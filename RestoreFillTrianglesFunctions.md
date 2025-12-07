**Token Count:** ~86,000 / 190,000 (~45% consumed)

---

## Cursor Instructions: Fill Triangle Buttons

**CRITICAL CONSTRAINTS:**
1. Make ONLY the changes specified below
2. Do NOT refactor, optimize, or modify any other code
3. If you encounter errors, STOP and report the error message—do not attempt fixes
4. **Do NOT automatically push to git. Wait for explicit instructions to do so.**

---

### Task 1: Fix Existing "Fill Triangle" Button

**File:** `ARViewWithOverlays.swift`

**Location:** Find the Fill Triangle button (search for `"Fill Triangle button"` comment). Current code:

```swift
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangle.id,
                                    "spacing": surveySpacing,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore
                                ]
                            )
```

**Change:** Add `triangleStore` to userInfo:

```swift
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangle.id,
                                    "spacing": surveySpacing,
                                    "triangleStore": arCalibrationCoordinator.triangleStore,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore
                                ]
                            )
```

---

### Task 2: Add "Fill All Triangles" Button

**File:** `ARViewWithOverlays.swift`

**Location:** Immediately AFTER the existing Fill Triangle button's closing brace and `.buttonStyle(.plain)`, add a new button. Find this pattern:

```swift
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .position(x: geo.size.width - 120, y: 270) // Below PiP map
```

**Change:** Insert the new button BEFORE the closing brace of the HStack/VStack that contains the Fill Triangle button. The structure should become:

```swift
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        // Fill All Triangles button
                        Button(action: {
                            let calibratedTriangles = arCalibrationCoordinator.triangleStore.triangles.filter { $0.isCalibrated }
                            
                            print("🎯 [FILL_ALL_BTN] Button tapped")
                            print("   Found \(calibratedTriangles.count) calibrated triangle(s)")
                            
                            guard !calibratedTriangles.isEmpty else {
                                print("⚠️ [FILL_ALL_BTN] No calibrated triangles to fill")
                                return
                            }
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            for triangle in calibratedTriangles {
                                print("🎯 [FILL_ALL_BTN] Filling triangle \(String(triangle.id.uuidString.prefix(8)))")
                                
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                    object: nil,
                                    userInfo: [
                                        "triangleID": triangle.id,
                                        "spacing": surveySpacing,
                                        "triangleStore": arCalibrationCoordinator.triangleStore,
                                        "arWorldMapStore": arCalibrationCoordinator.arStore
                                    ]
                                )
                            }
                            
                            print("✅ [FILL_ALL_BTN] Posted fill notifications for \(calibratedTriangles.count) triangle(s)")
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.system(size: 14))
                                Text("Fill All")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .position(x: geo.size.width - 120, y: 270) // Below PiP map
```

**Visual difference:**
- "Fill Triangle" = Red button, `grid.circle.fill` icon
- "Fill All" = Purple button, `square.grid.3x3.fill` icon

---

## Files Changed

| File | Change Type | Description |
|------|-------------|-------------|
| `ARViewWithOverlays.swift` | Modified | Fix Fill Triangle notification + Add Fill All button |

---

## Acceptance Criteria

### Fill Triangle (single)
1. Button taps without crash
2. Console shows `✅ [FILL_TRIANGLE] Found triangle XXXXXXXX`
3. Survey markers appear within that triangle

### Fill All Triangles
1. Button appears (purple, next to red Fill Triangle button)
2. Console shows:
   ```
   🎯 [FILL_ALL_BTN] Button tapped
      Found N calibrated triangle(s)
   🎯 [FILL_ALL_BTN] Filling triangle XXXXXXXX
   🎯 [FILL_ALL_BTN] Filling triangle YYYYYYYY
   ...
   ✅ [FILL_ALL_BTN] Posted fill notifications for N triangle(s)
   ```
3. Survey markers appear in ALL calibrated triangles
4. If no calibrated triangles exist, console shows warning and no crash

---

**Token consumption for this response:** ~1,200 tokens