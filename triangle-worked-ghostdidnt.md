🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 7E771FF4...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: 909C9050...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 7E771FF4...
   [LOAD-3] Accessing ctx.locationID (PersistenceContext.shared.locationID)
   [LOAD-4] Current ctx.locationID = 'museum'
   [LOAD-5] pointsKey constant = 'MapPoints_v1'
   [LOAD-6] Calling ctx.read('MapPoints_v1', as: [MapPointDTO].self)
   [LOAD-7] This will generate key: 'locations.museum.MapPoints_v1'
   [LOAD-8] Expected UserDefaults key: 'locations.museum.MapPoints_v1'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'museum'
   [3] Generated full key via key('MapPoints_v1'): 'locations.museum.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.museum.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 15198 bytes (14.84 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"sessions":[],"roles":[],"x":3695.000015258789,"isLocked":true,"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"createdDate":782228945,"sessions":[],"roles":[],"x":2150.3345762176123,"isLocked":true,"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"createdDate":782145975,"sessions":[],"roles":[],"x":4627.521824291598,"isLocked":true,"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"createdDate":782228857,"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 68 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

   [LOAD-9] ✅ ctx.read() returned 68 MapPointDTO items
   [LOAD-10] First 3 point IDs from loaded data:
       DTO[1]: ID=E325D867... Pos=(3695, 4197)
       DTO[2]: ID=F5DE687B... Pos=(2150, 4358)
       DTO[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-11] Starting conversion from MapPointDTO to MapPoint
   [LOAD-12] Processing 68 DTO items
   [LOAD-13] Converting DTO[1]: ID=E325D867...
   [LOAD-13] Converting DTO[2]: ID=F5DE687B...
   [LOAD-13] Converting DTO[3]: ID=D8BF400C...
   [LOAD-14] ✅ Conversion complete: 68 MapPoint objects created
   [LOAD-15] Final points array contains 68 items
   [LOAD-16] First 3 MapPoint IDs in memory:
       MapPoint[1]: ID=E325D867... Pos=(3695, 4197)
       MapPoint[2]: ID=F5DE687B... Pos=(2150, 4358)
       MapPoint[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-17] Total sessions: 0
   [LOAD-18] Migration needed - calling save()
📦 Migrated 68 MapPoint(s) to include role metadata

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 7E771FF4...
   [SAVE-3] Current ctx.locationID = 'museum'
   [SAVE-4] points array contains 68 items
   [SAVE-5] ⚠️ BLOCKED: isReloading = true
   [SAVE-6] MapPointStore.save() blocked during reload operation
================================================================================

================================================================================

🔍 DEBUG: loadARMarkers() called for location 'museum'
📍 Legacy AR Markers in storage: 60 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'museum'
✅ MapPointStore: Reload complete - 68 points loaded
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 909C9050...
   [LOAD-3] Accessing ctx.locationID (PersistenceContext.shared.locationID)
   [LOAD-4] Current ctx.locationID = 'museum'
   [LOAD-5] pointsKey constant = 'MapPoints_v1'
   [LOAD-6] Calling ctx.read('MapPoints_v1', as: [MapPointDTO].self)
   [LOAD-7] This will generate key: 'locations.museum.MapPoints_v1'
   [LOAD-8] Expected UserDefaults key: 'locations.museum.MapPoints_v1'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'museum'
   [3] Generated full key via key('MapPoints_v1'): 'locations.museum.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.museum.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 15198 bytes (14.84 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"sessions":[],"roles":[],"x":3695.000015258789,"isLocked":true,"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"createdDate":782228945,"sessions":[],"roles":[],"x":2150.3345762176123,"isLocked":true,"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"createdDate":782145975,"sessions":[],"roles":[],"x":4627.521824291598,"isLocked":true,"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"createdDate":782228857,"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 68 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

   [LOAD-9] ✅ ctx.read() returned 68 MapPointDTO items
   [LOAD-10] First 3 point IDs from loaded data:
       DTO[1]: ID=E325D867... Pos=(3695, 4197)
       DTO[2]: ID=F5DE687B... Pos=(2150, 4358)
       DTO[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-11] Starting conversion from MapPointDTO to MapPoint
   [LOAD-12] Processing 68 DTO items
   [LOAD-13] Converting DTO[1]: ID=E325D867...
   [LOAD-13] Converting DTO[2]: ID=F5DE687B...
   [LOAD-13] Converting DTO[3]: ID=D8BF400C...
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
   [LOAD-14] ✅ Conversion complete: 68 MapPoint objects created
   [LOAD-15] Final points array contains 68 items
   [LOAD-16] First 3 MapPoint IDs in memory:
       MapPoint[1]: ID=E325D867... Pos=(3695, 4197)
       MapPoint[2]: ID=F5DE687B... Pos=(2150, 4358)
       MapPoint[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-17] Total sessions: 0
   [LOAD-18] Migration needed - calling save()
📦 Migrated 68 MapPoint(s) to include role metadata

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 909C9050...
   [SAVE-3] Current ctx.locationID = 'museum'
   [SAVE-4] points array contains 68 items
   [SAVE-5] ⚠️ BLOCKED: isReloading = true
   [SAVE-6] MapPointStore.save() blocked during reload operation
================================================================================

================================================================================

Publishing changes from within view updates is not allowed, this will cause undefined behavior.
🔍 DEBUG: loadARMarkers() called for location 'museum'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Legacy AR Markers in storage: 60 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Loaded 0 Anchor Package(s) for location 'museum'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
✅ MapPointStore: Reload complete - 68 points loaded
📍 ARWorldMapStore: Location changed → museum

🔄 Checking for location metadata migration...
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/29A01642-4AC2-4D08-A55F-F37F8891170B/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/29A01642-4AC2-4D08-A55F-F37F8891170B/Documents/locations/museum/dots.json
   ✓ dots.json exists
   ✓ Read 1485 bytes from dots.json
✅ Location 'museum' already has all metadata fields
⚠️ No location.json found for 'default', skipping migration
✅ All locations up-to-date

🔄 MapPointStore: Initial load for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 7E771FF4...
   [LOAD-3] Accessing ctx.locationID (PersistenceContext.shared.locationID)
   [LOAD-4] Current ctx.locationID = 'museum'
   [LOAD-5] pointsKey constant = 'MapPoints_v1'
   [LOAD-6] Calling ctx.read('MapPoints_v1', as: [MapPointDTO].self)
   [LOAD-7] This will generate key: 'locations.museum.MapPoints_v1'
   [LOAD-8] Expected UserDefaults key: 'locations.museum.MapPoints_v1'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'museum'
   [3] Generated full key via key('MapPoints_v1'): 'locations.museum.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.museum.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 15198 bytes (14.84 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"sessions":[],"roles":[],"x":3695.000015258789,"isLocked":true,"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"createdDate":782228945,"sessions":[],"roles":[],"x":2150.3345762176123,"isLocked":true,"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"createdDate":782145975,"sessions":[],"roles":[],"x":4627.521824291598,"isLocked":true,"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"createdDate":782228857,"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 68 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

   [LOAD-9] ✅ ctx.read() returned 68 MapPointDTO items
   [LOAD-10] First 3 point IDs from loaded data:
       DTO[1]: ID=E325D867... Pos=(3695, 4197)
       DTO[2]: ID=F5DE687B... Pos=(2150, 4358)
       DTO[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-11] Starting conversion from MapPointDTO to MapPoint
   [LOAD-12] Processing 68 DTO items
   [LOAD-13] Converting DTO[1]: ID=E325D867...
   [LOAD-13] Converting DTO[2]: ID=F5DE687B...
   [LOAD-13] Converting DTO[3]: ID=D8BF400C...
   [LOAD-14] ✅ Conversion complete: 68 MapPoint objects created
   [LOAD-15] Final points array contains 68 items
   [LOAD-16] First 3 MapPoint IDs in memory:
       MapPoint[1]: ID=E325D867... Pos=(3695, 4197)
       MapPoint[2]: ID=F5DE687B... Pos=(2150, 4358)
       MapPoint[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-17] Total sessions: 0
   [LOAD-18] Migration needed - calling save()
📦 Migrated 68 MapPoint(s) to include role metadata

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 7E771FF4...
   [SAVE-3] Current ctx.locationID = 'museum'
   [SAVE-4] points array contains 68 items
   [SAVE-5] ✅ isReloading = false, proceeding with save
   [SAVE-6] ✅ points array has 68 items - proceeding
   [SAVE-7] First 3 point IDs to be saved:
       Point[1]: ID=E325D867... Pos=(3695, 4197)
       Point[2]: ID=F5DE687B... Pos=(2150, 4358)
       Point[3]: ID=D8BF400C... Pos=(4627, 4820)
   [SAVE-8] Converting 68 MapPoint objects to MapPointDTO
   [SAVE-9] Calling ctx.write('MapPoints_v1', value: dto)
   [SAVE-10] This will write to key: 'locations.museum.MapPoints_v1'
   [SAVE-11] Full UserDefaults key: 'locations.museum.MapPoints_v1'
   [SAVE-12] ✅ Data written to UserDefaults
   [SAVE-13] No activePointID to save
   [SAVE-14] ✅ Save complete: 68 Map Point(s) saved for location 'museum'
================================================================================

================================================================================

🔍 DEBUG: loadARMarkers() called for location 'museum'
📍 Legacy AR Markers in storage: 60 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'museum'
🔄 MapPointStore: Initial load for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 909C9050...
   [LOAD-3] Accessing ctx.locationID (PersistenceContext.shared.locationID)
   [LOAD-4] Current ctx.locationID = 'museum'
   [LOAD-5] pointsKey constant = 'MapPoints_v1'
   [LOAD-6] Calling ctx.read('MapPoints_v1', as: [MapPointDTO].self)
   [LOAD-7] This will generate key: 'locations.museum.MapPoints_v1'
   [LOAD-8] Expected UserDefaults key: 'locations.museum.MapPoints_v1'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'museum'
   [3] Generated full key via key('MapPoints_v1'): 'locations.museum.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.museum.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 15198 bytes (14.84 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"isLocked":true,"roles":[],"sessions":[],"x":3695.000015258789,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","y":4197.66667175293},{"createdDate":782228945,"isLocked":true,"roles":[],"sessions":[],"x":2150.3345762176123,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","y":4358.594897588835},{"createdDate":782145975,"isLocked":true,"roles":[],"sessions":[],"x":4627.521824291598,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","y":4820.4774370841515},{"createdDate":782228857,"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 68 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

   [LOAD-9] ✅ ctx.read() returned 68 MapPointDTO items
   [LOAD-10] First 3 point IDs from loaded data:
       DTO[1]: ID=E325D867... Pos=(3695, 4197)
       DTO[2]: ID=F5DE687B... Pos=(2150, 4358)
       DTO[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-11] Starting conversion from MapPointDTO to MapPoint
   [LOAD-12] Processing 68 DTO items
   [LOAD-13] Converting DTO[1]: ID=E325D867...
   [LOAD-13] Converting DTO[2]: ID=F5DE687B...
   [LOAD-13] Converting DTO[3]: ID=D8BF400C...
   [LOAD-14] ✅ Conversion complete: 68 MapPoint objects created
   [LOAD-15] Final points array contains 68 items
   [LOAD-16] First 3 MapPoint IDs in memory:
       MapPoint[1]: ID=E325D867... Pos=(3695, 4197)
       MapPoint[2]: ID=F5DE687B... Pos=(2150, 4358)
       MapPoint[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-17] Total sessions: 0
   [LOAD-18] Migration needed - calling save()
📦 Migrated 68 MapPoint(s) to include role metadata

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 909C9050...
   [SAVE-3] Current ctx.locationID = 'museum'
   [SAVE-4] points array contains 68 items
   [SAVE-5] ✅ isReloading = false, proceeding with save
   [SAVE-6] ✅ points array has 68 items - proceeding
   [SAVE-7] First 3 point IDs to be saved:
       Point[1]: ID=E325D867... Pos=(3695, 4197)
       Point[2]: ID=F5DE687B... Pos=(2150, 4358)
       Point[3]: ID=D8BF400C... Pos=(4627, 4820)
   [SAVE-8] Converting 68 MapPoint objects to MapPointDTO
   [SAVE-9] Calling ctx.write('MapPoints_v1', value: dto)
   [SAVE-10] This will write to key: 'locations.museum.MapPoints_v1'
   [SAVE-11] Full UserDefaults key: 'locations.museum.MapPoints_v1'
   [SAVE-12] ✅ Data written to UserDefaults
   [SAVE-13] No activePointID to save
   [SAVE-14] ✅ Save complete: 68 Map Point(s) saved for location 'museum'
================================================================================

================================================================================

🔍 DEBUG: loadARMarkers() called for location 'museum'
📍 Legacy AR Markers in storage: 60 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'museum'
App is being debugged, do not track this hang
Hang detected: 0.55s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 2.53s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.38s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 909C9050...
   [LOAD-3] Accessing ctx.locationID (PersistenceContext.shared.locationID)
   [LOAD-4] Current ctx.locationID = 'museum'
   [LOAD-5] pointsKey constant = 'MapPoints_v1'
   [LOAD-6] Calling ctx.read('MapPoints_v1', as: [MapPointDTO].self)
   [LOAD-7] This will generate key: 'locations.museum.MapPoints_v1'
   [LOAD-8] Expected UserDefaults key: 'locations.museum.MapPoints_v1'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'museum'
   [3] Generated full key via key('MapPoints_v1'): 'locations.museum.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.museum.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 15198 bytes (14.84 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"roles":[],"isLocked":true,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","x":3695.000015258789},{"createdDate":782228945,"sessions":[],"y":4358.594897588835,"roles":[],"isLocked":true,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","x":2150.3345762176123},{"createdDate":782145975,"sessions":[],"y":4820.4774370841515,"roles":[],"isLocked":true,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","x":4627.521824291598},{"createdDate":782228857,"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 68 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

   [LOAD-9] ✅ ctx.read() returned 68 MapPointDTO items
   [LOAD-10] First 3 point IDs from loaded data:
       DTO[1]: ID=E325D867... Pos=(3695, 4197)
       DTO[2]: ID=F5DE687B... Pos=(2150, 4358)
       DTO[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-11] Starting conversion from MapPointDTO to MapPoint
   [LOAD-12] Processing 68 DTO items
   [LOAD-13] Converting DTO[1]: ID=E325D867...
   [LOAD-13] Converting DTO[2]: ID=F5DE687B...
   [LOAD-13] Converting DTO[3]: ID=D8BF400C...
   [LOAD-14] ✅ Conversion complete: 68 MapPoint objects created
   [LOAD-15] Final points array contains 68 items
   [LOAD-16] First 3 MapPoint IDs in memory:
       MapPoint[1]: ID=E325D867... Pos=(3695, 4197)
       MapPoint[2]: ID=F5DE687B... Pos=(2150, 4358)
       MapPoint[3]: ID=D8BF400C... Pos=(4627, 4820)
   [LOAD-17] Total sessions: 0
   [LOAD-18] Migration needed - calling save()
📦 Migrated 68 MapPoint(s) to include role metadata

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 909C9050...
   [SAVE-3] Current ctx.locationID = 'museum'
   [SAVE-4] points array contains 68 items
   [SAVE-5] ⚠️ BLOCKED: isReloading = true
   [SAVE-6] MapPointStore.save() blocked during reload operation
================================================================================

================================================================================

🔍 DEBUG: loadARMarkers() called for location 'museum'
📍 Legacy AR Markers in storage: 60 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'museum'
✅ MapPointStore: Reload complete - 68 points loaded
📂 Loaded 10 triangle(s)
MapCanvas mapTransform: ObjectIdentifier(0x0000000101c34380) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.43s (debugger attached, not reporting)
🔵 Selected triangle via long-press: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
🎯 Long-press detected - starting calibration for triangle: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: D3AAD5D9
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle D3AAD5D9
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
⚠️ getCurrentVertexID: triangleVertices is empty
⚠️ getCurrentVertexID: triangleVertices is empty
📍 Starting calibration with vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🎯 Guiding user to Map Point (3593.3, 4584.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle D3AAD5D9
📍 Calibration vertices set: ["B9714AA0", "86EB7B89", "A59BC2FB"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle D3AAD5D9
🧪 ARView ID: triangle viewing mode for D3AAD5D9
🧪 ARViewWithOverlays instance: 0x00000001280a4700
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
🔺 Entering triangle calibration mode for triangle: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 PiP Map: Displaying focused point B9714AA0 at (3593, 4584)
MapCanvas mapTransform: ObjectIdentifier(0x0000000111116a80) mapSize: (0.0, 0.0)
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
App is being debugged, do not track this hang
Hang detected: 0.43s (debugger attached, not reporting)
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
warning: using linearization / solving fallback.
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
ARSession <0x1067e4c80>: The delegate of ARSession is retaining 11 ARFrames. The camera will stop delivering camera images if the delegate keeps holding on to too many ARFrames. This could be a threading or memory management issue in the delegate and should be fixed.
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
📍 getCurrentVertexID: returning vertex[0] = B9714AA0