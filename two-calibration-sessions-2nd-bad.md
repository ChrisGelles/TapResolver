🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 444B2BD1...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: F004F8ED...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 444B2BD1...
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
   [6] Data size: 15745 bytes (15.38 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"createdDate":782847128.446136,"y":4197.66667175293,"sessions":[],"isLocked":true},{"x":2150.3345762176123,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"createdDate":782228945,"y":4358.594897588835,"sessions":[],"isLocked":true},{"x":4627.521824291598,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"createdDate":782145975,"y":4820.4774370841515,"sessions":[],"isLocked":true},{"x":1931.311207952279,"id...
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
   [SAVE-2] Instance ID: 444B2BD1...
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
   [LOAD-2] Instance ID: F004F8ED...
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
   [6] Data size: 15745 bytes (15.38 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"createdDate":782847128.446136,"y":4197.66667175293,"sessions":[],"isLocked":true},{"x":2150.3345762176123,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"createdDate":782228945,"y":4358.594897588835,"sessions":[],"isLocked":true},{"x":4627.521824291598,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"createdDate":782145975,"y":4820.4774370841515,"sessions":[],"isLocked":true},{"x":1931.311207952279,"id...
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
   [SAVE-2] Instance ID: F004F8ED...
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
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/211DA88E-EE25-44A2-B725-E9DA3ACA0424/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/211DA88E-EE25-44A2-B725-E9DA3ACA0424/Documents/locations/museum/dots.json
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
   [LOAD-2] Instance ID: 444B2BD1...
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
   [6] Data size: 15745 bytes (15.38 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"createdDate":782847128.446136,"y":4197.66667175293,"sessions":[],"isLocked":true},{"x":2150.3345762176123,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"createdDate":782228945,"y":4358.594897588835,"sessions":[],"isLocked":true},{"x":4627.521824291598,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"createdDate":782145975,"y":4820.4774370841515,"sessions":[],"isLocked":true},{"x":1931.311207952279,"id...
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
   [SAVE-2] Instance ID: 444B2BD1...
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
   [LOAD-2] Instance ID: F004F8ED...
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
   [6] Data size: 15745 bytes (15.38 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"roles":[],"isLocked":true,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"roles":[],"isLocked":true,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","createdDate":782228945,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"roles":[],"isLocked":true,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","createdDate":782145975,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"roles":[],"isLocked":tru...
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
   [SAVE-2] Instance ID: F004F8ED...
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
Hang detected: 3.20s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.42s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: F004F8ED...
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
   [6] Data size: 15745 bytes (15.38 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"roles":[],"isLocked":true,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"roles":[],"isLocked":true,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","createdDate":782228945,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"roles":[],"isLocked":true,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","createdDate":782145975,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"roles":[],"isLocked":tru...
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
   [SAVE-2] Instance ID: F004F8ED...
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
MapCanvas mapTransform: ObjectIdentifier(0x0000000150032b00) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.35s (debugger attached, not reporting)
🔵 Selected triangle via long-press: 3E553D63-BEE5-4A16-A64B-36A6A9D753E1
🎯 Long-press detected - starting calibration for triangle: 3E553D63-BEE5-4A16-A64B-36A6A9D753E1
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 3E553D63
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 3E553D63
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: ["E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489"]
🧹 [CLEAR_MARKERS] Clearing markers for triangle 3E553D63
   Before: ["E21CBB0F-CCCD-41E8-AEBF-4D1FAFE28489"]
   After: []
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [CLEAR_MARKERS] Cleared and saved
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
   New arMarkerIDs: []
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
📍 Starting calibration with vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
🔄 Re-calibrating triangle - clearing 1 existing markers
📍 getCurrentVertexID: returning vertex[0] = 86EB7B89
🎯 Guiding user to Map Point (3889.5, 4260.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle 3E553D63
📍 Calibration vertices set: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle 3E553D63
🧪 ARView ID: triangle viewing mode for 3E553D63
🧪 ARViewWithOverlays instance: 0x000000015494ebc0
🔺 Entering triangle calibration mode for triangle: 3E553D63-BEE5-4A16-A64B-36A6A9D753E1
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex 86EB7B89
📍 PiP Map: Displaying focused point 86EB7B89 at (3889, 4260)
MapCanvas mapTransform: ObjectIdentifier(0x0000000150032c80) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.44s (debugger attached, not reporting)
warning: using linearization / solving fallback.
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 94C6F600 at AR(11.70, -1.25, -2.29) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 94C6F600
   currentVertexID: 86EB7B89
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 86EB7B89
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 86EB7B89.jpg (917 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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
🔗 AR Marker planted at AR(11.70, -1.25, -2.29) meters for Map Point (3889.5, 4260.7) pixels
📍 registerMarker called for MapPoint 86EB7B89
🖼 Photo '86EB7B89.jpg' linked to MapPoint 86EB7B89
💾 Saving AR Marker:
   Marker ID: 94C6F600-CC4A-4493-A85D-A50CBC3937F4
   Linked Map Point: 86EB7B89-DA39-4295-BDCC-CF43DC1DFCFA
   AR Position: (11.70, -1.25, -2.29) meters
   Map Coordinates: (3889.5, 4260.7) pixels
📍 Saved marker 94C6F600-CC4A-4493-A85D-A50CBC3937F4 (MapPoint: 86EB7B89-DA39-4295-BDCC-CF43DC1DFCFA)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: 86EB7B89
   markerID: 94C6F600
🔍 [ADD_MARKER_TRACE] Triangle found at index 5:
   Triangle ID: 3E553D63
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: '94C6F600-CC4A-4493-A85D-A50CBC3937F4'
   Updated arMarkerIDs: ["94C6F600-CC4A-4493-A85D-A50CBC3937F4", "", ""]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["94C6F600", "", ""]
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 94C6F600 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=A59BC2FB
🎯 Guiding user to Map Point (4113.7, 4511.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 86EB7B89 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 94C6F600 for vertex 86EB7B89
📍 getCurrentVertexID: returning vertex[1] = A59BC2FB
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 265501BE at AR(9.03, -1.25, 3.76) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 265501BE
   currentVertexID: A59BC2FB
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: A59BC2FB
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: A59BC2FB.jpg (1120 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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
🔗 AR Marker planted at AR(9.03, -1.25, 3.76) meters for Map Point (4113.7, 4511.7) pixels
📍 registerMarker called for MapPoint A59BC2FB
🖼 Photo 'A59BC2FB.jpg' linked to MapPoint A59BC2FB
💾 Saving AR Marker:
   Marker ID: 265501BE-8153-4FC7-88FF-CE1A9E51CE4A
   Linked Map Point: A59BC2FB-81A9-45C7-BD94-0172065DB685
   AR Position: (9.03, -1.25, 3.76) meters
   Map Coordinates: (4113.7, 4511.7) pixels
📍 Saved marker 265501BE-8153-4FC7-88FF-CE1A9E51CE4A (MapPoint: A59BC2FB-81A9-45C7-BD94-0172065DB685)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: A59BC2FB
   markerID: 265501BE
🔍 [ADD_MARKER_TRACE] Triangle found at index 3:
   Triangle ID: 1F066815
   Current arMarkerIDs: ["", "", "0F9B237D-19B7-44C8-946C-EEF846EA1550"]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: '0F9B237D-19B7-44C8-946C-EEF846EA1550'
   New value: '265501BE-8153-4FC7-88FF-CE1A9E51CE4A'
   Updated arMarkerIDs: ["", "", "265501BE-8153-4FC7-88FF-CE1A9E51CE4A"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", ""]
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 265501BE to triangle vertex 2
📍 Advanced to next vertex: index=2, vertexID=CD8E90BB
🎯 Guiding user to Map Point (4191.0, 4227.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint A59BC2FB (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 265501BE for vertex A59BC2FB
📍 getCurrentVertexID: returning vertex[2] = CD8E90BB
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 9C022FCC at AR(14.95, -1.22, 2.96) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 9C022FCC
   currentVertexID: CD8E90BB
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: CD8E90BB
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: CD8E90BB.jpg (863 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint CD8E90BB
🔗 AR Marker planted at AR(14.95, -1.22, 2.96) meters for Map Point (4191.0, 4227.7) pixels
📍 registerMarker called for MapPoint CD8E90BB
🖼 Photo 'CD8E90BB.jpg' linked to MapPoint CD8E90BB
💾 Saving AR Marker:
   Marker ID: 9C022FCC-646B-4004-AD96-860A40D0E386
   Linked Map Point: CD8E90BB-C16C-42FF-8873-6BE745A672B1
   AR Position: (14.95, -1.22, 2.96) meters
   Map Coordinates: (4191.0, 4227.7) pixels
📍 Saved marker 9C022FCC-646B-4004-AD96-860A40D0E386 (MapPoint: CD8E90BB-C16C-42FF-8873-6BE745A672B1)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: CD8E90BB
   markerID: 9C022FCC
🔍 [ADD_MARKER_TRACE] Triangle found at index 5:
   Triangle ID: 3E553D63
   Current arMarkerIDs: ["94C6F600-CC4A-4493-A85D-A50CBC3937F4", "", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: ''
   New value: '9C022FCC-646B-4004-AD96-860A40D0E386'
   Updated arMarkerIDs: ["94C6F600-CC4A-4493-A85D-A50CBC3937F4", "", "9C022FCC-646B-4004-AD96-860A40D0E386"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 9C022FCC to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint CD8E90BB (3/3)
⚠️ Cannot compute quality: Only found 1/3 AR markers
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
   Calibrated: true
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Marked triangle 3E553D63 as calibrated (quality: 0%)
🔍 Triangle 3E553D63 state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["94C6F600", "", "9C022FCC"]
🎉 ARCalibrationCoordinator: Triangle 3E553D63 calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 3E553D63
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 9C022FCC for vertex CD8E90BB
📍 getCurrentVertexID: returning vertex[0] = 86EB7B89
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🎯 PiP Map: Triangle complete - fitting all 3 vertices
ARWorldTrackingTechnique <0x15122f100>: World tracking performance is being affected by resource constraints [25]
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: 3E553D63
   Features: 5932
   Size: 33.4 MB
   Path: /var/mobile/Containers/Data/Application/211DA88E-EE25-44A2-B725-E9DA3ACA0424/Documents/locations/museum/ARSpatial/Strategies/worldmap/3E553D63-BEE5-4A16-A64B-36A6A9D753E1.armap
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
   Calibrated: true
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '3E553D63-BEE5-4A16-A64B-36A6A9D753E1.armap' for triangle 3E553D63
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
   Calibrated: true
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '3E553D63-BEE5-4A16-A64B-36A6A9D753E1.armap' for strategy 'ARWorldMap' on triangle 3E553D63
✅ Saved ARWorldMap for triangle 3E553D63
   Strategy: worldmap (ARWorldMap)
   Features: 5932
   Center: (4064, 4333)
   Radius: 4.33m
   Filename: 3E553D63-BEE5-4A16-A64B-36A6A9D753E1.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
📍 Plotting points within triangle A(3889.5, 4260.7) B(4113.7, 4511.7) C(4191.0, 4227.7)
✅ Found AR marker 94C6F600 for vertex 86EB7B89 at SIMD3<Float>(11.704596, -1.2546258, -2.287911)
✅ Found AR marker 265501BE for vertex A59BC2FB at SIMD3<Float>(9.025418, -1.2512589, 3.76404)
✅ Found AR marker 9C022FCC for vertex CD8E90BB at SIMD3<Float>(14.948316, -1.2175732, 2.9559722)
🌍 Planting Survey Markers within triangle A(11.70, -1.25, -2.29) B(9.03, -1.25, 3.76) C(14.95, -1.22, 2.96)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(4191.0, 4227.7) s2(4175.5, 4284.5) s3(4160.1, 4341.3) s4(4144.6, 4398.1) s5(4129.1, 4454.9) s6(4113.7, 4511.7) s7(4130.7, 4234.3) s8(4115.2, 4291.1) s9(4099.8, 4347.9) s10(4084.3, 4404.7) s11(4068.8, 4461.5) s12(4070.4, 4240.9) s13(4054.9, 4297.7) s14(4039.5, 4354.5) s15(4010.1, 4247.5) s16(3994.6, 4304.3) s17(3949.8, 4254.1) s18(3889.5, 4260.7) 
📍 Survey Marker placed at (14.95, -1.24, 2.96)
📍 Survey Marker placed at (14.95, -1.24, 2.96)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(14.95, -1.24, 2.96)
📍 Survey marker placed at map(4191.0, 4227.7) → AR(14.95, -1.24, 2.96)
📍 Survey Marker placed at (13.76, -1.24, 3.12)
📍 Survey Marker placed at (13.76, -1.24, 3.12)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(13.76, -1.24, 3.12)
📍 Survey marker placed at map(4175.5, 4284.5) → AR(13.76, -1.24, 3.12)
📍 Survey Marker placed at (12.58, -1.24, 3.28)
📍 Survey Marker placed at (12.58, -1.24, 3.28)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(12.58, -1.24, 3.28)
📍 Survey marker placed at map(4160.1, 4341.3) → AR(12.58, -1.24, 3.28)
📍 Survey Marker placed at (11.39, -1.24, 3.44)
📍 Survey Marker placed at (11.39, -1.24, 3.44)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(11.39, -1.24, 3.44)
📍 Survey marker placed at map(4144.6, 4398.1) → AR(11.39, -1.24, 3.44)
📍 Survey Marker placed at (10.21, -1.24, 3.60)
📍 Survey Marker placed at (10.21, -1.24, 3.60)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(10.21, -1.24, 3.60)
📍 Survey marker placed at map(4129.1, 4454.9) → AR(10.21, -1.24, 3.60)
📍 Survey Marker placed at (9.03, -1.24, 3.76)
📍 Survey Marker placed at (9.03, -1.24, 3.76)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(9.03, -1.24, 3.76)
📍 Survey marker placed at map(4113.7, 4511.7) → AR(9.03, -1.24, 3.76)
📍 Survey Marker placed at (14.30, -1.24, 1.91)
📍 Survey Marker placed at (14.30, -1.24, 1.91)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(14.30, -1.24, 1.91)
📍 Survey marker placed at map(4130.7, 4234.3) → AR(14.30, -1.24, 1.91)
📍 Survey Marker placed at (13.11, -1.24, 2.07)
📍 Survey Marker placed at (13.11, -1.24, 2.07)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(13.11, -1.24, 2.07)
📍 Survey marker placed at map(4115.2, 4291.1) → AR(13.11, -1.24, 2.07)
📍 Survey Marker placed at (11.93, -1.24, 2.23)
📍 Survey Marker placed at (11.93, -1.24, 2.23)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(11.93, -1.24, 2.23)
📍 Survey marker placed at map(4099.8, 4347.9) → AR(11.93, -1.24, 2.23)
📍 Survey Marker placed at (10.75, -1.24, 2.39)
📍 Survey Marker placed at (10.75, -1.24, 2.39)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(10.75, -1.24, 2.39)
📍 Survey marker placed at map(4084.3, 4404.7) → AR(10.75, -1.24, 2.39)
📍 Survey Marker placed at (9.56, -1.24, 2.55)
📍 Survey Marker placed at (9.56, -1.24, 2.55)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(9.56, -1.24, 2.55)
📍 Survey marker placed at map(4068.8, 4461.5) → AR(9.56, -1.24, 2.55)
📍 Survey Marker placed at (13.65, -1.24, 0.86)
📍 Survey Marker placed at (13.65, -1.24, 0.86)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(13.65, -1.24, 0.86)
📍 Survey marker placed at map(4070.4, 4240.9) → AR(13.65, -1.24, 0.86)
📍 Survey Marker placed at (12.47, -1.24, 1.02)
📍 Survey Marker placed at (12.47, -1.24, 1.02)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(12.47, -1.24, 1.02)
📍 Survey marker placed at map(4054.9, 4297.7) → AR(12.47, -1.24, 1.02)
📍 Survey Marker placed at (11.28, -1.24, 1.18)
📍 Survey Marker placed at (11.28, -1.24, 1.18)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(11.28, -1.24, 1.18)
📍 Survey marker placed at map(4039.5, 4354.5) → AR(11.28, -1.24, 1.18)
📍 Survey Marker placed at (13.00, -1.24, -0.19)
📍 Survey Marker placed at (13.00, -1.24, -0.19)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(13.00, -1.24, -0.19)
📍 Survey marker placed at map(4010.1, 4247.5) → AR(13.00, -1.24, -0.19)
📍 Survey Marker placed at (11.82, -1.24, -0.03)
📍 Survey Marker placed at (11.82, -1.24, -0.03)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(11.82, -1.24, -0.03)
📍 Survey marker placed at map(3994.6, 4304.3) → AR(11.82, -1.24, -0.03)
📍 Survey Marker placed at (12.35, -1.24, -1.24)
📍 Survey Marker placed at (12.35, -1.24, -1.24)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(12.35, -1.24, -1.24)
📍 Survey marker placed at map(3949.8, 4254.1) → AR(12.35, -1.24, -1.24)
📍 Survey Marker placed at (11.71, -1.24, -2.29)
📍 Survey Marker placed at (11.71, -1.24, -2.29)
📍 Placed survey marker at map(3889.5, 4260.7) → AR(11.71, -1.24, -2.29)
📍 Survey marker placed at map(3889.5, 4260.7) → AR(11.71, -1.24, -2.29)
📊 3D Survey Markers: s1(11.82, -1.24, -0.03) s2(14.95, -1.24, 2.96) s3(13.65, -1.24, 0.86) s4(9.56, -1.24, 2.55) s5(12.58, -1.24, 3.28) s6(11.39, -1.24, 3.44) s7(14.30, -1.24, 1.91) s8(11.93, -1.24, 2.23) s9(12.35, -1.24, -1.24) s10(12.47, -1.24, 1.02) s11(13.11, -1.24, 2.07) s12(10.21, -1.24, 3.60) s13(9.03, -1.24, 3.76) s14(10.75, -1.24, 2.39) s15(11.71, -1.24, -2.29) s16(13.00, -1.24, -0.19) s17(13.76, -1.24, 3.12) s18(11.28, -1.24, 1.18) 
✅ Placed 18 survey markers
🔍 [PIP_MAP] State changed: Survey Mode
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
🔵 Selected triangle via long-press: 149463A3-3B36-4F8B-9D92-6FAEEBD81804
🎯 Long-press detected - starting calibration for triangle: 149463A3-3B36-4F8B-9D92-6FAEEBD81804
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 149463A3
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 149463A3
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🧹 Cleared survey markers
ARSession <0x152b88c80>: ARSession is being deallocated without being paused. Please pause running sessions explicitly.
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: []
🧹 [CLEAR_MARKERS] Clearing markers for triangle 149463A3
   Before: []
   After: []
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
   Calibrated: true
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
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [CLEAR_MARKERS] Cleared and saved
   New arMarkerIDs: []
📍 Starting calibration with vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
📍 getCurrentVertexID: returning vertex[0] = E49BCB0F
🎯 Guiding user to Map Point (4386.3, 4377.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle 149463A3
📍 Calibration vertices set: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle 149463A3
🧪 ARView ID: triangle viewing mode for 149463A3
🧪 ARViewWithOverlays instance: 0x0000000160e3f480
🔺 Entering triangle calibration mode for triangle: 149463A3-3B36-4F8B-9D92-6FAEEBD81804
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex E49BCB0F
📍 PiP Map: Displaying focused point E49BCB0F at (4386, 4377)
MapCanvas mapTransform: ObjectIdentifier(0x0000000150031b00) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.44s (debugger attached, not reporting)
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 6994FCA6 at AR(15.26, -1.19, -1.28) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 6994FCA6
   currentVertexID: E49BCB0F
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: E49BCB0F
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: E49BCB0F.jpg (993 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint E49BCB0F
🔗 AR Marker planted at AR(15.26, -1.19, -1.28) meters for Map Point (4386.3, 4377.7) pixels
📍 registerMarker called for MapPoint E49BCB0F
🖼 Photo 'E49BCB0F.jpg' linked to MapPoint E49BCB0F
💾 Saving AR Marker:
   Marker ID: 6994FCA6-F446-4559-B8F3-C89DD90E71D2
   Linked Map Point: E49BCB0F-8AC4-4B11-AE2A-F88FCCD61F03
   AR Position: (15.26, -1.19, -1.28) meters
   Map Coordinates: (4386.3, 4377.7) pixels
📍 Saved marker 6994FCA6-F446-4559-B8F3-C89DD90E71D2 (MapPoint: E49BCB0F-8AC4-4B11-AE2A-F88FCCD61F03)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: E49BCB0F
   markerID: 6994FCA6
🔍 [ADD_MARKER_TRACE] Triangle found at index 7:
   Triangle ID: 149463A3
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: '6994FCA6-F446-4559-B8F3-C89DD90E71D2'
   Updated arMarkerIDs: ["6994FCA6-F446-4559-B8F3-C89DD90E71D2", "", ""]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "9C022FCC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 6994FCA6 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=CD8E90BB
🎯 Guiding user to Map Point (4191.0, 4227.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint E49BCB0F (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 6994FCA6 for vertex E49BCB0F
📍 getCurrentVertexID: returning vertex[1] = CD8E90BB
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 283296F2 at AR(13.60, -1.16, -5.89) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 283296F2
   currentVertexID: CD8E90BB
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: CD8E90BB
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: CD8E90BB.jpg (822 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint CD8E90BB
🔗 AR Marker planted at AR(13.60, -1.16, -5.89) meters for Map Point (4191.0, 4227.7) pixels
📍 registerMarker called for MapPoint CD8E90BB
🖼 Photo 'CD8E90BB.jpg' linked to MapPoint CD8E90BB
💾 Saving AR Marker:
   Marker ID: 283296F2-D7F4-40AF-8650-641EB8A5E18E
   Linked Map Point: CD8E90BB-C16C-42FF-8873-6BE745A672B1
   AR Position: (13.60, -1.16, -5.89) meters
   Map Coordinates: (4191.0, 4227.7) pixels
📍 Saved marker 283296F2-D7F4-40AF-8650-641EB8A5E18E (MapPoint: CD8E90BB-C16C-42FF-8873-6BE745A672B1)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: CD8E90BB
   markerID: 283296F2
🔍 [ADD_MARKER_TRACE] Triangle found at index 5:
   Triangle ID: 3E553D63
   Current arMarkerIDs: ["94C6F600-CC4A-4493-A85D-A50CBC3937F4", "", "9C022FCC-646B-4004-AD96-860A40D0E386"]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: '9C022FCC-646B-4004-AD96-860A40D0E386'
   New value: '283296F2-D7F4-40AF-8650-641EB8A5E18E'
   Updated arMarkerIDs: ["94C6F600-CC4A-4493-A85D-A50CBC3937F4", "", "283296F2-D7F4-40AF-8650-641EB8A5E18E"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "265501BE"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "283296F2"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 283296F2 to triangle vertex 2
📍 Advanced to next vertex: index=2, vertexID=A59BC2FB
🎯 Guiding user to Map Point (4113.7, 4511.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint CD8E90BB (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 283296F2 for vertex CD8E90BB
📍 getCurrentVertexID: returning vertex[2] = A59BC2FB
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 0289831B at AR(9.10, -1.19, -2.02) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000105290d14 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 0289831B
   currentVertexID: A59BC2FB
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: A59BC2FB
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: A59BC2FB.jpg (1095 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F004F8ED...
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
🔗 AR Marker planted at AR(9.10, -1.19, -2.02) meters for Map Point (4113.7, 4511.7) pixels
📍 registerMarker called for MapPoint A59BC2FB
🖼 Photo 'A59BC2FB.jpg' linked to MapPoint A59BC2FB
💾 Saving AR Marker:
   Marker ID: 0289831B-9A08-4EE3-A9B2-A57802A09F24
   Linked Map Point: A59BC2FB-81A9-45C7-BD94-0172065DB685
   AR Position: (9.10, -1.19, -2.02) meters
   Map Coordinates: (4113.7, 4511.7) pixels
📍 Saved marker 0289831B-9A08-4EE3-A9B2-A57802A09F24 (MapPoint: A59BC2FB-81A9-45C7-BD94-0172065DB685)
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   mapPointID: A59BC2FB
   markerID: 0289831B
🔍 [ADD_MARKER_TRACE] Triangle found at index 3:
   Triangle ID: 1F066815
   Current arMarkerIDs: ["", "", "265501BE-8153-4FC7-88FF-CE1A9E51CE4A"]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: '265501BE-8153-4FC7-88FF-CE1A9E51CE4A'
   New value: '0289831B-9A08-4EE3-A9B2-A57802A09F24'
   Updated arMarkerIDs: ["", "", "0289831B-9A08-4EE3-A9B2-A57802A09F24"]
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "0289831B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "283296F2"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 0289831B to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint A59BC2FB (3/3)
⚠️ Cannot compute quality: Only found 1/3 AR markers
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "0289831B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "283296F2"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Marked triangle 149463A3 as calibrated (quality: 0%)
🔍 Triangle 149463A3 state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["6994FCA6", "", ""]
🎉 ARCalibrationCoordinator: Triangle 149463A3 calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 149463A3
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 0289831B for vertex A59BC2FB
📍 getCurrentVertexID: returning vertex[0] = E49BCB0F
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🎯 PiP Map: Triangle complete - fitting all 3 vertices
ARSession <0x152b8b200>: The delegate of ARSession is retaining 11 ARFrames. The camera will stop delivering camera images if the delegate keeps holding on to too many ARFrames. This could be a threading or memory management issue in the delegate and should be fixed.
ARSession <0x152b8b200>: The delegate of ARSession is retaining 12 ARFrames. The camera will stop delivering camera images if the delegate keeps holding on to too many ARFrames. This could be a threading or memory management issue in the delegate and should be fixed.
ARSession <0x152b8b200>: The delegate of ARSession is retaining 13 ARFrames. The camera will stop delivering camera images if the delegate keeps holding on to too many ARFrames. This could be a threading or memory management issue in the delegate and should be fixed.
ARWorldTrackingTechnique <0x15122ed80>: World tracking performance is being affected by resource constraints [25]
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: 149463A3
   Features: 6708
   Size: 44.4 MB
   Path: /var/mobile/Containers/Data/Application/211DA88E-EE25-44A2-B725-E9DA3ACA0424/Documents/locations/museum/ARSpatial/Strategies/worldmap/149463A3-3B36-4F8B-9D92-6FAEEBD81804.armap
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "0289831B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "283296F2"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '149463A3-3B36-4F8B-9D92-6FAEEBD81804.armap' for triangle 149463A3
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["CBBF699F", "9433C158", "FDED30E3"]
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
   AR Markers: ["", "", "0289831B"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: ["0DE6B904"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 3E553D63:
   Vertices: ["86EB7B89", "A59BC2FB", "CD8E90BB"]
   AR Markers: ["94C6F600", "", "283296F2"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D3AAD5D9:
   Vertices: ["B9714AA0", "86EB7B89", "A59BC2FB"]
   AR Markers: []
   Calibrated: true
   Quality: 0%
💾 Saving Triangle 149463A3:
   Vertices: ["E49BCB0F", "CD8E90BB", "A59BC2FB"]
   AR Markers: ["6994FCA6", "", ""]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle D9F3EC97:
   Vertices: ["F8FF09C8", "6AEC0243", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle BFEEA42A:
   Vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
   AR Markers: ["687114F4", "", ""]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '149463A3-3B36-4F8B-9D92-6FAEEBD81804.armap' for strategy 'ARWorldMap' on triangle 149463A3
✅ Saved ARWorldMap for triangle 149463A3
   Strategy: worldmap (ARWorldMap)
   Features: 6708
   Center: (4230, 4372)
   Radius: 4.15m
   Filename: 149463A3-3B36-4F8B-9D92-6FAEEBD81804.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
📍 Plotting points within triangle A(4386.3, 4377.7) B(4191.0, 4227.7) C(4113.7, 4511.7)
✅ Found AR marker 6994FCA6 for vertex E49BCB0F at SIMD3<Float>(15.260416, -1.1889365, -1.2817373)
✅ Found AR marker 9C022FCC for vertex CD8E90BB at SIMD3<Float>(14.948316, -1.2175732, 2.9559722)
✅ Found AR marker 265501BE for vertex A59BC2FB at SIMD3<Float>(9.025418, -1.2512589, 3.76404)
🌍 Planting Survey Markers within triangle A(15.26, -1.19, -1.28) B(14.95, -1.22, 2.96) C(9.03, -1.25, 3.76)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(4113.7, 4511.7) s2(4129.1, 4454.9) s3(4144.6, 4398.1) s4(4160.1, 4341.3) s5(4175.5, 4284.5) s6(4191.0, 4227.7) s7(4168.2, 4484.9) s8(4183.7, 4428.1) s9(4199.1, 4371.3) s10(4214.6, 4314.5) s11(4230.1, 4257.7) s12(4222.7, 4458.1) s13(4238.2, 4401.3) s14(4253.7, 4344.5) s15(4277.3, 4431.3) s16(4292.7, 4374.5) s17(4331.8, 4404.5) s18(4386.3, 4377.7) 
📍 Survey Marker placed at (9.03, -1.22, 3.76)
📍 Survey Marker placed at (9.03, -1.22, 3.76)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(9.03, -1.22, 3.76)
📍 Survey marker placed at map(4113.7, 4511.7) → AR(9.03, -1.22, 3.76)
📍 Survey Marker placed at (10.21, -1.22, 3.60)
📍 Survey Marker placed at (10.21, -1.22, 3.60)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(10.21, -1.22, 3.60)
📍 Survey marker placed at map(4129.1, 4454.9) → AR(10.21, -1.22, 3.60)
📍 Survey Marker placed at (11.39, -1.22, 3.44)
📍 Survey Marker placed at (11.39, -1.22, 3.44)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(11.39, -1.22, 3.44)
📍 Survey marker placed at map(4144.6, 4398.1) → AR(11.39, -1.22, 3.44)
📍 Survey Marker placed at (12.58, -1.22, 3.28)
📍 Survey Marker placed at (12.58, -1.22, 3.28)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(12.58, -1.22, 3.28)
📍 Survey marker placed at map(4160.1, 4341.3) → AR(12.58, -1.22, 3.28)
📍 Survey Marker placed at (13.76, -1.22, 3.12)
📍 Survey Marker placed at (13.76, -1.22, 3.12)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(13.76, -1.22, 3.12)
📍 Survey marker placed at map(4175.5, 4284.5) → AR(13.76, -1.22, 3.12)
📍 Survey Marker placed at (14.95, -1.22, 2.96)
📍 Survey Marker placed at (14.95, -1.22, 2.96)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(14.95, -1.22, 2.96)
📍 Survey marker placed at map(4191.0, 4227.7) → AR(14.95, -1.22, 2.96)
📍 Survey Marker placed at (10.27, -1.22, 2.76)
📍 Survey Marker placed at (10.27, -1.22, 2.76)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(10.27, -1.22, 2.76)
📍 Survey marker placed at map(4168.2, 4484.9) → AR(10.27, -1.22, 2.76)
📍 Survey Marker placed at (11.46, -1.22, 2.59)
📍 Survey Marker placed at (11.46, -1.22, 2.59)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(11.46, -1.22, 2.59)
📍 Survey marker placed at map(4183.7, 4428.1) → AR(11.46, -1.22, 2.59)
📍 Survey Marker placed at (12.64, -1.22, 2.43)
📍 Survey Marker placed at (12.64, -1.22, 2.43)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(12.64, -1.22, 2.43)
📍 Survey marker placed at map(4199.1, 4371.3) → AR(12.64, -1.22, 2.43)
📍 Survey Marker placed at (13.83, -1.22, 2.27)
📍 Survey Marker placed at (13.83, -1.22, 2.27)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(13.83, -1.22, 2.27)
📍 Survey marker placed at map(4214.6, 4314.5) → AR(13.83, -1.22, 2.27)
📍 Survey Marker placed at (15.01, -1.22, 2.11)
📍 Survey Marker placed at (15.01, -1.22, 2.11)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(15.01, -1.22, 2.11)
📍 Survey marker placed at map(4230.1, 4257.7) → AR(15.01, -1.22, 2.11)
📍 Survey Marker placed at (11.52, -1.22, 1.75)
📍 Survey Marker placed at (11.52, -1.22, 1.75)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(11.52, -1.22, 1.75)
📍 Survey marker placed at map(4222.7, 4458.1) → AR(11.52, -1.22, 1.75)
📍 Survey Marker placed at (12.70, -1.22, 1.58)
📍 Survey Marker placed at (12.70, -1.22, 1.58)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(12.70, -1.22, 1.58)
📍 Survey marker placed at map(4238.2, 4401.3) → AR(12.70, -1.22, 1.58)
📍 Survey Marker placed at (13.89, -1.22, 1.42)
📍 Survey Marker placed at (13.89, -1.22, 1.42)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(13.89, -1.22, 1.42)
📍 Survey marker placed at map(4253.7, 4344.5) → AR(13.89, -1.22, 1.42)
📍 Survey Marker placed at (12.77, -1.22, 0.74)
📍 Survey Marker placed at (12.77, -1.22, 0.74)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(12.77, -1.22, 0.74)
📍 Survey marker placed at map(4277.3, 4431.3) → AR(12.77, -1.22, 0.74)
📍 Survey Marker placed at (13.95, -1.22, 0.58)
📍 Survey Marker placed at (13.95, -1.22, 0.58)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(13.95, -1.22, 0.58)
📍 Survey marker placed at map(4292.7, 4374.5) → AR(13.95, -1.22, 0.58)
📍 Survey Marker placed at (14.01, -1.22, -0.27)
📍 Survey Marker placed at (14.01, -1.22, -0.27)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(14.01, -1.22, -0.27)
📍 Survey marker placed at map(4331.8, 4404.5) → AR(14.01, -1.22, -0.27)
📍 Survey Marker placed at (15.26, -1.22, -1.28)
📍 Survey Marker placed at (15.26, -1.22, -1.28)
📍 Placed survey marker at map(4386.3, 4377.7) → AR(15.26, -1.22, -1.28)
📍 Survey marker placed at map(4386.3, 4377.7) → AR(15.26, -1.22, -1.28)
📊 3D Survey Markers: s1(15.26, -1.22, -1.28) s2(14.01, -1.22, -0.27) s3(9.03, -1.22, 3.76) s4(12.64, -1.22, 2.43) s5(15.01, -1.22, 2.11) s6(11.52, -1.22, 1.75) s7(11.46, -1.22, 2.59) s8(12.58, -1.22, 3.28) s9(13.95, -1.22, 0.58) s10(13.76, -1.22, 3.12) s11(13.83, -1.22, 2.27) s12(11.39, -1.22, 3.44) s13(10.21, -1.22, 3.60) s14(12.70, -1.22, 1.58) s15(14.95, -1.22, 2.96) s16(13.89, -1.22, 1.42) s17(10.27, -1.22, 2.76) s18(12.77, -1.22, 0.74) 
✅ Placed 18 survey markers
🔍 [PIP_MAP] State changed: Survey Mode
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
Execution of the command buffer was aborted due to an error during execution. Insufficient Permission (to submit GPU work from background) (00000006:kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted)