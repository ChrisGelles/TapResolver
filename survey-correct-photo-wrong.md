🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: F8792564...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: 0513BB7A...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: F8792564...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136,"y":4197.66667175293,"x":3695.000015258789,"sessions":[]},{"isLocked":true,"roles":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","createdDate":782228945,"y":4358.594897588835,"x":2150.3345762176123,"sessions":[]},{"isLocked":true,"roles":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","createdDate":782145975,"y":4820.4774370841515,"x":4627.521824291598,"sessions":[]},{"isLocked":true,"roles":[...
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
   [SAVE-2] Instance ID: F8792564...
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
   [LOAD-2] Instance ID: 0513BB7A...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136,"y":4197.66667175293,"x":3695.000015258789,"sessions":[]},{"isLocked":true,"roles":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","createdDate":782228945,"y":4358.594897588835,"x":2150.3345762176123,"sessions":[]},{"isLocked":true,"roles":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","createdDate":782145975,"y":4820.4774370841515,"x":4627.521824291598,"sessions":[]},{"isLocked":true,"roles":[...
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
   [SAVE-2] Instance ID: 0513BB7A...
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
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CDF29537-2266-4153-9B83-6CF1EA7EB124/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CDF29537-2266-4153-9B83-6CF1EA7EB124/Documents/locations/museum/dots.json
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
   [LOAD-2] Instance ID: F8792564...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136,"y":4197.66667175293,"x":3695.000015258789,"sessions":[]},{"isLocked":true,"roles":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","createdDate":782228945,"y":4358.594897588835,"x":2150.3345762176123,"sessions":[]},{"isLocked":true,"roles":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","createdDate":782145975,"y":4820.4774370841515,"x":4627.521824291598,"sessions":[]},{"isLocked":true,"roles":[...
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
   [SAVE-2] Instance ID: F8792564...
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
   [LOAD-2] Instance ID: 0513BB7A...
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
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"sessions":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"isLocked":true,"y":4197.66667175293,"x":3695.000015258789},{"createdDate":782228945,"sessions":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"isLocked":true,"y":4358.594897588835,"x":2150.3345762176123},{"createdDate":782145975,"sessions":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"isLocked":true,"y":4820.4774370841515,"x":4627.521824291598},{"createdDate":782228857,"...
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
   [SAVE-2] Instance ID: 0513BB7A...
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
Hang detected: 0.51s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 3.17s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.53s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 0513BB7A...
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
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"createdDate":782847128.446136,"y":4197.66667175293,"isLocked":true,"roles":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","sessions":[]},{"x":2150.3345762176123,"createdDate":782228945,"y":4358.594897588835,"isLocked":true,"roles":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","sessions":[]},{"x":4627.521824291598,"createdDate":782145975,"y":4820.4774370841515,"isLocked":true,"roles":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","sessions":[]},{"x":1931.311207952279,"cr...
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
   [SAVE-2] Instance ID: 0513BB7A...
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
MapCanvas mapTransform: ObjectIdentifier(0x000000014c106280) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.35s (debugger attached, not reporting)
🔵 Selected triangle via long-press: 1F066815-4657-4816-9AA1-FB33CAB5AB71
🎯 Long-press detected - starting calibration for triangle: 1F066815-4657-4816-9AA1-FB33CAB5AB71
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 1F066815
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 1F066815
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🎯 CalibrationState → Placing Vertices (index: 0)
📍 Starting calibration with vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
🔄 Re-calibrating triangle - clearing 1 existing markers
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🎯 Guiding user to Map Point (3593.3, 4584.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle 1F066815
📍 Calibration vertices set: ["B9714AA0", "58BA635B", "A59BC2FB"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle 1F066815
🧪 ARView ID: triangle viewing mode for 1F066815
🧪 ARViewWithOverlays instance: 0x0000000150163d40
🔺 Entering triangle calibration mode for triangle: 1F066815-4657-4816-9AA1-FB33CAB5AB71
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
📍 PiP Map: Displaying focused point B9714AA0 at (3593, 4584)
MapCanvas mapTransform: ObjectIdentifier(0x000000014e781280) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.42s (debugger attached, not reporting)
warning: using linearization / solving fallback.
📍 Placed marker A71EE329 at AR(-0.58, -1.16, -6.38) meters
📸 Saved photo to disk: B9714AA0.jpg (1145 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 0513BB7A...
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

📸 Captured photo for MapPoint B9714AA0
🔗 AR Marker planted at AR(-0.58, -1.16, -6.38) meters for Map Point (3593.3, 4584.7) pixels
📍 registerMarker called for MapPoint B9714AA0
🖼 Photo 'B9714AA0.jpg' linked to MapPoint B9714AA0
💾 Saving AR Marker:
   Marker ID: A71EE329-B888-4470-BF14-FBE221EF011A
   Linked Map Point: B9714AA0-CC7A-42E0-8344-725A2F33F30C
   AR Position: (-0.58, -1.16, -6.38) meters
   Map Coordinates: (3593.3, 4584.7) pixels
📍 Saved marker A71EE329-B888-4470-BF14-FBE221EF011A (MapPoint: B9714AA0-CC7A-42E0-8344-725A2F33F30C)
   Storage Key: ARWorldMapStore (saved successfully)
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "73CF9A75", "48007C20"]
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
   AR Markers: ["", "", "51965041"]
   Calibrated: false
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
✅ Added marker A71EE329 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=58BA635B
🎯 Guiding user to Map Point (3691.9, 4799.2)
✅ ARCalibrationCoordinator: Registered marker for MapPoint B9714AA0 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker A71EE329 for vertex B9714AA0
📍 getCurrentVertexID: returning vertex[1] = 58BA635B
📍 Placed marker 9433C158 at AR(-1.48, -1.15, -1.16) meters
📸 Saved photo to disk: 58BA635B.jpg (990 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 0513BB7A...
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

📸 Captured photo for MapPoint 58BA635B
🔗 AR Marker planted at AR(-1.48, -1.15, -1.16) meters for Map Point (3691.9, 4799.2) pixels
📍 registerMarker called for MapPoint 58BA635B
🖼 Photo '58BA635B.jpg' linked to MapPoint 58BA635B
💾 Saving AR Marker:
   Marker ID: 9433C158-BD1A-4EC9-9BF3-72AEE98C3930
   Linked Map Point: 58BA635B-D29D-481B-95F5-202A8A432D04
   AR Position: (-1.48, -1.15, -1.16) meters
   Map Coordinates: (3691.9, 4799.2) pixels
📍 Saved marker 9433C158-BD1A-4EC9-9BF3-72AEE98C3930 (MapPoint: 58BA635B-D29D-481B-95F5-202A8A432D04)
   Storage Key: ARWorldMapStore (saved successfully)
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "9433C158", "48007C20"]
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
   AR Markers: ["", "", "51965041"]
   Calibrated: false
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
✅ Added marker 9433C158 to triangle vertex 1
📍 Advanced to next vertex: index=2, vertexID=A59BC2FB
🎯 Guiding user to Map Point (4113.7, 4511.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 58BA635B (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 9433C158 for vertex 58BA635B
📍 getCurrentVertexID: returning vertex[2] = A59BC2FB
📍 Placed marker 4F2F547C at AR(8.96, -1.16, -1.98) meters
📸 Saved photo to disk: A59BC2FB.jpg (1035 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 0513BB7A...
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

📸 Captured photo for MapPoint A59BC2FB
🔗 AR Marker planted at AR(8.96, -1.16, -1.98) meters for Map Point (4113.7, 4511.7) pixels
📍 registerMarker called for MapPoint A59BC2FB
🖼 Photo 'A59BC2FB.jpg' linked to MapPoint A59BC2FB
💾 Saving AR Marker:
   Marker ID: 4F2F547C-B23D-4C1D-9196-231A31315962
   Linked Map Point: A59BC2FB-81A9-45C7-BD94-0172065DB685
   AR Position: (8.96, -1.16, -1.98) meters
   Map Coordinates: (4113.7, 4511.7) pixels
📍 Saved marker 4F2F547C-B23D-4C1D-9196-231A31315962 (MapPoint: A59BC2FB-81A9-45C7-BD94-0172065DB685)
   Storage Key: ARWorldMapStore (saved successfully)
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "9433C158", "48007C20"]
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
   Calibrated: false
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
✅ Added marker 4F2F547C to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint A59BC2FB (3/3)
⚠️ Cannot compute quality: Only found 0/3 AR markers
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "9433C158", "48007C20"]
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
✅ Marked triangle 1F066815 as calibrated (quality: 0%)
🔍 Triangle 1F066815 state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["", "", "4F2F547C"]
🎉 ARCalibrationCoordinator: Triangle 1F066815 calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 1F066815
⚠️ Could not find marker node for 
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 4F2F547C for vertex A59BC2FB
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🎯 PiP Map: Triangle complete - fitting all 3 vertices
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: 1F066815
   Features: 4936
   Size: 26.2 MB
   Path: /var/mobile/Containers/Data/Application/CDF29537-2266-4153-9B83-6CF1EA7EB124/Documents/locations/museum/ARSpatial/Strategies/worldmap/1F066815-4657-4816-9AA1-FB33CAB5AB71.armap
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "9433C158", "48007C20"]
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
✅ Set world map filename '1F066815-4657-4816-9AA1-FB33CAB5AB71.armap' for triangle 1F066815
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["A71EE329", "9433C158", "48007C20"]
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
✅ Set world map filename '1F066815-4657-4816-9AA1-FB33CAB5AB71.armap' for strategy 'ARWorldMap' on triangle 1F066815
✅ Saved ARWorldMap for triangle 1F066815
   Strategy: worldmap (ARWorldMap)
   Features: 4936
   Center: (3799, 4631)
   Radius: 7.67m
   Filename: 1F066815-4657-4816-9AA1-FB33CAB5AB71.armap
🎯 CalibrationState → Survey Mode
🧹 Cleared survey markers
📍 Plotting points within triangle A(3593.3, 4584.7) B(3691.9, 4799.2) C(4113.7, 4511.7)
✅ Found AR marker A71EE329 for vertex B9714AA0 at SIMD3<Float>(-0.5825395, -1.1622814, -6.383946)
✅ Found AR marker 9433C158 for vertex 58BA635B at SIMD3<Float>(-1.4788394, -1.1535882, -1.1580839)
✅ Found AR marker 4F2F547C for vertex A59BC2FB at SIMD3<Float>(8.958055, -1.1619493, -1.9809241)
🌍 Planting Survey Markers within triangle A(-0.58, -1.16, -6.38) B(-1.48, -1.15, -1.16) C(8.96, -1.16, -1.98)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(4113.7, 4511.7) s2(4029.3, 4569.2) s3(3945.0, 4626.7) s4(3860.6, 4684.2) s5(3776.3, 4741.7) s6(3691.9, 4799.2) s7(4009.6, 4526.3) s8(3925.2, 4583.8) s9(3840.9, 4641.3) s10(3756.5, 4698.8) s11(3672.2, 4756.3) s12(3905.5, 4540.9) s13(3821.2, 4598.4) s14(3736.8, 4655.9) s15(3801.4, 4555.5) s16(3717.1, 4613.0) s17(3697.4, 4570.1) s18(3593.3, 4584.7) 
📍 Survey Marker placed at (8.96, -1.16, -1.98)
📍 Survey Marker placed at (8.96, -1.16, -1.98)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(8.96, -1.16, -1.98)
📍 Survey marker placed at map(4113.7, 4511.7) → AR(8.96, -1.16, -1.98)
📍 Survey Marker placed at (6.87, -1.16, -1.82)
📍 Survey Marker placed at (6.87, -1.16, -1.82)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(6.87, -1.16, -1.82)
📍 Survey marker placed at map(4029.3, 4569.2) → AR(6.87, -1.16, -1.82)
📍 Survey Marker placed at (4.78, -1.16, -1.65)
📍 Survey Marker placed at (4.78, -1.16, -1.65)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(4.78, -1.16, -1.65)
📍 Survey marker placed at map(3945.0, 4626.7) → AR(4.78, -1.16, -1.65)
📍 Survey Marker placed at (2.70, -1.16, -1.49)
📍 Survey Marker placed at (2.70, -1.16, -1.49)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(2.70, -1.16, -1.49)
📍 Survey marker placed at map(3860.6, 4684.2) → AR(2.70, -1.16, -1.49)
📍 Survey Marker placed at (0.61, -1.16, -1.32)
📍 Survey Marker placed at (0.61, -1.16, -1.32)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(0.61, -1.16, -1.32)
📍 Survey marker placed at map(3776.3, 4741.7) → AR(0.61, -1.16, -1.32)
📍 Survey Marker placed at (-1.48, -1.16, -1.16)
📍 Survey Marker placed at (-1.48, -1.16, -1.16)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.48, -1.16, -1.16)
📍 Survey marker placed at map(3691.9, 4799.2) → AR(-1.48, -1.16, -1.16)
📍 Survey Marker placed at (7.05, -1.16, -2.86)
📍 Survey Marker placed at (7.05, -1.16, -2.86)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(7.05, -1.16, -2.86)
📍 Survey marker placed at map(4009.6, 4526.3) → AR(7.05, -1.16, -2.86)
📍 Survey Marker placed at (4.96, -1.16, -2.70)
📍 Survey Marker placed at (4.96, -1.16, -2.70)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(4.96, -1.16, -2.70)
📍 Survey marker placed at map(3925.2, 4583.8) → AR(4.96, -1.16, -2.70)
📍 Survey Marker placed at (2.88, -1.16, -2.53)
📍 Survey Marker placed at (2.88, -1.16, -2.53)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(2.88, -1.16, -2.53)
📍 Survey marker placed at map(3840.9, 4641.3) → AR(2.88, -1.16, -2.53)
📍 Survey Marker placed at (0.79, -1.16, -2.37)
📍 Survey Marker placed at (0.79, -1.16, -2.37)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(0.79, -1.16, -2.37)
📍 Survey marker placed at map(3756.5, 4698.8) → AR(0.79, -1.16, -2.37)
📍 Survey Marker placed at (-1.30, -1.16, -2.20)
📍 Survey Marker placed at (-1.30, -1.16, -2.20)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.30, -1.16, -2.20)
📍 Survey marker placed at map(3672.2, 4756.3) → AR(-1.30, -1.16, -2.20)
📍 Survey Marker placed at (5.14, -1.16, -3.74)
📍 Survey Marker placed at (5.14, -1.16, -3.74)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(5.14, -1.16, -3.74)
📍 Survey marker placed at map(3905.5, 4540.9) → AR(5.14, -1.16, -3.74)
📍 Survey Marker placed at (3.05, -1.16, -3.58)
📍 Survey Marker placed at (3.05, -1.16, -3.58)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(3.05, -1.16, -3.58)
📍 Survey marker placed at map(3821.2, 4598.4) → AR(3.05, -1.16, -3.58)
📍 Survey Marker placed at (0.97, -1.16, -3.41)
📍 Survey Marker placed at (0.97, -1.16, -3.41)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(0.97, -1.16, -3.41)
📍 Survey marker placed at map(3736.8, 4655.9) → AR(0.97, -1.16, -3.41)
📍 Survey Marker placed at (3.23, -1.16, -4.62)
📍 Survey Marker placed at (3.23, -1.16, -4.62)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(3.23, -1.16, -4.62)
📍 Survey marker placed at map(3801.4, 4555.5) → AR(3.23, -1.16, -4.62)
📍 Survey Marker placed at (1.15, -1.16, -4.46)
📍 Survey Marker placed at (1.15, -1.16, -4.46)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(1.15, -1.16, -4.46)
📍 Survey marker placed at map(3717.1, 4613.0) → AR(1.15, -1.16, -4.46)
📍 Survey Marker placed at (1.33, -1.16, -5.50)
📍 Survey Marker placed at (1.33, -1.16, -5.50)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(1.33, -1.16, -5.50)
📍 Survey marker placed at map(3697.4, 4570.1) → AR(1.33, -1.16, -5.50)
📍 Survey Marker placed at (-0.58, -1.16, -6.38)
📍 Survey Marker placed at (-0.58, -1.16, -6.38)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-0.58, -1.16, -6.38)
📍 Survey marker placed at map(3593.3, 4584.7) → AR(-0.58, -1.16, -6.38)
📊 3D Survey Markers: s1(4.78, -1.16, -1.65) s2(-1.30, -1.16, -2.20) s3(2.88, -1.16, -2.53) s4(1.33, -1.16, -5.50) s5(4.96, -1.16, -2.70) s6(8.96, -1.16, -1.98) s7(6.87, -1.16, -1.82) s8(5.14, -1.16, -3.74) s9(3.23, -1.16, -4.62) s10(-1.48, -1.16, -1.16) s11(0.79, -1.16, -2.37) s12(1.15, -1.16, -4.46) s13(0.97, -1.16, -3.41) s14(3.05, -1.16, -3.58) s15(2.70, -1.16, -1.49) s16(7.05, -1.16, -2.86) s17(-0.58, -1.16, -6.38) s18(0.61, -1.16, -1.32) 
✅ Placed 18 survey markers
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
ðŸŽ¯ Location Menu button tapped!
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 0513BB7A...
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
   [SAVE-2] Instance ID: 0513BB7A...
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
MapCanvas mapTransform: ObjectIdentifier(0x000000014c106280) mapSize: (8192.0, 8192.0)
App is being debugged, do not track this hang
Hang detected: 0.31s (debugger attached, not reporting)