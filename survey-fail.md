🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 911F39A1...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: 79450154...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 911F39A1...
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
   [6] Data size: 16072 bytes (15.70 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"isLocked":true,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"isLocked":true,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"isLocked":true,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"x":1931.311207952279,"se...
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
   [SAVE-2] Instance ID: 911F39A1...
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
   [LOAD-2] Instance ID: 79450154...
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
   [6] Data size: 16072 bytes (15.70 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"isLocked":true,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"isLocked":true,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"isLocked":true,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"x":1931.311207952279,"se...
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
   [SAVE-2] Instance ID: 79450154...
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
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/2463B581-131F-4FDC-9AC9-DAB3B2BAB6C3/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/2463B581-131F-4FDC-9AC9-DAB3B2BAB6C3/Documents/locations/museum/dots.json
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
   [LOAD-2] Instance ID: 911F39A1...
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
   [6] Data size: 16072 bytes (15.70 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"createdDate":782847128.446136,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","roles":[],"isLocked":true,"sessions":[],"y":4197.66667175293,"x":3695.000015258789},{"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","roles":[],"isLocked":true,"sessions":[],"y":4358.594897588835,"x":2150.3345762176123},{"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","roles":[],"isLocked":true,"sessions":[],"y":4820.4774370841515,"x":4627.521824291598},{"x":1931.311207952279,"se...
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
   [SAVE-2] Instance ID: 911F39A1...
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
   [LOAD-2] Instance ID: 79450154...
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
   [6] Data size: 16072 bytes (15.70 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"sessions":[],"roles":[],"y":4197.66667175293,"x":3695.000015258789,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","createdDate":782847128.446136},{"roles":[],"x":2150.3345762176123,"sessions":[],"isLocked":true,"y":4358.594897588835,"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"roles":[],"x":4627.521824291598,"sessions":[],"isLocked":true,"y":4820.4774370841515,"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"roles":[],"x":1931.31120...
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
   [SAVE-2] Instance ID: 79450154...
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
Hang detected: 2.77s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 79450154...
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
   [6] Data size: 16072 bytes (15.70 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","y":4197.66667175293,"sessions":[],"createdDate":782847128.446136,"roles":[],"x":3695.000015258789},{"isLocked":true,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","y":4358.594897588835,"sessions":[],"createdDate":782228945,"roles":[],"x":2150.3345762176123},{"isLocked":true,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","y":4820.4774370841515,"sessions":[],"createdDate":782145975,"roles":[],"x":4627.521824291598},{"isLocked":true,"id":"E4C...
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
   [SAVE-2] Instance ID: 79450154...
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
MapCanvas mapTransform: ObjectIdentifier(0x0000000104417100) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.49s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.38s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.28s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.44s (debugger attached, not reporting)
================================================================================
🗑️ SOFT RESET - CLEARING CALIBRATION DATA
================================================================================
📍 Target Location: 'museum'

📊 Before reset:
   Calibrated triangles: 1
   Total AR markers: 9

🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x000000010528eb5c $s11TapResolver12HUDContainerV16performSoftResetyyF + 5564
   2   TapResolver.debug.dylib             0x000000010528d590 $s11TapResolver12HUDContainerV4bodyQrvg7SwiftUI9TupleViewVyAE6ButtonVyAE4TextVG_ALtGyXEfU13_yyScMYccfU0_ + 52
   3   SwiftUI                             0x00000001906510c0 43149985-7D90-345D-8C31-B764E66E9C4E + 10166464
   4   SwiftUI                             0x0000000190561294 43149985-7D90-345D-8C31-B764E66E9C4E + 9183892
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
✅ Cleared calibration data:
   - Set isCalibrated = false for all triangles
   - Cleared arMarkerIDs arrays
   - Reset calibrationQuality to 0.0
   - Cleared legMeasurements
   - Cleared ARWorldMap filenames
   - Cleared transform data
   - Cleared lastCalibratedAt
   - Cleared userPositionWhenCalibrated

✅ Preserved:
   - Triangle vertices (30 total)
   - Mesh connectivity
   - Triangle structure (10 triangles)

🗑️ Deleted ARWorldMap files at: /var/mobile/Containers/Data/Application/2463B581-131F-4FDC-9AC9-DAB3B2BAB6C3/Documents/locations/museum/ARSpatial

🛡️ Other locations UNTOUCHED:
   ✓ Location 'home' - VERIFIED INTACT
================================================================================
✅ Soft reset complete for location 'museum'
================================================================================
🔵 Selected triangle via long-press: 19A9999C-2028-4563-ACE1-802B97382008
🎯 Long-press detected - starting calibration for triangle: 19A9999C-2028-4563-ACE1-802B97382008
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 19A9999C
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 19A9999C
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🆕 New AR session started: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Session timestamp: 2025-11-17 22:12:45 +0000
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: []
🧹 [CLEAR_MARKERS] Clearing markers for triangle 19A9999C
   Before: []
   After: []
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe4c2c $s11TapResolver18TrianglePatchStoreC16_clearAllMarkers33_1038F30D4546FD018964946DBEC54D69LL3fory10Foundation4UUIDV_tF + 2008
   2   TapResolver.debug.dylib             0x0000000104fe42b0 $s11TapResolver18TrianglePatchStoreC15clearAllMarkers3fory10Foundation4UUIDV_tFyyXEfU_ + 68
   3   TapResolver.debug.dylib             0x0000000104fe4394 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x0000000104fe43ec $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
✅ [CLEAR_MARKERS] Cleared and saved
   New arMarkerIDs: []
📍 Starting calibration with vertices: ["B9714AA0", "58BA635B", "9E947C28"]
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🎯 Guiding user to Map Point (3593.3, 4584.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle 19A9999C
📍 Calibration vertices set: ["B9714AA0", "58BA635B", "9E947C28"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle 19A9999C
🧪 ARView ID: triangle viewing mode for 19A9999C
🧪 ARViewWithOverlays instance: 0x0000000117d9abc0
🔺 Entering triangle calibration mode for triangle: 19A9999C-2028-4563-ACE1-802B97382008
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex B9714AA0
📍 PiP Map: Displaying focused point B9714AA0 at (3593, 4584)
MapCanvas mapTransform: ObjectIdentifier(0x0000000114555080) mapSize: (0.0, 0.0)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
App is being debugged, do not track this hang
Hang detected: 0.43s (debugger attached, not reporting)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
warning: using linearization / solving fallback.
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 4B20C9B3 at AR(0.02, -1.07, -6.61) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000104f2f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 4B20C9B3
   currentVertexID: B9714AA0
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: B9714AA0
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: B9714AA0.jpg (1052 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 79450154...
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
🔗 AR Marker planted at AR(0.02, -1.07, -6.61) meters for Map Point (3593.3, 4584.7) pixels
📍 registerMarker called for MapPoint B9714AA0
🖼 Photo 'B9714AA0.jpg' linked to MapPoint B9714AA0
💾 Saving AR Marker:
   Marker ID: 4B20C9B3-B6CD-406C-8055-3E49F2659924
   Linked Map Point: B9714AA0-CC7A-42E0-8344-725A2F33F30C
   AR Position: (0.02, -1.07, -6.61) meters
   Map Coordinates: (3593.3, 4584.7) pixels
📍 Saved marker 4B20C9B3-B6CD-406C-8055-3E49F2659924 (MapPoint: B9714AA0-CC7A-42E0-8344-725A2F33F30C)
💾 Saving AR Marker with session context:
   Marker ID: 4B20C9B3-B6CD-406C-8055-3E49F2659924
   Session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Session Time: 2025-11-17 22:12:45 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: B9714AA0
   markerID: 4B20C9B3
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: '4B20C9B3-B6CD-406C-8055-3E49F2659924'
   Updated arMarkerIDs: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "", ""]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe7934 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x0000000104fe5410 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000104fe4394 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x0000000104fe43ec $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "", ""]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 4B20C9B3 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=58BA635B
🎯 Guiding user to Map Point (3691.9, 4799.2)
✅ ARCalibrationCoordinator: Registered marker for MapPoint B9714AA0 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 4B20C9B3 for vertex B9714AA0
📍 getCurrentVertexID: returning vertex[1] = 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker C40ACCFF at AR(-1.26, -1.08, -1.45) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000104f2f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: C40ACCFF
   currentVertexID: 58BA635B
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 58BA635B
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 58BA635B.jpg (873 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 79450154...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint 58BA635B
🔗 AR Marker planted at AR(-1.26, -1.08, -1.45) meters for Map Point (3691.9, 4799.2) pixels
📍 registerMarker called for MapPoint 58BA635B
🖼 Photo '58BA635B.jpg' linked to MapPoint 58BA635B
💾 Saving AR Marker:
   Marker ID: C40ACCFF-577A-446B-876B-C0A334002F46
   Linked Map Point: 58BA635B-D29D-481B-95F5-202A8A432D04
   AR Position: (-1.26, -1.08, -1.45) meters
   Map Coordinates: (3691.9, 4799.2) pixels
📍 Saved marker C40ACCFF-577A-446B-876B-C0A334002F46 (MapPoint: 58BA635B-D29D-481B-95F5-202A8A432D04)
💾 Saving AR Marker with session context:
   Marker ID: C40ACCFF-577A-446B-876B-C0A334002F46
   Session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Session Time: 2025-11-17 22:12:45 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: 58BA635B
   markerID: C40ACCFF
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 1
🔍 [ADD_MARKER_TRACE] Array ready, setting index 1
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[1]:
   Old value: ''
   New value: 'C40ACCFF-577A-446B-876B-C0A334002F46'
   Updated arMarkerIDs: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", ""]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe7934 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x0000000104fe5410 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000104fe4394 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x0000000104fe43ec $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "C40ACCFF", ""]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker C40ACCFF to triangle vertex 1
📍 Advanced to next vertex: index=2, vertexID=9E947C28
🎯 Guiding user to Map Point (3388.7, 4808.3)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 58BA635B (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker C40ACCFF for vertex 58BA635B
📍 getCurrentVertexID: returning vertex[2] = 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PIP_ONCHANGE] Calibration state changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 07E48899 at AR(-6.29, -1.09, -5.07) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x0000000104f2f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 07E48899
   currentVertexID: 9E947C28
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 9E947C28
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: 9E947C28.jpg (849 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: 79450154...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint 9E947C28
🔗 AR Marker planted at AR(-6.29, -1.09, -5.07) meters for Map Point (3388.7, 4808.3) pixels
📍 registerMarker called for MapPoint 9E947C28
🖼 Photo '9E947C28.jpg' linked to MapPoint 9E947C28
💾 Saving AR Marker:
   Marker ID: 07E48899-893D-447E-86B9-393778EC4441
   Linked Map Point: 9E947C28-E6BE-459F-A161-E3B00AA13B05
   AR Position: (-6.29, -1.09, -5.07) meters
   Map Coordinates: (3388.7, 4808.3) pixels
📍 Saved marker 07E48899-893D-447E-86B9-393778EC4441 (MapPoint: 9E947C28-E6BE-459F-A161-E3B00AA13B05)
💾 Saving AR Marker with session context:
   Marker ID: 07E48899-893D-447E-86B9-393778EC4441
   Session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Session Time: 2025-11-17 22:12:45 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: 9E947C28
   markerID: 07E48899
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: ''
   New value: '07E48899-893D-447E-86B9-393778EC4441'
   Updated arMarkerIDs: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe7934 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x0000000104fe5410 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000104fe4394 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x0000000104fe43ec $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "C40ACCFF", "07E48899"]
   Calibrated: false
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 07E48899 to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint 9E947C28 (3/3)
⚠️ Cannot compute quality: Only found 2/3 AR markers
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe8ad0 $s11TapResolver18TrianglePatchStoreC14markCalibrated_7qualityy10Foundation4UUIDV_SftF + 824
   2   TapResolver.debug.dylib             0x0000000104e35708 $s11TapResolver24ARCalibrationCoordinatorC19finalizeCalibration33_F64506FEE7F9EF4E533DE967F641E0F2LL3foryAA13TrianglePatchV_tF + 480
   3   TapResolver.debug.dylib             0x0000000104e33898 $s11TapResolver24ARCalibrationCoordinatorC14registerMarker10mapPointID6markery10Foundation4UUIDV_AA8ARMarkerVtF + 12548
   4   TapResolver.debug.dylib             0x0000000104f319bc $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 10388
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "C40ACCFF", "07E48899"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
✅ Marked triangle 19A9999C as calibrated (quality: 0%)
🔍 Triangle 19A9999C state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["4B20C9B3", "C40ACCFF", "07E48899"]
🎉 ARCalibrationCoordinator: Triangle 19A9999C calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 19A9999C
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 07E48899 for vertex 9E947C28
📍 getCurrentVertexID: returning vertex[0] = B9714AA0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
🔍 [PIP_ONCHANGE] Calibration state changed: Ready to Fill
🎯 [PIP_ONCHANGE] Triggering triangle frame calculation
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
✅ [PIP_ONCHANGE] Applied triangle framing transform
🎯 PiP Map: Triangle complete - fitting all 3 vertices
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4484)
   Corner B: (3791, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.472, offset: (262.3, -283.5)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: 19A9999C
   Features: 2549
   Size: 14.3 MB
   Path: /var/mobile/Containers/Data/Application/2463B581-131F-4FDC-9AC9-DAB3B2BAB6C3/Documents/locations/museum/ARSpatial/Strategies/worldmap/19A9999C-2028-4563-ACE1-802B97382008.armap
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fe9a44 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for8filenamey10Foundation4UUIDV_SStF + 428
   2   TapResolver.debug.dylib             0x0000000104e3a354 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3848
   3   TapResolver.debug.dylib             0x00000001050b1074 $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x00000001050b1120 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "C40ACCFF", "07E48899"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
✅ Set world map filename '19A9999C-2028-4563-ACE1-802B97382008.armap' for triangle 19A9999C
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x103959580>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["4B20C9B3-B6CD-406C-8055-3E49F2659924", "C40ACCFF-577A-446B-876B-C0A334002F46", "07E48899-893D-447E-86B9-393778EC4441"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x0000000104feb1c8 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000104fea1a8 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for12strategyName8filenamey10Foundation4UUIDV_S2StF + 512
   2   TapResolver.debug.dylib             0x0000000104e3a3e4 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3992
   3   TapResolver.debug.dylib             0x00000001050b1074 $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x00000001050b1120 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["4B20C9B3", "C40ACCFF", "07E48899"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle DBC91CD1:
   Vertices: ["58BA635B", "3E185BD1", "90EA7A4A"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 1F066815:
   Vertices: ["B9714AA0", "58BA635B", "A59BC2FB"]
   AR Markers: []
   Calibrated: false
   Quality: 0%
💾 Saving Triangle 6FC8415C:
   Vertices: ["F8FF09C8", "A59BC2FB", "58BA635B"]
   AR Markers: []
   Calibrated: false
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
✅ Set world map filename '19A9999C-2028-4563-ACE1-802B97382008.armap' for strategy 'ARWorldMap' on triangle 19A9999C
✅ Saved ARWorldMap for triangle 19A9999C
   Strategy: worldmap (ARWorldMap)
   Features: 2549
   Center: (3557, 4730)
   Radius: 4.25m
   Filename: 19A9999C-2028-4563-ACE1-802B97382008.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [PIP_MAP] State changed: Survey Mode
🔍 [PIP_ONCHANGE] Calibration state changed: Survey Mode
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Survey Mode
⚠️ Cannot enter survey mode - not in readyToFill state (current: Survey Mode)
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: ED7ACD2C-B27E-4781-9F32-F2BB8AEC0CA5
❌ [SURVEY_VALIDATION] Vertex[0] B9714AA0: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[1] 58BA635B: No marker ID in triangle
❌ [SURVEY_VALIDATION] Vertex[2] 9E947C28: No marker ID in triangle
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 0/3
   Other session markers: 0
❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch
   Markers from current session: 0/3
   Markers from other sessions: 0

🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session
   This ensures all markers use the same coordinate origin.

💡 FUTURE: When relocalization is implemented, you'll be able to:
   1. Place 2+ known markers to establish coordinate transformation
   2. System automatically transforms stored markers to current session
   3. Survey markers work across sessions