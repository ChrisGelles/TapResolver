🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 0380653B...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: 48B99B2E...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 0380653B...
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
   [6] Data size: 15602 bytes (15.24 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"roles":[],"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","isLocked":true,"createdDate":782847128.446136},{"x":2150.3345762176123,"roles":[],"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","isLocked":true,"createdDate":782228945},{"x":4627.521824291598,"roles":[],"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","isLocked":true,"createdDate":782145975},{"x":1931.311207952279,"ro...
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
   [SAVE-2] Instance ID: 0380653B...
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
   [LOAD-2] Instance ID: 48B99B2E...
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
   [6] Data size: 15602 bytes (15.24 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"roles":[],"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","isLocked":true,"createdDate":782847128.446136},{"x":2150.3345762176123,"roles":[],"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","isLocked":true,"createdDate":782228945},{"x":4627.521824291598,"roles":[],"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","isLocked":true,"createdDate":782145975},{"x":1931.311207952279,"ro...
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
   [SAVE-2] Instance ID: 48B99B2E...
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
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/C6A18215-4028-4CEA-BEFD-0DC654237A42/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/C6A18215-4028-4CEA-BEFD-0DC654237A42/Documents/locations/museum/dots.json
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
   [LOAD-2] Instance ID: 0380653B...
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
   [6] Data size: 15602 bytes (15.24 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"roles":[],"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","isLocked":true,"createdDate":782847128.446136},{"x":2150.3345762176123,"roles":[],"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","isLocked":true,"createdDate":782228945},{"x":4627.521824291598,"roles":[],"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","isLocked":true,"createdDate":782145975},{"x":1931.311207952279,"ro...
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
   [SAVE-2] Instance ID: 0380653B...
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
   [LOAD-2] Instance ID: 48B99B2E...
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
   [6] Data size: 15602 bytes (15.24 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"createdDate":782847128.446136,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","sessions":[],"x":3695.000015258789,"y":4197.66667175293,"roles":[]},{"isLocked":true,"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","sessions":[],"x":2150.3345762176123,"y":4358.594897588835,"roles":[]},{"isLocked":true,"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","sessions":[],"x":4627.521824291598,"y":4820.4774370841515,"roles":[]},{"isLocked":true,"createdD...
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
   [SAVE-2] Instance ID: 48B99B2E...
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
Hang detected: 2.92s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 48B99B2E...
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
   [6] Data size: 15602 bytes (15.24 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"createdDate":782847128.446136,"isLocked":true,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"createdDate":782228945,"isLocked":true,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"createdDate":782145975,"isLocked":true,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"id":"E4C4E0FD-A421-48A1-...
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
   [SAVE-2] Instance ID: 48B99B2E...
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
MapCanvas mapTransform: ObjectIdentifier(0x0000000106c33980) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.33s (debugger attached, not reporting)
🔵 Selected triangle via long-press: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
🎯 Long-press detected - starting calibration for triangle: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: D3AAD5D9
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle D3AAD5D9
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
🎯 CalibrationState → Placing Vertices (index: 0)
📍 Starting calibration with vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🎯 Guiding user to Map Point (3593.3, 4584.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle D3AAD5D9
📍 Calibration vertices set: ["B9714AA0", "86EB7B89", "A59BC2FB"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle D3AAD5D9
🧪 ARView ID: triangle viewing mode for D3AAD5D9
🧪 ARViewWithOverlays instance: 0x00000001164196c0
🔺 Entering triangle calibration mode for triangle: D3AAD5D9-F462-44A3-95F1-7DFEA930527F
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
📍 PiP Map: Displaying focused point B9714AA0 at (3593, 4584)
MapCanvas mapTransform: ObjectIdentifier(0x0000000116540500) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.37s (debugger attached, not reporting)
warning: using linearization / solving fallback.
🔍 [PHOTO_REF] Displaying photo reference for vertex B9714AA0
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
📍 Placed marker 85A0CF0D at AR(3.79, -1.24, -5.38) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000107648088 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA132_yAE6CircleVA24_G_Qo__A157_A157_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA161__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_A123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A170_Qo__Qo_tGG_Qo__Qo_A175_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA183__A183_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 85A0CF0D
   currentVertexID: B9714AA0
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: B9714AA0
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: B9714AA0.jpg (1104 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 48B99B2E...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint B9714AA0
🔗 AR Marker planted at AR(3.79, -1.24, -5.38) meters for Map Point (3593.3, 4584.7) pixels
📍 registerMarker called for MapPoint B9714AA0
🖼 Photo 'B9714AA0.jpg' linked to MapPoint B9714AA0
💾 Saving AR Marker:
   Marker ID: 85A0CF0D-7FD4-4903-BF50-EE919014517D
   Linked Map Point: B9714AA0-CC7A-42E0-8344-725A2F33F30C
   AR Position: (3.79, -1.24, -5.38) meters
   Map Coordinates: (3593.3, 4584.7) pixels
📍 Saved marker 85A0CF0D-7FD4-4903-BF50-EE919014517D (MapPoint: B9714AA0-CC7A-42E0-8344-725A2F33F30C)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: B9714AA0
   markerID: 85A0CF0D
🔍 [ADD_MARKER_TRACE] Triangle found at index 0:
   Triangle ID: 19A9999C
   Current arMarkerIDs: ["A71EE329-B888-4470-BF14-FBE221EF011A", "9433C158-BD1A-4EC9-9BF3-72AEE98C3930", "48007C20-DF2C-4153-93DC-CCCFD634F06B"]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: 'A71EE329-B888-4470-BF14-FBE221EF011A'
   New value: '85A0CF0D-7FD4-4903-BF50-EE919014517D'
   Updated arMarkerIDs: ["85A0CF0D-7FD4-4903-BF50-EE919014517D", "9433C158-BD1A-4EC9-9BF3-72AEE98C3930", "48007C20-DF2C-4153-93DC-CCCFD634F06B"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "4F2F547C"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 85A0CF0D to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=86EB7B89
🎯 Guiding user to Map Point (3889.5, 4260.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint B9714AA0 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 85A0CF0D for vertex B9714AA0
📍 getCurrentVertexID: returning vertex[1] = 86EB7B89
🔍 [PHOTO_REF] Displaying photo reference for vertex 86EB7B89
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
📍 Placed marker E21CBB0F at AR(11.71, -1.20, -1.48) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000107648088 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA132_yAE6CircleVA24_G_Qo__A157_A157_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA161__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_A123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A170_Qo__Qo_tGG_Qo__Qo_A175_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA183__A183_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: E21CBB0F
   currentVertexID: 86EB7B89
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 86EB7B89
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 86EB7B89.jpg (899 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 48B99B2E...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint 86EB7B89
🔗 AR Marker planted at AR(11.71, -1.20, -1.48) meters for Map Point (3889.5, 4260.7) pixels
📍 registerMarker called for MapPoint 86EB7B89
🖼 Photo '86EB7B89.jpg' linked to MapPoint 86EB7B89
💾 Saving AR Marker:
   Marker ID: E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489
   Linked Map Point: 86EB7B89-DA39-4295-BDCC-CF43DC1DFCFA
   AR Position: (11.71, -1.20, -1.48) meters
   Map Coordinates: (3889.5, 4260.7) pixels
📍 Saved marker E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489 (MapPoint: 86EB7B89-DA39-4295-BDCC-CF43DC1DFCFA)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: 86EB7B89
   markerID: E21CBB0F
🔍 [ADD_MARKER_TRACE] Triangle found at index 5:
   Triangle ID: 3E553D63
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Expanded arMarkerIDs array to 1 slots
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: 'E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489'
   Updated arMarkerIDs: ["E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "4F2F547C"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["E21CBB0F"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker E21CBB0F to triangle vertex 0
📍 Advanced to next vertex: index=2, vertexID=A59BC2FB
🎯 Guiding user to Map Point (4113.7, 4511.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 86EB7B89 (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker E21CBB0F for vertex 86EB7B89
📍 getCurrentVertexID: returning vertex[2] = A59BC2FB
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [PHOTO_REF] Displaying photo reference for vertex A59BC2FB
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
📍 Placed marker 0F9B237D at AR(8.49, -1.21, 4.24) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000107648088 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA132_yAE6CircleVA24_G_Qo__A157_A157_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA161__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_A123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A170_Qo__Qo_tGG_Qo__Qo_A175_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA183__A183_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 0F9B237D
   currentVertexID: A59BC2FB
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: A59BC2FB
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: A59BC2FB.jpg (1045 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 48B99B2E...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint A59BC2FB
🔗 AR Marker planted at AR(8.49, -1.21, 4.24) meters for Map Point (4113.7, 4511.7) pixels
📍 registerMarker called for MapPoint A59BC2FB
🖼 Photo 'A59BC2FB.jpg' linked to MapPoint A59BC2FB
💾 Saving AR Marker:
   Marker ID: 0F9B237D-19B7-44C8-946C-EEF846EA1550
   Linked Map Point: A59BC2FB-81A9-45C7-BD94-0172065DB685
   AR Position: (8.49, -1.21, 4.24) meters
   Map Coordinates: (4113.7, 4511.7) pixels
📍 Saved marker 0F9B237D-19B7-44C8-946C-EEF846EA1550 (MapPoint: A59BC2FB-81A9-45C7-BD94-0172065DB685)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: A59BC2FB
   markerID: 0F9B237D
🔍 [ADD_MARKER_TRACE] Triangle found at index 3:
   Triangle ID: 1F066815
   Current arMarkerIDs: ["", "", "4F2F547C-B23D-4C1D-9196-231A31315962"]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: '4F2F547C-B23D-4C1D-9196-231A31315962'
   New value: '0F9B237D-19B7-44C8-946C-EEF846EA1550'
   Updated arMarkerIDs: ["", "", "0F9B237D-19B7-44C8-946C-EEF846EA1550"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "0F9B237D"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["E21CBB0F"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 0F9B237D to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint A59BC2FB (3/3)
⚠️ Cannot compute quality: Need 3 AR marker IDs
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "0F9B237D"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["E21CBB0F"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ Marked triangle D3AAD5D9 as calibrated (quality: 0%)
🔍 Triangle D3AAD5D9 state after marking:
   isCalibrated: true
   arMarkerIDs count: 0
   arMarkerIDs: []
🎉 ARCalibrationCoordinator: Triangle D3AAD5D9 calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for D3AAD5D9
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 0F9B237D for vertex A59BC2FB
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🎯 PiP Map: Triangle complete - fitting all 3 vertices
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: D3AAD5D9
   Features: 4622
   Size: 23.1 MB
   Path: /var/mobile/Containers/Data/Application/C6A18215-4028-4CEA-BEFD-0DC654237A42/Documents/locations/museum/ARSpatial/Strategies/worldmap/D3AAD5D9-F462-44A3-95F1-7DFEA930527F.armap
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "0F9B237D"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["E21CBB0F"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ Set world map filename 'D3AAD5D9-F462-44A3-95F1-7DFEA930527F.armap' for triangle D3AAD5D9
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["85A0CF0D", "9433C158", "48007C20"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["", "9834125B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: ["", "", "0F9B237D"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["E21CBB0F"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
✅ Set world map filename 'D3AAD5D9-F462-44A3-95F1-7DFEA930527F.armap' for strategy 'ARWorldMap' on triangle D3AAD5D9
✅ Saved ARWorldMap for triangle D3AAD5D9
   Strategy: worldmap (ARWorldMap)
   Features: 4622
   Center: (3865, 4452)
   Radius: 6.90m
   Filename: D3AAD5D9-F462-44A3-95F1-7DFEA930527F.armap
🎯 CalibrationState → Survey Mode
🧹 Cleared survey markers
📍 Plotting points within triangle A(3593.3, 4584.7) B(3889.5, 4260.7) C(4113.7, 4511.7)
✅ Found AR marker 85A0CF0D for vertex B9714AA0 at SIMD3<Float>(3.7868762, -1.2365592, -5.375009)
✅ Found AR marker E21CBB0F for vertex 86EB7B89 at SIMD3<Float>(11.708721, -1.1985043, -1.4765911)
✅ Found AR marker 0F9B237D for vertex A59BC2FB at SIMD3<Float>(8.486735, -1.2097543, 4.236746)
🌍 Planting Survey Markers within triangle A(3.79, -1.24, -5.38) B(11.71, -1.20, -1.48) C(8.49, -1.21, 4.24)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 28 survey points at 1.0m spacing
📊 2D Survey Points: s1(4113.7, 4511.7) s2(4076.3, 4469.9) s3(4038.9, 4428.0) s4(4001.6, 4386.2) s5(3964.2, 4344.4) s6(3926.8, 4302.6) s7(3889.5, 4260.7) s8(4026.9, 4523.8) s9(3989.6, 4482.0) s10(3952.2, 4440.2) s11(3914.8, 4398.4) s12(3877.5, 4356.6) s13(3840.1, 4314.7) s14(3940.2, 4536.0) s15(3902.8, 4494.2) s16(3865.5, 4452.4) s17(3828.1, 4410.5) s18(3790.7, 4368.7) s19(3853.5, 4548.2) s20(3816.1, 4506.4) ... (8 more)
📍 Survey Marker placed at (8.49, -1.21, 4.24)
📍 Survey Marker placed at (8.49, -1.21, 4.24)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(8.49, -1.21, 4.24)
📍 Survey marker placed at map(4113.7, 4511.7) → AR(8.49, -1.21, 4.24)
📍 Survey Marker placed at (9.02, -1.21, 3.28)
📍 Survey Marker placed at (9.02, -1.21, 3.28)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(9.02, -1.21, 3.28)
📍 Survey marker placed at map(4076.3, 4469.9) → AR(9.02, -1.21, 3.28)
📍 Survey Marker placed at (9.56, -1.21, 2.33)
📍 Survey Marker placed at (9.56, -1.21, 2.33)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(9.56, -1.21, 2.33)
📍 Survey marker placed at map(4038.9, 4428.0) → AR(9.56, -1.21, 2.33)
📍 Survey Marker placed at (10.10, -1.21, 1.38)
📍 Survey Marker placed at (10.10, -1.21, 1.38)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(10.10, -1.21, 1.38)
📍 Survey marker placed at map(4001.6, 4386.2) → AR(10.10, -1.21, 1.38)
📍 Survey Marker placed at (10.63, -1.21, 0.43)
📍 Survey Marker placed at (10.63, -1.21, 0.43)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(10.63, -1.21, 0.43)
📍 Survey marker placed at map(3964.2, 4344.4) → AR(10.63, -1.21, 0.43)
📍 Survey Marker placed at (11.17, -1.21, -0.53)
📍 Survey Marker placed at (11.17, -1.21, -0.53)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(11.17, -1.21, -0.53)
📍 Survey marker placed at map(3926.8, 4302.6) → AR(11.17, -1.21, -0.53)
📍 Survey Marker placed at (11.71, -1.21, -1.48)
📍 Survey Marker placed at (11.71, -1.21, -1.48)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(11.71, -1.21, -1.48)
📍 Survey marker placed at map(3889.5, 4260.7) → AR(11.71, -1.21, -1.48)
📍 Survey Marker placed at (7.70, -1.21, 2.63)
📍 Survey Marker placed at (7.70, -1.21, 2.63)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.70, -1.21, 2.63)
📍 Survey marker placed at map(4026.9, 4523.8) → AR(7.70, -1.21, 2.63)
📍 Survey Marker placed at (8.24, -1.21, 1.68)
📍 Survey Marker placed at (8.24, -1.21, 1.68)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(8.24, -1.21, 1.68)
📍 Survey marker placed at map(3989.6, 4482.0) → AR(8.24, -1.21, 1.68)
📍 Survey Marker placed at (8.78, -1.21, 0.73)
📍 Survey Marker placed at (8.78, -1.21, 0.73)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(8.78, -1.21, 0.73)
📍 Survey marker placed at map(3952.2, 4440.2) → AR(8.78, -1.21, 0.73)
📍 Survey Marker placed at (9.31, -1.21, -0.22)
📍 Survey Marker placed at (9.31, -1.21, -0.22)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(9.31, -1.21, -0.22)
📍 Survey marker placed at map(3914.8, 4398.4) → AR(9.31, -1.21, -0.22)
📍 Survey Marker placed at (9.85, -1.21, -1.17)
📍 Survey Marker placed at (9.85, -1.21, -1.17)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(9.85, -1.21, -1.17)
📍 Survey marker placed at map(3877.5, 4356.6) → AR(9.85, -1.21, -1.17)
📍 Survey Marker placed at (10.39, -1.21, -2.13)
📍 Survey Marker placed at (10.39, -1.21, -2.13)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(10.39, -1.21, -2.13)
📍 Survey marker placed at map(3840.1, 4314.7) → AR(10.39, -1.21, -2.13)
📍 Survey Marker placed at (6.92, -1.21, 1.03)
📍 Survey Marker placed at (6.92, -1.21, 1.03)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(6.92, -1.21, 1.03)
📍 Survey marker placed at map(3940.2, 4536.0) → AR(6.92, -1.21, 1.03)
📍 Survey Marker placed at (7.46, -1.21, 0.08)
📍 Survey Marker placed at (7.46, -1.21, 0.08)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.46, -1.21, 0.08)
📍 Survey marker placed at map(3902.8, 4494.2) → AR(7.46, -1.21, 0.08)
📍 Survey Marker placed at (7.99, -1.21, -0.87)
📍 Survey Marker placed at (7.99, -1.21, -0.87)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.99, -1.21, -0.87)
📍 Survey marker placed at map(3865.5, 4452.4) → AR(7.99, -1.21, -0.87)
📍 Survey Marker placed at (8.53, -1.21, -1.82)
📍 Survey Marker placed at (8.53, -1.21, -1.82)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(8.53, -1.21, -1.82)
📍 Survey marker placed at map(3828.1, 4410.5) → AR(8.53, -1.21, -1.82)
📍 Survey Marker placed at (9.07, -1.21, -2.78)
📍 Survey Marker placed at (9.07, -1.21, -2.78)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(9.07, -1.21, -2.78)
📍 Survey marker placed at map(3790.7, 4368.7) → AR(9.07, -1.21, -2.78)
📍 Survey Marker placed at (6.14, -1.21, -0.57)
📍 Survey Marker placed at (6.14, -1.21, -0.57)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(6.14, -1.21, -0.57)
📍 Survey marker placed at map(3853.5, 4548.2) → AR(6.14, -1.21, -0.57)
📍 Survey Marker placed at (6.67, -1.21, -1.52)
📍 Survey Marker placed at (6.67, -1.21, -1.52)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(6.67, -1.21, -1.52)
📍 Survey marker placed at map(3816.1, 4506.4) → AR(6.67, -1.21, -1.52)
📍 Survey Marker placed at (7.21, -1.21, -2.47)
📍 Survey Marker placed at (7.21, -1.21, -2.47)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.21, -1.21, -2.47)
📍 Survey marker placed at map(3778.7, 4464.5) → AR(7.21, -1.21, -2.47)
📍 Survey Marker placed at (7.75, -1.21, -3.43)
📍 Survey Marker placed at (7.75, -1.21, -3.43)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.75, -1.21, -3.43)
📍 Survey marker placed at map(3741.4, 4422.7) → AR(7.75, -1.21, -3.43)
📍 Survey Marker placed at (5.35, -1.21, -2.17)
📍 Survey Marker placed at (5.35, -1.21, -2.17)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(5.35, -1.21, -2.17)
📍 Survey marker placed at map(3766.7, 4560.3) → AR(5.35, -1.21, -2.17)
📍 Survey Marker placed at (5.89, -1.21, -3.12)
📍 Survey Marker placed at (5.89, -1.21, -3.12)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(5.89, -1.21, -3.12)
📍 Survey marker placed at map(3729.4, 4518.5) → AR(5.89, -1.21, -3.12)
📍 Survey Marker placed at (6.43, -1.21, -4.08)
📍 Survey Marker placed at (6.43, -1.21, -4.08)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(6.43, -1.21, -4.08)
📍 Survey marker placed at map(3692.0, 4476.7) → AR(6.43, -1.21, -4.08)
📍 Survey Marker placed at (4.57, -1.21, -3.77)
📍 Survey Marker placed at (4.57, -1.21, -3.77)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(4.57, -1.21, -3.77)
📍 Survey marker placed at map(3680.0, 4572.5) → AR(4.57, -1.21, -3.77)
📍 Survey Marker placed at (5.11, -1.21, -4.73)
📍 Survey Marker placed at (5.11, -1.21, -4.73)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(5.11, -1.21, -4.73)
📍 Survey marker placed at map(3642.6, 4530.7) → AR(5.11, -1.21, -4.73)
📍 Survey Marker placed at (3.79, -1.21, -5.37)
📍 Survey Marker placed at (3.79, -1.21, -5.37)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(3.79, -1.21, -5.37)
📍 Survey marker placed at map(3593.3, 4584.7) → AR(3.79, -1.21, -5.37)
📊 3D Survey Markers: s1(3.79, -1.21, -5.37) s2(9.07, -1.21, -2.78) s3(9.31, -1.21, -0.22) s4(8.78, -1.21, 0.73) s5(7.46, -1.21, 0.08) s6(4.57, -1.21, -3.77) s7(9.56, -1.21, 2.33) s8(8.24, -1.21, 1.68) s9(8.49, -1.21, 4.24) s10(5.89, -1.21, -3.12) s11(6.14, -1.21, -0.57) s12(7.70, -1.21, 2.63) s13(7.75, -1.21, -3.43) s14(5.35, -1.21, -2.17) s15(9.02, -1.21, 3.28) s16(6.67, -1.21, -1.52) s17(5.11, -1.21, -4.73) s18(6.43, -1.21, -4.08) s19(9.85, -1.21, -1.17) s20(7.99, -1.21, -0.87) ... (8 more)
✅ Placed 28 survey markers
🔍 [PIP_MAP] State changed: Survey Mode
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
ðŸŽ¯ Location Menu button tapped!