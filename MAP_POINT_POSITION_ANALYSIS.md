# TapResolver: Map Point Position Calculations in AR Space - Deep Dive Analysis

This document provides comprehensive answers to questions about how TapResolver calculates Map Point positions in AR space, with actual code references.

---

## Question Set 1: Session Transform Computation

### 1. Where is the session transform computed? (file, function name)

**Answer:** The session transform is computed in two places:

1. **Primary function:** `computeSessionTransformForBakedData()` in `ARCalibrationCoordinator.swift` (lines 3553-3657)
2. **Helper function:** `computeSessionToCanonicalTransform()` in `ARCalibrationCoordinator.swift` (lines 3476-3529)

```3476:3529:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
    /// - Returns: Transform from session to canonical, or nil if computation fails
    private func computeSessionToCanonicalTransform(
        marker1MapPosition: CGPoint,
        marker1ARPosition: SIMD3<Float>,
        marker2MapPosition: CGPoint,
        marker2ARPosition: SIMD3<Float>,
        canonicalFrame: CanonicalFrame
    ) -> SessionToCanonicalTransform? {
        
        // Convert map positions to canonical 3D positions
        let canonical1 = canonicalFrame.mapToCanonical(marker1MapPosition)
        let canonical2 = canonicalFrame.mapToCanonical(marker2MapPosition)
        
        // Calculate edge vectors in both coordinate systems (XZ plane only)
        let canonicalEdge = SIMD2<Float>(canonical2.x - canonical1.x, canonical2.z - canonical1.z)
        let sessionEdge = SIMD2<Float>(marker2ARPosition.x - marker1ARPosition.x, marker2ARPosition.z - marker1ARPosition.z)
        
        let canonicalLength = simd_length(canonicalEdge)
        let sessionLength = simd_length(sessionEdge)
        
        guard canonicalLength > 0.001, sessionLength > 0.001 else {
            print("⚠️ [BAKE_TRANSFORM] Degenerate edge - markers too close")
            return nil
        }
        
        // Calculate scale: canonical meters per session meter
        // (canonical frame uses real-world scale derived from MetricSquare)
        let scale = canonicalLength / sessionLength
        
        // Calculate rotation: angle from session edge to canonical edge
        let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
        let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
        let rotation = canonicalAngle - sessionAngle
        
        // Calculate translation: where session origin lands in canonical space
        // First, rotate and scale the session position of marker 1
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let scaledSession1 = marker1ARPosition * scale
        let rotatedSession1 = SIMD3<Float>(
            scaledSession1.x * cosR - scaledSession1.z * sinR,
            scaledSession1.y,
            scaledSession1.x * sinR + scaledSession1.z * cosR
        )
        
        // Translation = canonical position - transformed session position
        let translation = canonical1 - rotatedSession1
        
        print("📐 [BAKE_TRANSFORM] Computed session→canonical transform:")
        print("   Scale: \(String(format: "%.4f", scale)) (canonical/session)")
        print("   Rotation: \(String(format: "%.1f", rotation * 180 / .pi))°")
        print("   Translation: (\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.y)), \(String(format: "%.2f", translation.z)))")
        
        return SessionToCanonicalTransform(rotationY: rotation, translation: translation, scale: scale)
    }
```

### 2. How many markers are required before a transform is computed?

**Answer:** **2 markers minimum** are required.

```3569:3573:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // Need at least 2 planted markers
        guard placedMarkers.count >= 2 else {
            print("⚠️ [SESSION_TRANSFORM] Need 2+ markers, have \(placedMarkers.count)")
            return false
        }
```

### 3. What type of transform is it? (rigid body? affine? per-triangle?)

**Answer:** It's a **rigid body transform** (similarity transform) with:
- **Rotation:** Y-axis only (2D rotation in XZ plane)
- **Scale:** Uniform scale factor
- **Translation:** 3D translation vector

The transform structure is defined as:

```137:159:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
    struct SessionToCanonicalTransform {
        let rotationY: Float           // Radians, Y-axis rotation
        let translation: SIMD3<Float>  // Translation vector
        let scale: Float               // Scale factor (AR meters / canonical meters)
        
        /// Transforms a position from session coordinates to canonical coordinates
        func apply(to sessionPosition: SIMD3<Float>) -> SIMD3<Float> {
            // Apply scale
            let scaled = sessionPosition * scale
            
            // Apply rotation around Y axis
            let cosR = cos(rotationY)
            let sinR = sin(rotationY)
            let rotated = SIMD3<Float>(
                scaled.x * cosR - scaled.z * sinR,
                scaled.y,
                scaled.x * sinR + scaled.z * cosR
            )
            
            // Apply translation
            return rotated + translation
        }
    }
```

**Note:** This is a **global session-level transform**, NOT per-triangle. All triangles in a session share the same transform.

### 4. What are the inputs to the transform computation?

**Answer:** The inputs are:

1. **Two MapPoint IDs** (from `placedMarkers[0]` and `placedMarkers[1]`)
2. **Map positions** (2D CGPoint from MapPointStore)
3. **AR positions** (3D SIMD3<Float> from `mapPointARPositions`)
4. **Map parameters:** `mapSize` (CGSize) and `metersPerPixel` (Float)

```3575:3601:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        let marker1ID = placedMarkers[0]
        let marker2ID = placedMarkers[1]
        
        guard let marker1MapPoint = safeMapStore.points.first(where: { $0.id == marker1ID }),
              let marker2MapPoint = safeMapStore.points.first(where: { $0.id == marker2ID }),
              let marker1AR = mapPointARPositions[marker1ID],
              let marker2AR = mapPointARPositions[marker2ID] else {
            print("⚠️ [SESSION_TRANSFORM] Could not find marker data")
            return false
        }
        
        // Create canonical frame
        let pixelsPerMeter = 1.0 / metersPerPixel
        let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        let floorHeight: Float = -1.1
        
        // Convert map positions to canonical
        let marker1Canonical = SIMD3<Float>(
            Float(marker1MapPoint.position.x - canonicalOrigin.x) / pixelsPerMeter,
            floorHeight,
            Float(marker1MapPoint.position.y - canonicalOrigin.y) / pixelsPerMeter
        )
        let marker2Canonical = SIMD3<Float>(
            Float(marker2MapPoint.position.x - canonicalOrigin.x) / pixelsPerMeter,
            floorHeight,
            Float(marker2MapPoint.position.y - canonicalOrigin.y) / pixelsPerMeter
        )
```

### 5. What are the outputs?

**Answer:** The output is a `SessionToCanonicalTransform` struct containing:
- `rotationY`: Float (radians, Y-axis rotation)
- `translation`: SIMD3<Float> (translation vector)
- `scale`: Float (scale factor)

This transform is cached in `cachedCanonicalToSessionTransform`:

```3636:3640:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // Create and cache the transform
        cachedCanonicalToSessionTransform = SessionToCanonicalTransform(
            rotationY: rotation,
            translation: translation,
            scale: scale
        )
```

### 6. Show me the actual matrix math or algorithm used.

**Answer:** The algorithm computes a 2-point rigid body transform:

```3603:3633:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // Compute canonical→session transform (INVERSE of session→canonical)
        // Edge vectors
        let canonicalEdge = SIMD2<Float>(marker2Canonical.x - marker1Canonical.x, marker2Canonical.z - marker1Canonical.z)
        let sessionEdge = SIMD2<Float>(marker2AR.x - marker1AR.x, marker2AR.z - marker1AR.z)
        
        let canonicalLength = simd_length(canonicalEdge)
        let sessionLength = simd_length(sessionEdge)
        
        guard canonicalLength > 0.001, sessionLength > 0.001 else {
            print("⚠️ [SESSION_TRANSFORM] Degenerate edge")
            return false
        }
        
        // Scale: session meters per canonical meter (inverse of bake-down scale)
        let scale = sessionLength / canonicalLength
        
        // Rotation: angle from canonical edge to session edge (inverse direction)
        let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
        let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
        let rotation = sessionAngle - canonicalAngle  // Note: reversed from bake-down
        
        // Translation: compute where canonical origin maps to in session space
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let scaledCanonical1 = marker1Canonical * scale
        let rotatedCanonical1 = SIMD3<Float>(
            scaledCanonical1.x * cosR - scaledCanonical1.z * sinR,
            scaledCanonical1.y,
            scaledCanonical1.x * sinR + scaledCanonical1.z * cosR
        )
        let translation = marker1AR - rotatedCanonical1
```

**Algorithm steps:**
1. Compute edge vectors in XZ plane (ignoring Y height)
2. Calculate scale: `sessionLength / canonicalLength`
3. Calculate rotation angle: `atan2(sessionEdge) - atan2(canonicalEdge)`
4. Apply rotation matrix (Y-axis only): `[cos(θ), -sin(θ), 0; sin(θ), cos(θ), 0; 0, 0, 1]`
5. Compute translation: `marker1AR - (scale * rotate(marker1Canonical))`

---

## Question Set 2: Ghost Position Prediction

### 1. When a ghost marker position is calculated, what data sources are used?

**Answer:** Ghost positions use a **priority-based fallback system** with three data sources:

**PRIORITY 0: Baked Canonical Position** (fastest, most stable)
- Uses `MapPoint.canonicalPosition` (from historical consensus)
- Projects to current session via `cachedCanonicalToSessionTransform`

```1442:1473:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ 🔍 [GHOST_CALC] PRIORITY CHECK: Baked Canonical Position              ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        
        // Check prerequisites for baked path
        let hasBakedPosition = mapPoint.canonicalPosition != nil
        let hasSessionTransform = cachedCanonicalToSessionTransform != nil
        
        print("║   MapPoint: \(String(mapPoint.id.uuidString.prefix(8)))")
        print("║   canonicalPosition: \(hasBakedPosition ? "✅ EXISTS" : "❌ NIL")")
        if let baked = mapPoint.canonicalPosition {
            print("║     → (\(String(format: "%.2f", baked.x)), \(String(format: "%.2f", baked.y)), \(String(format: "%.2f", baked.z)))")
            print("║     confidence: \(mapPoint.canonicalConfidence != nil ? String(format: "%.2f", mapPoint.canonicalConfidence!) : "NIL")")
            print("║     sampleCount: \(mapPoint.canonicalSampleCount)")
        }
        print("║   cachedCanonicalToSessionTransform: \(hasSessionTransform ? "✅ EXISTS" : "❌ NIL")")
        
        if hasBakedPosition && hasSessionTransform {
            print("║   → Attempting baked projection via calculateGhostPositionFromBakedData()")
            print("╚════════════════════════════════════════════════════════════════════════╝")
            
            if let bakedPosition = calculateGhostPositionFromBakedData(for: mapPoint.id) {
                let calcEndTime = Date()
                let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ✅ [GHOST_CALC] BAKED PATH SUCCEEDED                                   ║")
                print("╠════════════════════════════════════════════════════════════════════════╣")
                print("║ Result: (\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.y)), \(String(format: "%.2f", bakedPosition.z)))")
                print("║ Duration: \(String(format: "%.2f", calcDuration))ms")
                print("║ Source: Baked canonical → session projection")
                print("╚════════════════════════════════════════════════════════════════════════╝")
                return bakedPosition
```

**PRIORITY 1: Session-Level Rigid Transform** (legacy path)
- Uses historical positions from `MapPoint.arPositionHistory`
- Transforms each historical session's position individually to current session
- Computes weighted average of transformed positions

```1490:1607:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // ═══════════════════════════════════════════════════════════════════════════
        // PRIORITY 1: Session-level rigid transform (legacy path)
        // Instead of using naive consensus (which mixes coordinate frames),
        // we transform each historical session's position individually
        
        let targetHistory = mapPoint.arPositionHistory
        if !targetHistory.isEmpty {
            print("📍 [GHOST_CALC] Target has \(targetHistory.count) historical position(s) - attempting session-level transform")
            
            // Group target positions by session
            let targetSessionIDs = Set(targetHistory.map { $0.sessionID })
            
            // Also collect vertex historical positions indexed by sessionID
            var vertexHistoryBySession: [UUID: [(vertexIndex: Int, position: simd_float3)]] = [:]
            for (index, vertexMapPoint) in vertexMapPoints.enumerated() {
                for record in vertexMapPoint.arPositionHistory {
                    vertexHistoryBySession[record.sessionID, default: []].append((vertexIndex: index, position: record.position))
                }
            }
            
            // Get current session positions for vertices (these are our "anchor points")
            var currentVertexPositions: [Int: simd_float3] = [:]
            for (index, vertexMapPoint) in vertexMapPoints.enumerated() {
                if let currentPos = mapPointARPositions[vertexMapPoint.id] {
                    currentVertexPositions[index] = currentPos
                }
            }
            
            // For each session where target has a position, attempt to build a transform
            var alignedCandidates: [(position: simd_float3, confidence: Float)] = []
            
            for targetRecord in targetHistory {
                let sessionID = targetRecord.sessionID
                
                // Check if this session has positions for 2+ vertices that we also have in current session
                guard let vertexRecords = vertexHistoryBySession[sessionID] else {
                    print("   ⏭️ Session \(String(sessionID.uuidString.prefix(8))): no vertex positions")
                    continue
                }
                
                // Find vertices that have BOTH historical (this session) AND current positions
                var correspondences: [(historical: simd_float3, current: simd_float3)] = []
                for vertexRecord in vertexRecords {
                    if let currentPos = currentVertexPositions[vertexRecord.vertexIndex] {
                        correspondences.append((historical: vertexRecord.position, current: currentPos))
                    }
                }
                
                guard correspondences.count >= 2 else {
                    print("   ⏭️ Session \(String(sessionID.uuidString.prefix(8))): only \(correspondences.count) correspondence(s), need 2")
                    continue
                }
                
                // Compute rigid transform from historical session to current session
                guard let transform = calculate2PointRigidTransform(
                    oldPoints: (correspondences[0].historical, correspondences[1].historical),
                    newPoints: (correspondences[0].current, correspondences[1].current)
                ) else {
                    print("   ⚠️ Session \(String(sessionID.uuidString.prefix(8))): transform calculation failed")
                    continue
                }
                
                // Verify transform quality
                let cosR = cos(transform.rotationY)
                let sinR = sin(transform.rotationY)
                let rotatedHistorical1 = simd_float3(
                    correspondences[1].historical.x * cosR - correspondences[1].historical.z * sinR,
                    correspondences[1].historical.y,
                    correspondences[1].historical.x * sinR + correspondences[1].historical.z * cosR
                )
                let transformedHistorical1 = rotatedHistorical1 + transform.translation
                let verificationError = simd_distance(transformedHistorical1, correspondences[1].current)
                
                if verificationError > 0.5 {
                    print("   ⚠️ Session \(String(sessionID.uuidString.prefix(8))): verification error \(String(format: "%.2f", verificationError))m > 0.5m threshold, skipping")
                    continue
                }
                
                // Render session origin in AR (translation = historical origin in current coordinates)
                // TODO: Render session origin - needs ARSCNView reference
                // renderSessionOrigin(sessionID: sessionID, origin: transform.translation, in: sceneView)
                print("🎯 [SESSION_ORIGIN] Session \(String(sessionID.uuidString.prefix(6))) origin at (\(String(format: "%.2f", transform.translation.x)), \(String(format: "%.2f", transform.translation.y)), \(String(format: "%.2f", transform.translation.z)))")
                
                // Apply transform to target's position from this session
                let transformedPosition = applyRigidTransform(
                    position: targetRecord.position,
                    rotationY: transform.rotationY,
                    translation: transform.translation
                )
                
                print("   ✅ Session \(String(sessionID.uuidString.prefix(8))): transformed to (\(String(format: "%.2f", transformedPosition.x)), \(String(format: "%.2f", transformedPosition.y)), \(String(format: "%.2f", transformedPosition.z))) [error: \(String(format: "%.2f", verificationError))m]")
                
                alignedCandidates.append((position: transformedPosition, confidence: targetRecord.confidenceScore))
            }
            
            // If we have aligned candidates, compute weighted average
            if !alignedCandidates.isEmpty {
                var weightedSum = simd_float3(0, 0, 0)
                var totalWeight: Float = 0
                
                for candidate in alignedCandidates {
                    weightedSum += candidate.position * candidate.confidence
                    totalWeight += candidate.confidence
                }
                
                let alignedConsensus = weightedSum / totalWeight
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ✅ [GHOST_CALC] PER-SESSION ALIGNMENT SUCCEEDED                        ║")
                print("╠════════════════════════════════════════════════════════════════════════╣")
                print("║ Consensus from \(alignedCandidates.count) session(s): (\(String(format: "%.2f", alignedConsensus.x)), \(String(format: "%.2f", alignedConsensus.y)), \(String(format: "%.2f", alignedConsensus.z)))")
                print("║ Source: Session-level rigid transforms (PRIORITY 1 path)")
                print("╚════════════════════════════════════════════════════════════════════════╝")
                
                let calcEndTime = Date()
                let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
                print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms)")
                
                return alignedConsensus
            } else {
                print("📐 [GHOST_CALC] No sessions could be aligned - falling back to barycentric")
            }
        } else {
            print("📐 [GHOST_CALC] No history for target MapPoint \(String(mapPoint.id.uuidString.prefix(8))) - using barycentric")
        }
```

**PRIORITY 2: Barycentric Interpolation** (fallback)
- Uses current session's triangle vertex positions
- Computes barycentric weights in 2D map space
- Applies weights to 3D AR positions

```1615:1721:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // PRIORITY 2: Barycentric interpolation from current session data (existing code follows)
        
        // STEP 3: Get triangle's 3 vertex AR positions (3D positions)
        // Attempt to gather 3 vertex positions from available sources
        var vertexPositions: [simd_float3] = []
        
        // FIRST: Try to use arMarkerIDs if they exist AND are all available in current session
        var foundAllMarkers = false
        if calibratedTriangle.arMarkerIDs.count == 3 && calibratedTriangle.arMarkerIDs.allSatisfy({ !$0.isEmpty }) {
            var markerPositions: [simd_float3] = []
            var allMarkersFound = true
            
            for markerIDString in calibratedTriangle.arMarkerIDs {
                guard !markerIDString.isEmpty else {
                    print("⚠️ [GHOST_CALC] Empty marker ID string in triangle's arMarkerIDs")
                    allMarkersFound = false
                    break
                }
                
                var foundPosition: simd_float3?
                
                // PRIORITY 1: Check current session's marker positions (just placed markers)
                if let sessionPosition = sessionMarkerPositions[markerIDString] {
                    foundPosition = sessionPosition
                    print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) in session cache at position (\(String(format: "%.2f", sessionPosition.x)), \(String(format: "%.2f", sessionPosition.y)), \(String(format: "%.2f", sessionPosition.z)))")
                }
                // PRIORITY 2: Check by prefix in case arMarkerIDs has short 8-char versions
                else if let sessionPosition = sessionMarkerPositions.first(where: { $0.key.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.key) })?.value {
                    foundPosition = sessionPosition
                    print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) via prefix in session cache")
                }
                // PRIORITY 3: Fall back to ARWorldMapStore
                else if let marker = arWorldMapStore.markers.first(where: { $0.id.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.id) }) {
                    foundPosition = marker.positionInSession
                    print("✅ [GHOST_CALC] Found marker \(String(marker.id.prefix(8))) in store at position (\(String(format: "%.2f", marker.positionInSession.x)), \(String(format: "%.2f", marker.positionInSession.y)), \(String(format: "%.2f", marker.positionInSession.z)))")
                }
                
                if let position = foundPosition {
                    markerPositions.append(position)
                } else {
                    print("📐 [GHOST_CALC] Marker \(String(markerIDString.prefix(8))) not in current session cache - will try vertex positions")
                    allMarkersFound = false
                    break
                }
            }
            
            if allMarkersFound && markerPositions.count == 3 {
                vertexPositions = markerPositions
                foundAllMarkers = true
            }
        }
        
        // SECOND: If markers weren't available, try mapPointARPositions (keyed by MapPoint ID)
        if !foundAllMarkers {
            print("📐 [GHOST_CALC] Checking mapPointARPositions for triangle vertices")
            var vertexPosFromActivation: [simd_float3] = []
            var allVerticesFound = true
            
            for vertexID in calibratedTriangle.vertexIDs {
                if let position = mapPointARPositions[vertexID] {
                    print("✅ [GHOST_CALC] Found vertex \(String(vertexID.uuidString.prefix(8))) in mapPointARPositions at (\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z)))")
                    vertexPosFromActivation.append(position)
                } else {
                    print("⚠️ [GHOST_CALC] Vertex \(String(vertexID.uuidString.prefix(8))) not in mapPointARPositions")
                    allVerticesFound = false
                    break
                }
            }
            
            if allVerticesFound && vertexPosFromActivation.count == 3 {
                vertexPositions = vertexPosFromActivation
            }
        }
        
        // Final check: do we have 3 positions?
        guard vertexPositions.count == 3 else {
            print("⚠️ [GHOST_CALC] Could not find all 3 vertex positions from any source")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        // STEP 4: Apply barycentric weights to 3D AR positions
        let m1_3D = vertexPositions[0]
        let m2_3D = vertexPositions[1]
        let m3_3D = vertexPositions[2]
        
        let ghostPosition = simd_float3(
            Float(w1) * m1_3D.x + Float(w2) * m2_3D.x + Float(w3) * m3_3D.x,
            Float(w1) * m1_3D.y + Float(w2) * m2_3D.y + Float(w3) * m3_3D.y,
            Float(w1) * m1_3D.z + Float(w2) * m2_3D.z + Float(w3) * m3_3D.z
        )
        
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ ⚠️ [GHOST_CALC] BARYCENTRIC FALLBACK USED                              ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ Position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        print("║ Source: Current session barycentric interpolation (PRIORITY 2 path)")
        print("║ Note: No baked data or session history available for this vertex")
        print("╚════════════════════════════════════════════════════════════════════════╝")
        
        let calcEndTime = Date()
        let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
        print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms)")
        
        return ghostPosition
```

### 2. Is there ONE transform applied, or multiple transforms composed together?

**Answer:** It depends on the priority path:

- **PRIORITY 0 (Baked):** ONE transform (`cachedCanonicalToSessionTransform`)
- **PRIORITY 1 (Session-level):** MULTIPLE transforms — one per historical session, then weighted average
- **PRIORITY 2 (Barycentric):** NO transform — direct barycentric interpolation

### 3. Does the ghost calculation use any per-triangle data, or only global data?

**Answer:** **Mixed approach:**

- **Barycentric weights** are computed **per-triangle** (in 2D map space)
- **Transform application** uses **global session transform** (same for all triangles)
- **Triangle vertex positions** are triangle-specific

The barycentric weights are computed from the triangle's 2D map geometry:

```1417:1436:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // STEP 2: Calculate barycentric weights in 2D map space
        // Using the formula: P = w1*P1 + w2*P2 + w3*P3 where w1+w2+w3=1
        let v0 = CGPoint(x: p2_2D.x - p1_2D.x, y: p2_2D.y - p1_2D.y)
        let v1 = CGPoint(x: p3_2D.x - p1_2D.x, y: p3_2D.y - p1_2D.y)
        let v2 = CGPoint(x: p_target_2D.x - p1_2D.x, y: p_target_2D.y - p1_2D.y)
        
        let denom = v0.x * v1.y - v1.x * v0.y
        guard abs(denom) > 0.001 else {
            print("⚠️ [GHOST_CALC] Degenerate triangle - vertices are collinear")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        let w2 = (v2.x * v1.y - v1.x * v2.y) / denom
        let w3 = (v0.x * v2.y - v2.x * v0.y) / denom
        let w1 = 1.0 - w2 - w3
        
        print("📐 [GHOST_CALC] Barycentric weights: w1=\(String(format: "%.3f", w1)), w2=\(String(format: "%.3f", w2)), w3=\(String(format: "%.3f", w3))")
```

### 4. Trace the complete function call chain from "we need a ghost position" to "here are the XYZ coordinates"

**Answer:** Function call chain:

1. **Entry point:** `calculateGhostPosition()` (line 1363)
   - Called from `plantGhostsForAdjacentTriangles()` or `activateAdjacentTriangle()`

2. **Priority check:** Checks for baked data first
   - Calls `calculateGhostPositionFromBakedData()` (line 1729)
   - Which calls `calculateGhostPositionFromBakedDataInternal()` (line 1766)
   - Applies `cachedCanonicalToSessionTransform.apply()` (line 1800)

3. **Fallback to session-level transform:** If baked fails
   - Loops through `mapPoint.arPositionHistory`
   - Calls `calculate2PointRigidTransform()` for each session
   - Calls `applyRigidTransform()` to transform positions
   - Computes weighted average

4. **Final fallback to barycentric:** If session-level fails
   - Uses pre-computed barycentric weights (w1, w2, w3)
   - Applies weights to vertex AR positions
   - Returns `simd_float3(w1*m1 + w2*m2 + w3*m3)`

### 5. Are barycentric coordinates used anywhere in ghost prediction?

**Answer:** **YES** — barycentric coordinates are used in PRIORITY 2 (fallback path):

```1698:1707:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // STEP 4: Apply barycentric weights to 3D AR positions
        let m1_3D = vertexPositions[0]
        let m2_3D = vertexPositions[1]
        let m3_3D = vertexPositions[2]
        
        let ghostPosition = simd_float3(
            Float(w1) * m1_3D.x + Float(w2) * m2_3D.x + Float(w3) * m3_3D.x,
            Float(w1) * m1_3D.y + Float(w2) * m2_3D.y + Float(w3) * m3_3D.y,
            Float(w1) * m1_3D.z + Float(w2) * m2_3D.z + Float(w3) * m3_3D.z
        )
```

The barycentric weights (w1, w2, w3) are computed in 2D map space and then applied to 3D AR positions.

### 6. Is there any interpolation between multiple historical positions?

**Answer:** **YES** — in PRIORITY 1 path, multiple historical positions are:
1. **Transformed** individually to current session coordinates
2. **Weighted averaged** by confidence scores

```1585:1607:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
            // If we have aligned candidates, compute weighted average
            if !alignedCandidates.isEmpty {
                var weightedSum = simd_float3(0, 0, 0)
                var totalWeight: Float = 0
                
                for candidate in alignedCandidates {
                    weightedSum += candidate.position * candidate.confidence
                    totalWeight += candidate.confidence
                }
                
                let alignedConsensus = weightedSum / totalWeight
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ✅ [GHOST_CALC] PER-SESSION ALIGNMENT SUCCEEDED                        ║")
                print("╠════════════════════════════════════════════════════════════════════════╣")
                print("║ Consensus from \(alignedCandidates.count) session(s): (\(String(format: "%.2f", alignedConsensus.x)), \(String(format: "%.2f", alignedConsensus.y)), \(String(format: "%.2f", alignedConsensus.z)))")
                print("║ Source: Session-level rigid transforms (PRIORITY 1 path)")
                print("╚════════════════════════════════════════════════════════════════════════╝")
                
                let calcEndTime = Date()
                let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
                print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms)")
                
                return alignedConsensus
            } else {
                print("📐 [GHOST_CALC] No sessions could be aligned - falling back to barycentric")
            }
```

---

## Question Set 3: Position History and Baking

### 1. What data structure stores AR position history for a MapPoint?

**Answer:** `MapPoint.arPositionHistory` — an array of `ARPositionRecord`:

```24:50:TapResolver/TapResolver/State/MapPointStore.swift
/// Records a single AR position measurement for a MapPoint
public struct ARPositionRecord: Codable, Identifiable {
    public let id: UUID
    let position: SIMD3<Float>      // 3D AR position (simd_float3)
    let sessionID: UUID              // Which AR session created this
    let timestamp: Date              // When recorded
    let sourceType: SourceType       // How it was recorded
    let distortionVector: SIMD3<Float>?  // Difference from estimated (nil if no adjustment)
    let confidenceScore: Float       // 0.0 - 1.0, used for weighted averaging
    
    public init(
        id: UUID = UUID(),
        position: SIMD3<Float>,
        sessionID: UUID,
        timestamp: Date = Date(),
        sourceType: SourceType,
        distortionVector: SIMD3<Float>? = nil,
        confidenceScore: Float
    ) {
        self.id = id
        self.position = position
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.sourceType = sourceType
        self.distortionVector = distortionVector
        self.confidenceScore = confidenceScore
    }
```

### 2. When a marker is placed or adjusted, what gets recorded?

**Answer:** When a marker is placed, an `ARPositionRecord` is created and added to history:

```812:821:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
            // MARK: - Record position in history (Milestone 2)
            let confidence: Float = sourceType == .ghostConfirm ? 1.0 : (sourceType == .ghostAdjust ? 0.8 : 0.95)
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: safeARStore.currentSessionID,
                sourceType: sourceType,
                distortionVector: distortionVector,
                confidenceScore: confidence
            )
            safeMapStore.addPositionRecord(mapPointID: mapPointID, record: record)
```

The record includes:
- **position:** The actual AR position where marker was placed
- **sessionID:** Current AR session ID
- **sourceType:** `.calibration`, `.ghostConfirm`, or `.ghostAdjust`
- **distortionVector:** Delta from ghost position (if adjusted)
- **confidenceScore:** Based on source type (0.8-1.0)

### 3. In bakeDownHistoricalData(), how are historical positions combined?

**Answer:** Historical positions are combined via **weighted averaging**:

**Step 1:** Group positions by session and compute per-session transforms

```1850:1972:TapResolver/TapResolver/State/MapPointStore.swift
        // Step 3: For each session, compute transform and bake positions
        var bakedPositionsAccumulator: [UUID: [(position: SIMD3<Float>, weight: Float)]] = [:]
        var sessionsProcessed = 0
        var sessionsSkipped = 0
        
        for sessionID in sessionIDs {
            guard let positionsInSession = sessionPositions[sessionID] else { continue }
            
            let sessionPrefix = String(sessionID.uuidString.prefix(8))
            print("\n🔄 [SESSION] Processing \(sessionPrefix) (\(positionsInSession.count) MapPoint(s))")
            
            // Need at least 2 MapPoints to compute transform
            guard positionsInSession.count >= 2 else {
                print("   ⏭️ Skipping — need 2+ MapPoints for transform, have \(positionsInSession.count)")
                sessionsSkipped += 1
                continue
            }
            
            // Pick 2 reference MapPoints (use first two that have good confidence)
            let sortedByConfidence = positionsInSession.sorted { $0.value.confidence > $1.value.confidence }
            let ref1ID = sortedByConfidence[0].key
            let ref2ID = sortedByConfidence[1].key
            
            guard let ref1MapPoint = points.first(where: { $0.id == ref1ID }),
                  let ref2MapPoint = points.first(where: { $0.id == ref2ID }) else {
                print("   ⚠️ Could not find reference MapPoints in store")
                sessionsSkipped += 1
                continue
            }
            
            let ref1AR = sortedByConfidence[0].value.position
            let ref2AR = sortedByConfidence[1].value.position
            let ref1Map = ref1MapPoint.position
            let ref2Map = ref2MapPoint.position
            
            print("   📍 Reference 1: \(String(ref1ID.uuidString.prefix(8))) map=(\(Int(ref1Map.x)), \(Int(ref1Map.y))) AR=(\(String(format: "%.2f", ref1AR.x)), \(String(format: "%.2f", ref1AR.y)), \(String(format: "%.2f", ref1AR.z)))")
            print("   📍 Reference 2: \(String(ref2ID.uuidString.prefix(8))) map=(\(Int(ref2Map.x)), \(Int(ref2Map.y))) AR=(\(String(format: "%.2f", ref2AR.x)), \(String(format: "%.2f", ref2AR.y)), \(String(format: "%.2f", ref2AR.z)))")
            
            // Convert map positions to canonical 3D
            let ref1Canonical = SIMD3<Float>(
                Float(ref1Map.x - canonicalOrigin.x) / pixelsPerMeter,
                floorHeight,
                Float(ref1Map.y - canonicalOrigin.y) / pixelsPerMeter
            )
            let ref2Canonical = SIMD3<Float>(
                Float(ref2Map.x - canonicalOrigin.x) / pixelsPerMeter,
                floorHeight,
                Float(ref2Map.y - canonicalOrigin.y) / pixelsPerMeter
            )
            
            // Compute session→canonical transform
            // Edge vectors in XZ plane
            let canonicalEdge = SIMD2<Float>(ref2Canonical.x - ref1Canonical.x, ref2Canonical.z - ref1Canonical.z)
            let sessionEdge = SIMD2<Float>(ref2AR.x - ref1AR.x, ref2AR.z - ref1AR.z)
            
            let canonicalLength = simd_length(canonicalEdge)
            let sessionLength = simd_length(sessionEdge)
            
            guard canonicalLength > 0.001, sessionLength > 0.001 else {
                print("   ⚠️ Degenerate edge — reference points too close")
                sessionsSkipped += 1
                continue
            }
            
            // Scale: canonical meters per session meter
            let scale = canonicalLength / sessionLength
            
            // Rotation: angle from session edge to canonical edge
            let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
            let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
            let rotation = canonicalAngle - sessionAngle
            
            // Translation: compute where session origin maps to in canonical space
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let scaledRef1AR = ref1AR * scale
            let rotatedRef1AR = SIMD3<Float>(
                scaledRef1AR.x * cosR - scaledRef1AR.z * sinR,
                scaledRef1AR.y,
                scaledRef1AR.x * sinR + scaledRef1AR.z * cosR
            )
            let translation = ref1Canonical - rotatedRef1AR
            
            // Verify transform quality using second reference point
            let scaledRef2AR = ref2AR * scale
            let rotatedRef2AR = SIMD3<Float>(
                scaledRef2AR.x * cosR - scaledRef2AR.z * sinR,
                scaledRef2AR.y,
                scaledRef2AR.x * sinR + scaledRef2AR.z * cosR
            )
            let transformedRef2 = rotatedRef2AR + translation
            let verificationError = simd_distance(transformedRef2, ref2Canonical)
            
            print("   📐 Transform: scale=\(String(format: "%.4f", scale)) rot=\(String(format: "%.1f", rotation * 180 / .pi))° trans=(\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.z)))")
            print("   ✅ Verification error: \(String(format: "%.3f", verificationError))m")
            
            if verificationError > 0.5 {
                print("   ⚠️ High verification error — session may have scale drift, including with reduced weight")
            }
            
            // Apply transform to all positions from this session
            for (mapPointID, (arPosition, confidence)) in positionsInSession {
                // Apply transform: scale, rotate, translate
                let scaled = arPosition * scale
                let rotated = SIMD3<Float>(
                    scaled.x * cosR - scaled.z * sinR,
                    scaled.y,
                    scaled.x * sinR + scaled.z * cosR
                )
                let canonical = rotated + translation
                
                // Weight by confidence, reduced if verification error was high
                let adjustedWeight = verificationError > 0.5 ? confidence * 0.5 : confidence
                
                if bakedPositionsAccumulator[mapPointID] == nil {
                    bakedPositionsAccumulator[mapPointID] = []
                }
                bakedPositionsAccumulator[mapPointID]?.append((position: canonical, weight: adjustedWeight))
            }
            
            sessionsProcessed += 1
            print("   ✅ Transformed \(positionsInSession.count) position(s) to canonical frame")
        }
```

**Step 2:** Compute weighted average for each MapPoint

```1980:2012:TapResolver/TapResolver/State/MapPointStore.swift
        // Step 4: Compute weighted average for each MapPoint and update baked positions
        var updatedCount = 0
        
        print("\n📦 [HISTORICAL_BAKE] Computing baked positions...")
        
        for (mapPointID, samples) in bakedPositionsAccumulator {
            guard let index = points.firstIndex(where: { $0.id == mapPointID }) else {
                continue
            }
            
            // Weighted average
            var weightedSum = SIMD3<Float>(0, 0, 0)
            var totalWeight: Float = 0
            
            for sample in samples {
                weightedSum += sample.position * sample.weight
                totalWeight += sample.weight
            }
            
            guard totalWeight > 0 else { continue }
            
            let bakedPosition = weightedSum / totalWeight
            let avgConfidence = totalWeight / Float(samples.count)
            
            // Update MapPoint
                points[index].canonicalPosition = bakedPosition
                points[index].canonicalConfidence = avgConfidence
                points[index].canonicalSampleCount = samples.count
            
            print("   ✅ \(String(mapPointID.uuidString.prefix(8))): (\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.y)), \(String(format: "%.2f", bakedPosition.z))) [samples: \(samples.count), conf: \(String(format: "%.2f", avgConfidence))]")
            
            updatedCount += 1
        }
```

### 4. Is there any per-triangle transform stored or computed during baking?

**Answer:** **NO** — baking uses a **global session-level transform**. All triangles in a session share the same transform. There is no per-triangle transform stored or computed during baking.

### 5. Are distortion vectors stored? If so, where and how are they used?

**Answer:** **YES** — distortion vectors are stored in `ARPositionRecord.distortionVector`:

```31:31:TapResolver/TapResolver/State/MapPointStore.swift
    let distortionVector: SIMD3<Float>?  // Difference from estimated (nil if no adjustment)
```

**However, distortion vectors are NOT currently used** in ghost prediction or baking. They are stored but not applied. The comment in the code suggests they were intended for future distortion correction:

```203:203:TapResolver/TapResolver/State/MapPointStore.swift
        // (after scale/rotation) indicates map distortion to be corrected.
```

### 6. Show me the actual averaging/consensus algorithm.

**Answer:** The averaging algorithm is a **weighted average**:

```1990:2001:TapResolver/TapResolver/State/MapPointStore.swift
            // Weighted average
            var weightedSum = SIMD3<Float>(0, 0, 0)
            var totalWeight: Float = 0
            
            for sample in samples {
                weightedSum += sample.position * sample.weight
                totalWeight += sample.weight
            }
            
            guard totalWeight > 0 else { continue }
            
            let bakedPosition = weightedSum / totalWeight
```

**Formula:** `bakedPosition = Σ(position_i * weight_i) / Σ(weight_i)`

Where:
- `position_i` = canonical position from session i (after transform)
- `weight_i` = confidence score (reduced by 50% if verification error > 0.5m)

---

## Question Set 4: Per-Triangle Data

### 1. Does TrianglePatch store any transform or correction data beyond vertex IDs?

**Answer:** **YES** — `TrianglePatch` stores:

```26:42:TapResolver/TapResolver/State/TrianglePatch.swift
struct TrianglePatch: Codable, Identifiable {
    let id: UUID
    let vertexIDs: [UUID]  // Exactly 3 MapPoint IDs (must have triangle-edge role)
    var isCalibrated: Bool
    var calibrationQuality: Float  // 0.0 (red) to 1.0 (green)
    var transform: Similarity2D?  // Map → AR floor plane transform (nil until calibrated)
    let createdAt: Date
    var lastCalibratedAt: Date?
    var arMarkerIDs: [String] = []  // AR marker IDs for the 3 vertices (matches order of vertexIDs)
    var userPositionWhenCalibrated: simd_float3?  // User's AR position when final marker placed
    var legMeasurements: [TriangleLegMeasurement] = []  // Leg distance measurements for quality computation
    var worldMapFilename: String?  // Legacy: Filename of saved ARWorldMap patch (deprecated - use worldMapFilesByStrategy)
    var worldMapFilesByStrategy: [String: String] = [:]  // [strategyName: filename] - Multiple world maps per strategy
    /// Tracks which vertex was used as the starting anchor in the last calibration session.
    /// Used to rotate starting vertex each session so all vertices cycle through being ghosts.
    /// nil means never calibrated with rotation tracking.
    var lastStartingVertexIndex: Int?
```

**Key fields:**
- `transform: Similarity2D?` — **NOT CURRENTLY USED** (placeholder for future)
- `legMeasurements: [TriangleLegMeasurement]` — stores distortion ratios per leg

### 2. Is there any per-triangle affine transform computed or stored anywhere?

**Answer:** **NO** — the `transform: Similarity2D?` field exists but is **never computed or used**. It's a placeholder:

```214:227:TapResolver/TapResolver/State/TrianglePatch.swift
// MARK: - Similarity2D Transform (placeholder for future implementation)
struct Similarity2D: Codable {
    var rotation: simd_float2x2  // Rotation matrix
    var scale: Float  // Uniform scale
    var translation: simd_float2  // Translation vector
    
    init(rotation: simd_float2x2 = matrix_identity_float2x2, 
         scale: Float = 1.0, 
         translation: simd_float2 = simd_float2(0, 0)) {
        self.rotation = rotation
        self.scale = scale
        self.translation = translation
    }
}
```

### 3. When transitioning between triangles in a crawl, is any triangle-specific correction applied?

**Answer:** **NO** — when transitioning between triangles, only the **global session transform** is used. No triangle-specific correction is applied.

### 4. Search for "distortion", "warp", "lattice", "mesh transform", "affine" - what do you find?

**Answer:** Found:

1. **`distortionVector`** — stored in `ARPositionRecord` but **not used**
2. **`TriangleLegMeasurement.distortionRatio`** — computed but only used for quality scoring:

```15:24:TapResolver/TapResolver/State/TrianglePatch.swift
struct TriangleLegMeasurement: Codable {
    let vertexA: UUID
    let vertexB: UUID
    let mapDistance: Float     // meters, 2D map distance
    let arDistance: Float      // meters, 3D AR distance
    
    var distortionRatio: Float {
        mapDistance == 0 ? 0 : arDistance / mapDistance
    }
}
```

3. **`Similarity2D`** — placeholder struct, never used
4. **No "warp", "lattice", or "mesh transform"** found

### 5. Search for "barycentric" - is it used for anything beyond point-in-triangle testing?

**Answer:** **YES** — barycentric coordinates are used for:

1. **Ghost position interpolation** (PRIORITY 2 fallback)
2. **Point-in-triangle testing** (multiple locations)
3. **AR-to-map projection** (in `ARViewWithOverlays.swift`)

Barycentric interpolation is the primary method for computing ghost positions when baked data is unavailable.

---

## Question Set 5: Adjustment/Correction Flow

### 1. When the user places a marker to adjust a ghost (wasAdjusted: true), what data is recorded?

**Answer:** When `wasAdjusted: true`, the following is recorded:

```3259:3281:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
        // Record position to MapPoint's arPositionHistory for future ghost prediction improvement
        // Confirmed positions get higher confidence than adjusted ones
        let confidence: Float = wasAdjusted ? 0.90 : 0.95
        let sourceType: SourceType = .calibration
        
        let positionRecord = ARPositionRecord(
            position: ghostPosition,
            sessionID: safeARStore.currentSessionID,
            sourceType: sourceType,
            confidenceScore: confidence
        )
        safeMapStore.addPositionRecord(mapPointID: ghostMapPointID, record: positionRecord)
        
        // MILESTONE 5: Update baked position incrementally
        updateBakedPositionIncrementally(
            mapPointID: ghostMapPointID,
            sessionPosition: ghostPosition,
            confidence: confidence
        )
        
        let adjustmentNote = wasAdjusted ? "(adjusted)" : "(confirmed)")
        print("📍 [POSITION_HISTORY] crawl \(adjustmentNote) → MapPoint \(String(ghostMapPointID.uuidString.prefix(8)))")
        print("   ↳ pos: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z))) confidence: \(confidence)")
```

**Key differences:**
- **Confidence:** 0.90 (adjusted) vs 0.95 (confirmed)
- **Position:** The actual AR position where marker was placed (may differ from ghost)
- **No distortionVector:** Not stored in crawl mode (only in normal `registerMarker`)

### 2. Is the delta/offset between ghost position and adjusted position stored anywhere?

**Answer:** **PARTIALLY** — In normal `registerMarker()`, `distortionVector` is stored:

```812:821:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
            // MARK: - Record position in history (Milestone 2)
            let confidence: Float = sourceType == .ghostConfirm ? 1.0 : (sourceType == .ghostAdjust ? 0.8 : 0.95)
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: safeARStore.currentSessionID,
                sourceType: sourceType,
                distortionVector: distortionVector,
                confidenceScore: confidence
            )
            safeMapStore.addPositionRecord(mapPointID: mapPointID, record: record)
```

**However, in crawl mode (`activateAdjacentTriangle`), distortionVector is NOT stored** — only the position and confidence are recorded.

### 3. Does adjusting a marker affect only that MapPoint, or does it influence neighboring points?

**Answer:** **Only that MapPoint** — adjustments are recorded per-MapPoint and do not propagate to neighbors. Each MapPoint's history is independent.

### 4. Is there any "correction propagation" to adjacent triangles?

**Answer:** **NO** — there is no correction propagation. Adjacent triangles are activated but do not inherit corrections from the previous triangle.

### 5. How does an adjustment affect future ghost predictions for that same point?

**Answer:** Adjustments affect future predictions through:

1. **Position history:** The adjusted position is added to `arPositionHistory`
2. **Baked position:** Incrementally updated via `updateBakedPositionIncrementally()`
3. **Weighted averaging:** Future bakes will include this position with confidence 0.90

However, **distortion vectors are not used** in prediction, so the delta from ghost to actual is lost.

---

## Question Set 6: The Big Picture

### Complete Data Flow: "User places first marker" → "Ghost appears for third vertex"

**STEP 1: User places first marker**
- **Action:** User taps to place marker at MapPoint A
- **Data changed:** `mapPointARPositions[A] = markerPosition`
- **Stored where:** `ARCalibrationCoordinator.mapPointARPositions` (in-memory cache)
- **Also stored:** `ARPositionRecord` added to `MapPoint.arPositionHistory`

**STEP 2: User places second marker**
- **Action:** User taps to place marker at MapPoint B
- **Data changed:** `mapPointARPositions[B] = markerPosition`
- **Stored where:** Same as Step 1
- **Trigger:** `computeSessionTransformForBakedData()` is called
- **Transform computed:** `cachedCanonicalToSessionTransform` (global session transform)

**STEP 3: Ghost calculation for third vertex**
- **Action:** System needs ghost position for MapPoint C
- **Function called:** `calculateGhostPosition(mapPoint: C, calibratedTriangleID: ...)`
- **Priority check:**
  1. **PRIORITY 0:** Check for `C.canonicalPosition` + `cachedCanonicalToSessionTransform`
  2. **PRIORITY 1:** Check `C.arPositionHistory` + compute per-session transforms
  3. **PRIORITY 2:** Compute barycentric weights from triangle's 2D map geometry, apply to vertex AR positions

**STEP 4: Barycentric calculation (if PRIORITY 2)**
- **Barycentric weights:** Computed in 2D map space (w1, w2, w3)
- **Vertex positions:** Retrieved from `mapPointARPositions[A]`, `mapPointARPositions[B]`, or `sessionMarkerPositions`
- **Ghost position:** `w1*A_AR + w2*B_AR + w3*C_AR` (but C_AR doesn't exist yet, so this uses A and B only for 2-marker case)

**STEP 5: Ghost marker rendered**
- **Action:** Ghost marker appears at calculated position
- **Stored where:** `ARViewContainer.ghostMarkers[C] = ghostNode`

### All Transforms Applied and Order

1. **Global Session Transform** (computed once after 2 markers)
   - Type: Rigid body (rotation Y-axis, scale, translation)
   - Applied: Canonical → Session (for baked positions)
   - Stored: `cachedCanonicalToSessionTransform`

2. **Per-Session Historical Transforms** (computed on-demand for PRIORITY 1)
   - Type: Rigid body (2-point alignment)
   - Applied: Historical session → Current session
   - Stored: Temporary (not cached)

3. **Barycentric Interpolation** (PRIORITY 2 fallback)
   - Type: Linear interpolation (not a transform)
   - Applied: 2D map weights → 3D AR positions
   - Stored: Not stored (computed on-demand)

### What is Global vs. Local/Per-Triangle

**GLOBAL:**
- `cachedCanonicalToSessionTransform` — shared by all triangles in session
- Session-level transforms — same for all triangles
- Baked canonical positions — global coordinate frame

**LOCAL/PER-TRIANGLE:**
- Barycentric weights — computed per-triangle from 2D map geometry
- Triangle vertex positions — triangle-specific
- `TrianglePatch.legMeasurements` — per-triangle distortion ratios (not used in prediction)

### Where Corrections/Adjustments Enter the System

1. **User adjusts ghost:** `wasAdjusted: true` passed to `activateAdjacentTriangle()`
2. **Position recorded:** `ARPositionRecord` created with confidence 0.90
3. **Baked position updated:** `updateBakedPositionIncrementally()` called
4. **Future predictions:** Adjusted position included in weighted average

**However:** Distortion vectors are stored but **NOT APPLIED** in future predictions.

### How Historical Data Influences Future Predictions

1. **Baked positions:** Historical consensus positions (`canonicalPosition`) are projected to current session via global transform
2. **Session-level alignment:** Historical positions are transformed individually and weighted-averaged
3. **Confidence weighting:** Higher confidence positions (confirmed vs adjusted) have more influence
4. **Incremental updates:** Each new placement updates baked position incrementally

**Gap identified:** Per-triangle distortion corrections are **NOT IMPLEMENTED**. The system uses global transforms only, which cannot account for local map distortion.

---

## Summary: What's Actually Implemented vs. What's Missing

### ✅ IMPLEMENTED:
1. **Global session transform** (rigid body, 2-point)
2. **Baked canonical positions** (weighted average across sessions)
3. **Barycentric interpolation** (fallback for ghost positions)
4. **Per-session historical alignment** (PRIORITY 1 path)
5. **Position history storage** (with confidence scores)
6. **Distortion vector storage** (but not used)

### ❌ NOT IMPLEMENTED:
1. **Per-triangle transforms** (`Similarity2D` exists but never computed)
2. **Distortion vector application** (stored but ignored)
3. **Correction propagation** (adjustments don't affect neighbors)
4. **Per-triangle affine/warp corrections** (no mesh warping)
5. **Triangle-specific distortion correction** (only global transforms)

### 🔍 THE GAP:
The system assumes **uniform scale/rotation** across the entire map. Real maps have **local distortion** that varies per triangle. The `TrianglePatch.legMeasurements` compute distortion ratios, but these are only used for **quality scoring**, not for **position correction**.

**Insertion point for per-triangle distortion:** Between barycentric weight calculation and position interpolation, apply triangle-specific distortion correction based on `legMeasurements`.

