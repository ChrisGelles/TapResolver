🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 20FDB2EF...
📂 Loaded 16 triangle(s)
🧱 MapPointStore init — ID: F867F6CA...
📂 Loaded 16 triangle(s)
📍 ARWorldMapStore: Location changed → museum
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: 20FDB2EF...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"x":3695.000015258789,"createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"isLocked":true,"roles":[],"x":2150.3345762176123,"createdDate":782228945,"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"isLocked":true,"roles":[],"x":4627.521824291598,"createdDate":782145975,"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"y":4061.314009152402,"is...
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
   [SAVE-2] Instance ID: 20FDB2EF...
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
   [LOAD-2] Instance ID: F867F6CA...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"x":3695.000015258789,"createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"isLocked":true,"roles":[],"x":2150.3345762176123,"createdDate":782228945,"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"isLocked":true,"roles":[],"x":4627.521824291598,"createdDate":782145975,"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"y":4061.314009152402,"is...
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
   [SAVE-2] Instance ID: F867F6CA...
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
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/museum/dots.json
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
   [LOAD-2] Instance ID: 20FDB2EF...
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
   [8] Raw JSON preview (first 500 chars): [{"isLocked":true,"roles":[],"x":3695.000015258789,"createdDate":782847128.446136,"sessions":[],"y":4197.66667175293,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC"},{"isLocked":true,"roles":[],"x":2150.3345762176123,"createdDate":782228945,"sessions":[],"y":4358.594897588835,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7"},{"isLocked":true,"roles":[],"x":4627.521824291598,"createdDate":782145975,"sessions":[],"y":4820.4774370841515,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86"},{"y":4061.314009152402,"is...
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
   [SAVE-2] Instance ID: 20FDB2EF...
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
   [LOAD-2] Instance ID: F867F6CA...
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
   [8] Raw JSON preview (first 500 chars): [{"sessions":[],"roles":[],"x":3695.000015258789,"createdDate":782847128.446136,"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","y":4197.66667175293,"isLocked":true},{"sessions":[],"roles":[],"x":2150.3345762176123,"createdDate":782228945,"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","y":4358.594897588835,"isLocked":true},{"sessions":[],"roles":[],"x":4627.521824291598,"createdDate":782145975,"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","y":4820.4774370841515,"isLocked":true},{"sessions":[],"roles":[],...
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
   [SAVE-2] Instance ID: F867F6CA...
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
Hang detected: 3.18s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.31s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 68
✅ Loaded map image for 'museum' from Documents
🔄 MapPointStore: Starting reload for location 'museum'

================================================================================
🔄 DATA LOAD TRACE: MapPointStore.load()
================================================================================
   [LOAD-1] MapPointStore.load() CALLED
   [LOAD-2] Instance ID: F867F6CA...
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
   [8] Raw JSON preview (first 500 chars): [{"x":3695.000015258789,"roles":[],"y":4197.66667175293,"createdDate":782847128.446136,"sessions":[],"id":"E325D867-4288-47AA-BEFF-F825A9D799FC","isLocked":true},{"x":2150.3345762176123,"roles":[],"y":4358.594897588835,"createdDate":782228945,"sessions":[],"id":"F5DE687B-E9B5-4EC6-8C3C-673F4B4295C7","isLocked":true},{"x":4627.521824291598,"roles":[],"y":4820.4774370841515,"createdDate":782145975,"sessions":[],"id":"D8BF400C-D1E5-4DB8-9DBD-450E3A215C86","isLocked":true},{"x":1931.311207952279,"ro...
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
   [SAVE-2] Instance ID: F867F6CA...
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
MapCanvas mapTransform: ObjectIdentifier(0x0000000105d05180) mapSize: (0.0, 0.0)
App is being debugged, do not track this hang
Hang detected: 0.41s (debugger attached, not reporting)
================================================================================
🗑️ SOFT RESET - CLEARING CALIBRATION DATA
================================================================================
📍 Target Location: 'museum'

📊 Before reset:
   Calibrated triangles: 1
   Total AR markers: 3

🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106be3390 $s11TapResolver12HUDContainerV16performSoftResetyyF + 5564
   2   TapResolver.debug.dylib             0x0000000106be1dc4 $s11TapResolver12HUDContainerV4bodyQrvg7SwiftUI9TupleViewVyAE6ButtonVyAE4TextVG_ALtGyXEfU13_yyScMYccfU0_ + 52
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

🗑️ Deleted ARWorldMap files at: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/museum/ARSpatial

🛡️ Other locations UNTOUCHED:
   ✓ Location 'home' - VERIFIED INTACT
================================================================================
✅ Soft reset complete for location 'museum'
================================================================================
🔵 Selected triangle via long-press: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E
🎯 Long-press detected - starting calibration for triangle: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: BFEEA42A
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle BFEEA42A
🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: BFEEA42A
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🆕 New AR session started: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Session timestamp: 2025-11-17 22:26:31 +0000
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: []
🧹 [CLEAR_MARKERS] Clearing markers for triangle BFEEA42A
   Before: []
   After: []
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106934ddc $s11TapResolver18TrianglePatchStoreC16_clearAllMarkers33_1038F30D4546FD018964946DBEC54D69LL3fory10Foundation4UUIDV_tF + 2008
   2   TapResolver.debug.dylib             0x0000000106934460 $s11TapResolver18TrianglePatchStoreC15clearAllMarkers3fory10Foundation4UUIDV_tFyyXEfU_ + 68
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
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
📍 Starting calibration with vertices: ["CCFF518E", "9E947C28", "B9714AA0"]
📍 getCurrentVertexID: returning vertex[0] = CCFF518E
🎯 Guiding user to Map Point (3292.4, 4580.7)
🎯 ARCalibrationCoordinator: Starting calibration for triangle BFEEA42A
📍 Calibration vertices set: ["CCFF518E", "9E947C28", "B9714AA0"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle BFEEA42A
🧪 ARView ID: triangle viewing mode for BFEEA42A
🧪 ARViewWithOverlays instance: 0x000000012dd4da40
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
🔺 Entering triangle calibration mode for triangle: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex CCFF518E
📍 PiP Map: Displaying focused point CCFF518E at (3292, 4580)
MapCanvas mapTransform: ObjectIdentifier(0x000000010ab8c000) mapSize: (0.0, 0.0)
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
App is being debugged, do not track this hang
Hang detected: 0.52s (debugger attached, not reporting)
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
🔍 [FOCUSED_POINT] placingVertices state - focusing on CCFF518E
warning: using linearization / solving fallback.
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker CD8098C5 at AR(2.32, -1.15, -11.06) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: CD8098C5
   currentVertexID: CCFF518E
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: CCFF518E
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: CCFF518E.jpg (1110 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint CCFF518E
🔗 AR Marker planted at AR(2.32, -1.15, -11.06) meters for Map Point (3292.4, 4580.7) pixels
📍 registerMarker called for MapPoint CCFF518E
🖼 Photo 'CCFF518E.jpg' linked to MapPoint CCFF518E
💾 Saving AR Marker:
   Marker ID: CD8098C5-B94A-4139-AA5D-C33A85373253
   Linked Map Point: CCFF518E-D066-498A-927E-F54F12C51AB7
   AR Position: (2.32, -1.15, -11.06) meters
   Map Coordinates: (3292.4, 4580.7) pixels
📍 Saved marker CD8098C5-B94A-4139-AA5D-C33A85373253 (MapPoint: CCFF518E-D066-498A-927E-F54F12C51AB7)
💾 Saving AR Marker with session context:
   Marker ID: CD8098C5-B94A-4139-AA5D-C33A85373253
   Session ID: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Session Time: 2025-11-17 22:26:31 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: BFEEA42A
   vertexMapPointID: CCFF518E
   markerID: CD8098C5
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: BFEEA42A
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: 'CD8098C5-B94A-4139-AA5D-C33A85373253'
   Updated arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
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
   AR Markers: ["CD8098C5", "", ""]
   Calibrated: false
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker CD8098C5 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=9E947C28
🎯 Guiding user to Map Point (3388.7, 4808.3)
✅ ARCalibrationCoordinator: Registered marker for MapPoint CCFF518E (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker CD8098C5 for vertex CCFF518E
📍 getCurrentVertexID: returning vertex[1] = 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 6FDE5941 at AR(-2.32, -1.17, -7.59) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 6FDE5941
   currentVertexID: 9E947C28
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 9E947C28
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 9E947C28.jpg (815 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(-2.32, -1.17, -7.59) meters for Map Point (3388.7, 4808.3) pixels
📍 registerMarker called for MapPoint 9E947C28
🖼 Photo '9E947C28.jpg' linked to MapPoint 9E947C28
💾 Saving AR Marker:
   Marker ID: 6FDE5941-BAB5-4114-B2AB-3CA21FA985E4
   Linked Map Point: 9E947C28-E6BE-459F-A161-E3B00AA13B05
   AR Position: (-2.32, -1.17, -7.59) meters
   Map Coordinates: (3388.7, 4808.3) pixels
📍 Saved marker 6FDE5941-BAB5-4114-B2AB-3CA21FA985E4 (MapPoint: 9E947C28-E6BE-459F-A161-E3B00AA13B05)
💾 Saving AR Marker with session context:
   Marker ID: 6FDE5941-BAB5-4114-B2AB-3CA21FA985E4
   Session ID: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Session Time: 2025-11-17 22:26:31 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: BFEEA42A
   vertexMapPointID: 9E947C28
   markerID: 6FDE5941
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: BFEEA42A
   Current arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 1
🔍 [ADD_MARKER_TRACE] Array ready, setting index 1
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[1]:
   Old value: ''
   New value: '6FDE5941-BAB5-4114-B2AB-3CA21FA985E4'
   Updated arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
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
   AR Markers: ["CD8098C5", "6FDE5941", ""]
   Calibrated: false
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 6FDE5941 to triangle vertex 1
📍 Advanced to next vertex: index=2, vertexID=B9714AA0
🎯 Guiding user to Map Point (3593.3, 4584.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 9E947C28 (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 6FDE5941 for vertex 9E947C28
📍 getCurrentVertexID: returning vertex[2] = B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PIP_ONCHANGE] Calibration state changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 32B96469 at AR(3.94, -1.19, -5.39) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 32B96469
   currentVertexID: B9714AA0
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: B9714AA0
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: B9714AA0.jpg (1068 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(3.94, -1.19, -5.39) meters for Map Point (3593.3, 4584.7) pixels
📍 registerMarker called for MapPoint B9714AA0
🖼 Photo 'B9714AA0.jpg' linked to MapPoint B9714AA0
💾 Saving AR Marker:
   Marker ID: 32B96469-2A7A-4C7A-A844-95E936C6E37E
   Linked Map Point: B9714AA0-CC7A-42E0-8344-725A2F33F30C
   AR Position: (3.94, -1.19, -5.39) meters
   Map Coordinates: (3593.3, 4584.7) pixels
📍 Saved marker 32B96469-2A7A-4C7A-A844-95E936C6E37E (MapPoint: B9714AA0-CC7A-42E0-8344-725A2F33F30C)
💾 Saving AR Marker with session context:
   Marker ID: 32B96469-2A7A-4C7A-A844-95E936C6E37E
   Session ID: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Session Time: 2025-11-17 22:26:31 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: BFEEA42A
   vertexMapPointID: B9714AA0
   markerID: 32B96469
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: BFEEA42A
   Current arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: ''
   New value: '32B96469-2A7A-4C7A-A844-95E936C6E37E'
   Updated arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", "32B96469-2A7A-4C7A-A844-95E936C6E37E"]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", "32B96469-2A7A-4C7A-A844-95E936C6E37E"]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: false
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[9].arMarkerIDs = ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", "32B96469-2A7A-4C7A-A844-95E936C6E37E"]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 32B96469 to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint B9714AA0 (3/3)
⚠️ Cannot compute quality: Only found 2/3 AR markers
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106938c80 $s11TapResolver18TrianglePatchStoreC14markCalibrated_7qualityy10Foundation4UUIDV_SftF + 824
   2   TapResolver.debug.dylib             0x0000000106785708 $s11TapResolver24ARCalibrationCoordinatorC19finalizeCalibration33_F64506FEE7F9EF4E533DE967F641E0F2LL3foryAA13TrianglePatchV_tF + 480
   3   TapResolver.debug.dylib             0x0000000106783898 $s11TapResolver24ARCalibrationCoordinatorC14registerMarker10mapPointID6markery10Foundation4UUIDV_AA8ARMarkerVtF + 12548
   4   TapResolver.debug.dylib             0x00000001068819bc $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 10388
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Marked triangle BFEEA42A as calibrated (quality: 0%)
🔍 Triangle BFEEA42A state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["CD8098C5", "6FDE5941", "32B96469"]
🎉 ARCalibrationCoordinator: Triangle BFEEA42A calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for BFEEA42A
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 32B96469 for vertex B9714AA0
📍 getCurrentVertexID: returning vertex[0] = CCFF518E
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
🔍 [PIP_ONCHANGE] Calibration state changed: Ready to Fill
🎯 [PIP_ONCHANGE] Triggering triangle frame calculation
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
✅ [PIP_ONCHANGE] Applied triangle framing transform
🎯 PiP Map: Triangle complete - fitting all 3 vertices
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3192, 4480)
   Corner B: (3693, 4908)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.468, offset: (305.5, -279.9)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
ARSession <0x115fc4f00>: The delegate of ARSession is retaining 11 ARFrames. The camera will stop delivering camera images if the delegate keeps holding on to too many ARFrames. This could be a threading or memory management issue in the delegate and should be fixed.
ARWorldTrackingTechnique <0x10a9b6a00>: World tracking performance is being affected by resource constraints [25]
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: BFEEA42A
   Features: 5709
   Size: 31.9 MB
   Path: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/museum/ARSpatial/Strategies/worldmap/BFEEA42A-338B-4FA3-AD8B-E26D403AA28E.armap
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106939bf4 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for8filenamey10Foundation4UUIDV_SStF + 428
   2   TapResolver.debug.dylib             0x000000010678a354 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3848
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename 'BFEEA42A-338B-4FA3-AD8B-E26D403AA28E.armap' for triangle BFEEA42A
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x000000010693a358 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for12strategyName8filenamey10Foundation4UUIDV_S2StF + 512
   2   TapResolver.debug.dylib             0x000000010678a3e4 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3992
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename 'BFEEA42A-338B-4FA3-AD8B-E26D403AA28E.armap' for strategy 'ARWorldMap' on triangle BFEEA42A
✅ Saved ARWorldMap for triangle BFEEA42A
   Strategy: worldmap (ARWorldMap)
   Features: 5709
   Center: (3424, 4657)
   Radius: 4.19m
   Filename: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
✅ [FILL_TRIANGLE] Found triangle BFEEA42A
   arMarkerIDs: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", "32B96469-2A7A-4C7A-A844-95E936C6E37E"]
   vertexIDs: ["CCFF518E", "9E947C28", "B9714AA0"]
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Triangle ID: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E
🔍 [SURVEY_VALIDATION] Current session ID: EBC21C7A-A952-4089-AD7C-98D393FEC74B
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs count: 3
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs contents: ["CD8098C5-B94A-4139-AA5D-C33A85373253", "6FDE5941-BAB5-4114-B2AB-3CA21FA985E4", "32B96469-2A7A-4C7A-A844-95E936C6E37E"]
🔍 [SURVEY_VALIDATION] Triangle vertexIDs: ["CCFF518E", "9E947C28", "B9714AA0"]
🔍 [SURVEY_VALIDATION] Checking vertex[0] CCFF518E
   arMarkerIDs.count: 3
   arMarkerIDs[0]: 'CD8098C5-B94A-4139-AA5D-C33A85373253' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[0] CCFF518E: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[1] 9E947C28
   arMarkerIDs.count: 3
   arMarkerIDs[1]: '6FDE5941-BAB5-4114-B2AB-3CA21FA985E4' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[1] 9E947C28: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[2] B9714AA0
   arMarkerIDs.count: 3
   arMarkerIDs[2]: '32B96469-2A7A-4C7A-A844-95E936C6E37E' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[2] B9714AA0: Found in placedMarkers (current session)
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 3/3
   Other session markers: 0
   ✅ CCFF518E via placedMarkers
   ✅ 9E947C28 via placedMarkers
   ✅ B9714AA0 via placedMarkers
✅ [SURVEY_VALIDATION] All 3 vertices from current session - proceeding
📍 Plotting points within triangle A(3292.4, 4580.7) B(3388.7, 4808.3) C(3593.3, 4584.7)
🔍 [SURVEY_3D] Getting AR positions for triangle vertices
   Current session: EBC21C7A-A952-4089-AD7C-98D393FEC74B
   Triangle has 3 marker IDs
✅ [SURVEY_3D] Vertex[0] CCFF518E: current session (placedMarkers) at SIMD3<Float>(2.3188217, -1.1471441, -11.061274)
   Session: EBC21C7A
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[1] 9E947C28: current session (placedMarkers) at SIMD3<Float>(-2.3202524, -1.1654873, -7.5902925)
   Session: EBC21C7A
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[2] B9714AA0: current session (placedMarkers) at SIMD3<Float>(3.9400628, -1.1852455, -5.3927817)
   Session: EBC21C7A
   Source: current session (placedMarkers)
🔍 [SURVEY_3D] Collected 3/3 AR positions
✅ [SURVEY_3D] All markers from current session - safe to proceed
🌍 Planting Survey Markers within triangle A(2.32, -1.15, -11.06) B(-2.32, -1.17, -7.59) C(3.94, -1.19, -5.39)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(3593.3, 4584.7) s2(3552.3, 4629.4) s3(3511.4, 4674.1) s4(3470.5, 4718.9) s5(3429.6, 4763.6) s6(3388.7, 4808.3) s7(3533.1, 4583.9) s8(3492.2, 4628.6) s9(3451.3, 4673.3) s10(3410.3, 4718.1) s11(3369.4, 4762.8) s12(3472.9, 4583.1) s13(3432.0, 4627.8) s14(3391.1, 4672.5) s15(3412.8, 4582.3) s16(3371.8, 4627.0) s17(3352.6, 4581.5) s18(3292.4, 4580.7) 
📍 Survey Marker placed at (3.94, -1.17, -5.39)
📍 Survey Marker placed at (3.94, -1.17, -5.39)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(3.94, -1.17, -5.39)
📍 Survey marker placed at map(3593.3, 4584.7) → AR(3.94, -1.17, -5.39)
📍 Survey Marker placed at (2.69, -1.17, -5.83)
📍 Survey Marker placed at (2.69, -1.17, -5.83)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.69, -1.17, -5.83)
📍 Survey marker placed at map(3552.3, 4629.4) → AR(2.69, -1.17, -5.83)
📍 Survey Marker placed at (1.44, -1.17, -6.27)
📍 Survey Marker placed at (1.44, -1.17, -6.27)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(1.44, -1.17, -6.27)
📍 Survey marker placed at map(3511.4, 4674.1) → AR(1.44, -1.17, -6.27)
📍 Survey Marker placed at (0.18, -1.17, -6.71)
📍 Survey Marker placed at (0.18, -1.17, -6.71)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(0.18, -1.17, -6.71)
📍 Survey marker placed at map(3470.5, 4718.9) → AR(0.18, -1.17, -6.71)
📍 Survey Marker placed at (-1.07, -1.17, -7.15)
📍 Survey Marker placed at (-1.07, -1.17, -7.15)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(-1.07, -1.17, -7.15)
📍 Survey marker placed at map(3429.6, 4763.6) → AR(-1.07, -1.17, -7.15)
📍 Survey Marker placed at (-2.32, -1.17, -7.59)
📍 Survey Marker placed at (-2.32, -1.17, -7.59)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(-2.32, -1.17, -7.59)
📍 Survey marker placed at map(3388.7, 4808.3) → AR(-2.32, -1.17, -7.59)
📍 Survey Marker placed at (3.62, -1.17, -6.53)
📍 Survey Marker placed at (3.62, -1.17, -6.53)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(3.62, -1.17, -6.53)
📍 Survey marker placed at map(3533.1, 4583.9) → AR(3.62, -1.17, -6.53)
📍 Survey Marker placed at (2.36, -1.17, -6.97)
📍 Survey Marker placed at (2.36, -1.17, -6.97)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.36, -1.17, -6.97)
📍 Survey marker placed at map(3492.2, 4628.6) → AR(2.36, -1.17, -6.97)
📍 Survey Marker placed at (1.11, -1.17, -7.40)
📍 Survey Marker placed at (1.11, -1.17, -7.40)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(1.11, -1.17, -7.40)
📍 Survey marker placed at map(3451.3, 4673.3) → AR(1.11, -1.17, -7.40)
📍 Survey Marker placed at (-0.14, -1.17, -7.85)
📍 Survey Marker placed at (-0.14, -1.17, -7.85)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(-0.14, -1.17, -7.85)
📍 Survey marker placed at map(3410.3, 4718.1) → AR(-0.14, -1.17, -7.85)
📍 Survey Marker placed at (-1.39, -1.17, -8.28)
📍 Survey Marker placed at (-1.39, -1.17, -8.28)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(-1.39, -1.17, -8.28)
📍 Survey marker placed at map(3369.4, 4762.8) → AR(-1.39, -1.17, -8.28)
📍 Survey Marker placed at (3.29, -1.17, -7.66)
📍 Survey Marker placed at (3.29, -1.17, -7.66)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(3.29, -1.17, -7.66)
📍 Survey marker placed at map(3472.9, 4583.1) → AR(3.29, -1.17, -7.66)
📍 Survey Marker placed at (2.04, -1.17, -8.10)
📍 Survey Marker placed at (2.04, -1.17, -8.10)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.04, -1.17, -8.10)
📍 Survey marker placed at map(3432.0, 4627.8) → AR(2.04, -1.17, -8.10)
📍 Survey Marker placed at (0.79, -1.17, -8.54)
📍 Survey Marker placed at (0.79, -1.17, -8.54)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(0.79, -1.17, -8.54)
📍 Survey marker placed at map(3391.1, 4672.5) → AR(0.79, -1.17, -8.54)
📍 Survey Marker placed at (2.97, -1.17, -8.79)
📍 Survey Marker placed at (2.97, -1.17, -8.79)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.97, -1.17, -8.79)
📍 Survey marker placed at map(3412.8, 4582.3) → AR(2.97, -1.17, -8.79)
📍 Survey Marker placed at (1.72, -1.17, -9.23)
📍 Survey Marker placed at (1.72, -1.17, -9.23)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(1.72, -1.17, -9.23)
📍 Survey marker placed at map(3371.8, 4627.0) → AR(1.72, -1.17, -9.23)
📍 Survey Marker placed at (2.64, -1.17, -9.93)
📍 Survey Marker placed at (2.64, -1.17, -9.93)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.64, -1.17, -9.93)
📍 Survey marker placed at map(3352.6, 4581.5) → AR(2.64, -1.17, -9.93)
📍 Survey Marker placed at (2.32, -1.17, -11.06)
📍 Survey Marker placed at (2.32, -1.17, -11.06)
📍 Placed survey marker at map(3292.4, 4580.7) → AR(2.32, -1.17, -11.06)
📍 Survey marker placed at map(3292.4, 4580.7) → AR(2.32, -1.17, -11.06)
📊 3D Survey Markers: s1(3.29, -1.17, -7.66) s2(1.72, -1.17, -9.23) s3(-2.32, -1.17, -7.59) s4(2.04, -1.17, -8.10) s5(2.64, -1.17, -9.93) s6(3.62, -1.17, -6.53) s7(1.11, -1.17, -7.40) s8(-1.39, -1.17, -8.28) s9(-0.14, -1.17, -7.85) s10(1.44, -1.17, -6.27) s11(0.18, -1.17, -6.71) s12(2.36, -1.17, -6.97) s13(0.79, -1.17, -8.54) s14(2.69, -1.17, -5.83) s15(2.32, -1.17, -11.06) s16(3.94, -1.17, -5.39) s17(-1.07, -1.17, -7.15) s18(2.97, -1.17, -8.79) 
✅ Placed 18 survey markers
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [PIP_MAP] State changed: Survey Mode
🔍 [PIP_ONCHANGE] Calibration state changed: Survey Mode
🔍 [TAP_TRACE] Tap detected
   Current mode: triangleCalibration(triangleID: BFEEA42A-338B-4FA3-AD8B-E26D403AA28E)
👆 [TAP_TRACE] Tap ignored in triangle calibration mode — use Place Marker button
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
🔵 Selected triangle via long-press: 19A9999C-2028-4563-ACE1-802B97382008
🎯 Long-press detected - starting calibration for triangle: 19A9999C-2028-4563-ACE1-802B97382008
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 19A9999C
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 19A9999C
🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: 19A9999C
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🧹 Cleared survey markers
ARSession <0x115fc4f00>: ARSession is being deallocated without being paused. Please pause running sessions explicitly.
🆕 New AR session started: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Session timestamp: 2025-11-17 22:28:58 +0000
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: []
🧹 [CLEAR_MARKERS] Clearing markers for triangle 19A9999C
   Before: []
   After: []
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: []
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106934ddc $s11TapResolver18TrianglePatchStoreC16_clearAllMarkers33_1038F30D4546FD018964946DBEC54D69LL3fory10Foundation4UUIDV_tF + 2008
   2   TapResolver.debug.dylib             0x0000000106934460 $s11TapResolver18TrianglePatchStoreC15clearAllMarkers3fory10Foundation4UUIDV_tFyyXEfU_ + 68
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
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
🧪 ARViewWithOverlays instance: 0x000000012dd4e680
🔺 Entering triangle calibration mode for triangle: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex B9714AA0
📍 PiP Map: Displaying focused point B9714AA0 at (3593, 4584)
MapCanvas mapTransform: ObjectIdentifier(0x0000000115d89200) mapSize: (0.0, 0.0)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
App is being debugged, do not track this hang
Hang detected: 0.50s (debugger attached, not reporting)
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [FOCUSED_POINT] placingVertices state - focusing on B9714AA0
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 9042529A at AR(-0.80, -1.19, -3.84) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 9042529A
   currentVertexID: B9714AA0
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: B9714AA0
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: B9714AA0.jpg (1004 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(-0.80, -1.19, -3.84) meters for Map Point (3593.3, 4584.7) pixels
📍 registerMarker called for MapPoint B9714AA0
🖼 Photo 'B9714AA0.jpg' linked to MapPoint B9714AA0
💾 Saving AR Marker:
   Marker ID: 9042529A-436A-49B2-ADFB-B5DB4112E136
   Linked Map Point: B9714AA0-CC7A-42E0-8344-725A2F33F30C
   AR Position: (-0.80, -1.19, -3.84) meters
   Map Coordinates: (3593.3, 4584.7) pixels
📍 Saved marker 9042529A-436A-49B2-ADFB-B5DB4112E136 (MapPoint: B9714AA0-CC7A-42E0-8344-725A2F33F30C)
💾 Saving AR Marker with session context:
   Marker ID: 9042529A-436A-49B2-ADFB-B5DB4112E136
   Session ID: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Session Time: 2025-11-17 22:28:58 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: B9714AA0
   markerID: 9042529A
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: '9042529A-436A-49B2-ADFB-B5DB4112E136'
   Updated arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "", ""]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "", ""]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 9042529A to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=58BA635B
🎯 Guiding user to Map Point (3691.9, 4799.2)
✅ ARCalibrationCoordinator: Registered marker for MapPoint B9714AA0 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 9042529A for vertex B9714AA0
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
📍 Placed marker 08307331 at AR(-0.31, -1.19, 1.38) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 08307331
   currentVertexID: 58BA635B
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 58BA635B
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 58BA635B.jpg (741 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(-0.31, -1.19, 1.38) meters for Map Point (3691.9, 4799.2) pixels
📍 registerMarker called for MapPoint 58BA635B
🖼 Photo '58BA635B.jpg' linked to MapPoint 58BA635B
💾 Saving AR Marker:
   Marker ID: 08307331-4DCF-4966-A48B-BACBDDFB36A2
   Linked Map Point: 58BA635B-D29D-481B-95F5-202A8A432D04
   AR Position: (-0.31, -1.19, 1.38) meters
   Map Coordinates: (3691.9, 4799.2) pixels
📍 Saved marker 08307331-4DCF-4966-A48B-BACBDDFB36A2 (MapPoint: 58BA635B-D29D-481B-95F5-202A8A432D04)
💾 Saving AR Marker with session context:
   Marker ID: 08307331-4DCF-4966-A48B-BACBDDFB36A2
   Session ID: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Session Time: 2025-11-17 22:28:58 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: 58BA635B
   markerID: 08307331
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 1
🔍 [ADD_MARKER_TRACE] Array ready, setting index 1
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[1]:
   Old value: ''
   New value: '08307331-4DCF-4966-A48B-BACBDDFB36A2'
   Updated arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", ""]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", ""]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 08307331 to triangle vertex 1
📍 Advanced to next vertex: index=2, vertexID=9E947C28
🎯 Guiding user to Map Point (3388.7, 4808.3)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 58BA635B (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 08307331 for vertex 58BA635B
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
📍 Placed marker 42FE0EAC at AR(-6.40, -1.18, -0.50) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 42FE0EAC
   currentVertexID: 9E947C28
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 9E947C28
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: 9E947C28.jpg (774 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(-6.40, -1.18, -0.50) meters for Map Point (3388.7, 4808.3) pixels
📍 registerMarker called for MapPoint 9E947C28
🖼 Photo '9E947C28.jpg' linked to MapPoint 9E947C28
💾 Saving AR Marker:
   Marker ID: 42FE0EAC-DF82-42F3-94EB-DB5C179ABA45
   Linked Map Point: 9E947C28-E6BE-459F-A161-E3B00AA13B05
   AR Position: (-6.40, -1.18, -0.50) meters
   Map Coordinates: (3388.7, 4808.3) pixels
📍 Saved marker 42FE0EAC-DF82-42F3-94EB-DB5C179ABA45 (MapPoint: 9E947C28-E6BE-459F-A161-E3B00AA13B05)
💾 Saving AR Marker with session context:
   Marker ID: 42FE0EAC-DF82-42F3-94EB-DB5C179ABA45
   Session ID: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Session Time: 2025-11-17 22:28:58 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: 19A9999C
   vertexMapPointID: 9E947C28
   markerID: 42FE0EAC
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: 19A9999C
   Current arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: ''
   New value: '42FE0EAC-DF82-42F3-94EB-DB5C179ABA45'
   Updated arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[0].arMarkerIDs = ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 42FE0EAC to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint 9E947C28 (3/3)
⚠️ Cannot compute quality: Only found 2/3 AR markers
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106938c80 $s11TapResolver18TrianglePatchStoreC14markCalibrated_7qualityy10Foundation4UUIDV_SftF + 824
   2   TapResolver.debug.dylib             0x0000000106785708 $s11TapResolver24ARCalibrationCoordinatorC19finalizeCalibration33_F64506FEE7F9EF4E533DE967F641E0F2LL3foryAA13TrianglePatchV_tF + 480
   3   TapResolver.debug.dylib             0x0000000106783898 $s11TapResolver24ARCalibrationCoordinatorC14registerMarker10mapPointID6markery10Foundation4UUIDV_AA8ARMarkerVtF + 12548
   4   TapResolver.debug.dylib             0x00000001068819bc $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 10388
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Marked triangle 19A9999C as calibrated (quality: 0%)
🔍 Triangle 19A9999C state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["9042529A", "08307331", "42FE0EAC"]
🎉 ARCalibrationCoordinator: Triangle 19A9999C calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 19A9999C
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 42FE0EAC for vertex 9E947C28
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
   Features: 2917
   Size: 12.2 MB
   Path: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/museum/ARSpatial/Strategies/worldmap/19A9999C-2028-4563-ACE1-802B97382008.armap
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106939bf4 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for8filenamey10Foundation4UUIDV_SStF + 428
   2   TapResolver.debug.dylib             0x000000010678a354 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3848
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '19A9999C-2028-4563-ACE1-802B97382008.armap' for triangle 19A9999C
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x000000010693a358 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for12strategyName8filenamey10Foundation4UUIDV_S2StF + 512
   2   TapResolver.debug.dylib             0x000000010678a3e4 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3992
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename '19A9999C-2028-4563-ACE1-802B97382008.armap' for strategy 'ARWorldMap' on triangle 19A9999C
✅ Saved ARWorldMap for triangle 19A9999C
   Strategy: worldmap (ARWorldMap)
   Features: 2917
   Center: (3557, 4730)
   Radius: 4.25m
   Filename: 19A9999C-2028-4563-ACE1-802B97382008.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
✅ [FILL_TRIANGLE] Found triangle 19A9999C
   arMarkerIDs: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   vertexIDs: ["B9714AA0", "58BA635B", "9E947C28"]
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Triangle ID: 19A9999C-2028-4563-ACE1-802B97382008
🔍 [SURVEY_VALIDATION] Current session ID: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs count: 3
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs contents: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
🔍 [SURVEY_VALIDATION] Triangle vertexIDs: ["B9714AA0", "58BA635B", "9E947C28"]
🔍 [SURVEY_VALIDATION] Checking vertex[0] B9714AA0
   arMarkerIDs.count: 3
   arMarkerIDs[0]: '9042529A-436A-49B2-ADFB-B5DB4112E136' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[0] B9714AA0: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[1] 58BA635B
   arMarkerIDs.count: 3
   arMarkerIDs[1]: '08307331-4DCF-4966-A48B-BACBDDFB36A2' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[1] 58BA635B: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[2] 9E947C28
   arMarkerIDs.count: 3
   arMarkerIDs[2]: '42FE0EAC-DF82-42F3-94EB-DB5C179ABA45' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[2] 9E947C28: Found in placedMarkers (current session)
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 3/3
   Other session markers: 0
   ✅ B9714AA0 via placedMarkers
   ✅ 58BA635B via placedMarkers
   ✅ 9E947C28 via placedMarkers
✅ [SURVEY_VALIDATION] All 3 vertices from current session - proceeding
📍 Plotting points within triangle A(3593.3, 4584.7) B(3691.9, 4799.2) C(3388.7, 4808.3)
🔍 [SURVEY_3D] Getting AR positions for triangle vertices
   Current session: EEF1C6E4-0B3F-422D-B86A-6DC6BD615943
   Triangle has 3 marker IDs
✅ [SURVEY_3D] Vertex[0] B9714AA0: current session (placedMarkers) at SIMD3<Float>(-0.80095327, -1.1947615, -3.838865)
   Session: EEF1C6E4
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[1] 58BA635B: current session (placedMarkers) at SIMD3<Float>(-0.31435063, -1.1944585, 1.3812915)
   Session: EEF1C6E4
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[2] 9E947C28: current session (placedMarkers) at SIMD3<Float>(-6.4028068, -1.1775278, -0.5006798)
   Session: EEF1C6E4
   Source: current session (placedMarkers)
🔍 [SURVEY_3D] Collected 3/3 AR positions
✅ [SURVEY_3D] All markers from current session - safe to proceed
🌍 Planting Survey Markers within triangle A(-0.80, -1.19, -3.84) B(-0.31, -1.19, 1.38) C(-6.40, -1.18, -0.50)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(3388.7, 4808.3) s2(3449.3, 4806.5) s3(3510.0, 4804.7) s4(3570.6, 4802.9) s5(3631.3, 4801.0) s6(3691.9, 4799.2) s7(3429.6, 4763.6) s8(3490.2, 4761.8) s9(3550.9, 4759.9) s10(3611.5, 4758.1) s11(3672.2, 4756.3) s12(3470.5, 4718.9) s13(3531.2, 4717.0) s14(3591.8, 4715.2) s15(3511.4, 4674.1) s16(3572.1, 4672.3) s17(3552.3, 4629.4) s18(3593.3, 4584.7) 
📍 Survey Marker placed at (-6.40, -1.19, -0.50)
📍 Survey Marker placed at (-6.40, -1.19, -0.50)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-6.40, -1.19, -0.50)
📍 Survey marker placed at map(3388.7, 4808.3) → AR(-6.40, -1.19, -0.50)
📍 Survey Marker placed at (-5.19, -1.19, -0.12)
📍 Survey Marker placed at (-5.19, -1.19, -0.12)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-5.19, -1.19, -0.12)
📍 Survey marker placed at map(3449.3, 4806.5) → AR(-5.19, -1.19, -0.12)
📍 Survey Marker placed at (-3.97, -1.19, 0.25)
📍 Survey Marker placed at (-3.97, -1.19, 0.25)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-3.97, -1.19, 0.25)
📍 Survey marker placed at map(3510.0, 4804.7) → AR(-3.97, -1.19, 0.25)
📍 Survey Marker placed at (-2.75, -1.19, 0.63)
📍 Survey Marker placed at (-2.75, -1.19, 0.63)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-2.75, -1.19, 0.63)
📍 Survey marker placed at map(3570.6, 4802.9) → AR(-2.75, -1.19, 0.63)
📍 Survey Marker placed at (-1.53, -1.19, 1.00)
📍 Survey Marker placed at (-1.53, -1.19, 1.00)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.53, -1.19, 1.00)
📍 Survey marker placed at map(3631.3, 4801.0) → AR(-1.53, -1.19, 1.00)
📍 Survey Marker placed at (-0.31, -1.19, 1.38)
📍 Survey Marker placed at (-0.31, -1.19, 1.38)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-0.31, -1.19, 1.38)
📍 Survey marker placed at map(3691.9, 4799.2) → AR(-0.31, -1.19, 1.38)
📍 Survey Marker placed at (-5.28, -1.19, -1.17)
📍 Survey Marker placed at (-5.28, -1.19, -1.17)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-5.28, -1.19, -1.17)
📍 Survey marker placed at map(3429.6, 4763.6) → AR(-5.28, -1.19, -1.17)
📍 Survey Marker placed at (-4.07, -1.19, -0.79)
📍 Survey Marker placed at (-4.07, -1.19, -0.79)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-4.07, -1.19, -0.79)
📍 Survey marker placed at map(3490.2, 4761.8) → AR(-4.07, -1.19, -0.79)
📍 Survey Marker placed at (-2.85, -1.19, -0.42)
📍 Survey Marker placed at (-2.85, -1.19, -0.42)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-2.85, -1.19, -0.42)
📍 Survey marker placed at map(3550.9, 4759.9) → AR(-2.85, -1.19, -0.42)
📍 Survey Marker placed at (-1.63, -1.19, -0.04)
📍 Survey Marker placed at (-1.63, -1.19, -0.04)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.63, -1.19, -0.04)
📍 Survey marker placed at map(3611.5, 4758.1) → AR(-1.63, -1.19, -0.04)
📍 Survey Marker placed at (-0.41, -1.19, 0.34)
📍 Survey Marker placed at (-0.41, -1.19, 0.34)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-0.41, -1.19, 0.34)
📍 Survey marker placed at map(3672.2, 4756.3) → AR(-0.41, -1.19, 0.34)
📍 Survey Marker placed at (-4.16, -1.19, -1.84)
📍 Survey Marker placed at (-4.16, -1.19, -1.84)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-4.16, -1.19, -1.84)
📍 Survey marker placed at map(3470.5, 4718.9) → AR(-4.16, -1.19, -1.84)
📍 Survey Marker placed at (-2.94, -1.19, -1.46)
📍 Survey Marker placed at (-2.94, -1.19, -1.46)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-2.94, -1.19, -1.46)
📍 Survey marker placed at map(3531.2, 4717.0) → AR(-2.94, -1.19, -1.46)
📍 Survey Marker placed at (-1.73, -1.19, -1.08)
📍 Survey Marker placed at (-1.73, -1.19, -1.08)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.73, -1.19, -1.08)
📍 Survey marker placed at map(3591.8, 4715.2) → AR(-1.73, -1.19, -1.08)
📍 Survey Marker placed at (-3.04, -1.19, -2.50)
📍 Survey Marker placed at (-3.04, -1.19, -2.50)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-3.04, -1.19, -2.50)
📍 Survey marker placed at map(3511.4, 4674.1) → AR(-3.04, -1.19, -2.50)
📍 Survey Marker placed at (-1.82, -1.19, -2.13)
📍 Survey Marker placed at (-1.82, -1.19, -2.13)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.82, -1.19, -2.13)
📍 Survey marker placed at map(3572.1, 4672.3) → AR(-1.82, -1.19, -2.13)
📍 Survey Marker placed at (-1.92, -1.19, -3.17)
📍 Survey Marker placed at (-1.92, -1.19, -3.17)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-1.92, -1.19, -3.17)
📍 Survey marker placed at map(3552.3, 4629.4) → AR(-1.92, -1.19, -3.17)
📍 Survey Marker placed at (-0.80, -1.19, -3.84)
📍 Survey Marker placed at (-0.80, -1.19, -3.84)
📍 Placed survey marker at map(3593.3, 4584.7) → AR(-0.80, -1.19, -3.84)
📍 Survey marker placed at map(3593.3, 4584.7) → AR(-0.80, -1.19, -3.84)
📊 3D Survey Markers: s1(-2.75, -1.19, 0.63) s2(-5.28, -1.19, -1.17) s3(-6.40, -1.19, -0.50) s4(-0.31, -1.19, 1.38) s5(-0.41, -1.19, 0.34) s6(-4.07, -1.19, -0.79) s7(-0.80, -1.19, -3.84) s8(-3.97, -1.19, 0.25) s9(-1.82, -1.19, -2.13) s10(-1.63, -1.19, -0.04) s11(-2.94, -1.19, -1.46) s12(-1.73, -1.19, -1.08) s13(-4.16, -1.19, -1.84) s14(-5.19, -1.19, -0.12) s15(-1.92, -1.19, -3.17) s16(-1.53, -1.19, 1.00) s17(-2.85, -1.19, -0.42) s18(-3.04, -1.19, -2.50) 
✅ Placed 18 survey markers
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [PIP_MAP] State changed: Survey Mode
🔍 [PIP_ONCHANGE] Calibration state changed: Survey Mode
Execution of the command buffer was aborted due to an error during execution. Insufficient Permission (to submit GPU work from background) (00000006:kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted)
Execution of the command buffer was aborted due to an error during execution. Insufficient Permission (to submit GPU work from background) (00000006:kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted)
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view
🔵 Selected triangle via long-press: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB
🎯 Long-press detected - starting calibration for triangle: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: CFB06EE1
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle CFB06EE1
🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: CFB06EE1
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
➕ Ground crosshair configured
🧹 Cleared survey markers
ARSession <0x115fc6f80>: ARSession is being deallocated without being paused. Please pause running sessions explicitly.
🆕 New AR session started: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Session timestamp: 2025-11-17 22:30:56 +0000
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: []
🧹 [CLEAR_MARKERS] Clearing markers for triangle CFB06EE1
   Before: []
   After: []
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: []
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106934ddc $s11TapResolver18TrianglePatchStoreC16_clearAllMarkers33_1038F30D4546FD018964946DBEC54D69LL3fory10Foundation4UUIDV_tF + 2008
   2   TapResolver.debug.dylib             0x0000000106934460 $s11TapResolver18TrianglePatchStoreC15clearAllMarkers3fory10Foundation4UUIDV_tFyyXEfU_ + 68
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ [CLEAR_MARKERS] Cleared and saved
   New arMarkerIDs: []
📍 Starting calibration with vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
📍 getCurrentVertexID: returning vertex[0] = 9E947C28
🎯 Guiding user to Map Point (3388.7, 4808.3)
🎯 ARCalibrationCoordinator: Starting calibration for triangle CFB06EE1
📍 Calibration vertices set: ["9E947C28", "90EA7A4A", "58BA635B"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle CFB06EE1
🧪 ARView ID: triangle viewing mode for CFB06EE1
🧪 ARViewWithOverlays instance: 0x000000015daded80
🔺 Entering triangle calibration mode for triangle: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex 9E947C28
📍 PiP Map: Displaying focused point 9E947C28 at (3388, 4808)
MapCanvas mapTransform: ObjectIdentifier(0x0000000115d6d380) mapSize: (0.0, 0.0)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
App is being debugged, do not track this hang
Hang detected: 0.52s (debugger attached, not reporting)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [FOCUSED_POINT] placingVertices state - focusing on 9E947C28
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 37F9E6E5 at AR(-4.75, -1.13, -2.95) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 37F9E6E5
   currentVertexID: 9E947C28
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 9E947C28
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 9E947C28.jpg (745 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(-4.75, -1.13, -2.95) meters for Map Point (3388.7, 4808.3) pixels
📍 registerMarker called for MapPoint 9E947C28
🖼 Photo '9E947C28.jpg' linked to MapPoint 9E947C28
💾 Saving AR Marker:
   Marker ID: 37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700
   Linked Map Point: 9E947C28-E6BE-459F-A161-E3B00AA13B05
   AR Position: (-4.75, -1.13, -2.95) meters
   Map Coordinates: (3388.7, 4808.3) pixels
📍 Saved marker 37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700 (MapPoint: 9E947C28-E6BE-459F-A161-E3B00AA13B05)
💾 Saving AR Marker with session context:
   Marker ID: 37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700
   Session ID: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Session Time: 2025-11-17 22:30:56 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: CFB06EE1
   vertexMapPointID: 9E947C28
   markerID: 37F9E6E5
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: CFB06EE1
   Current arMarkerIDs: []
   Current arMarkerIDs.count: 0
🔍 [ADD_MARKER_TRACE] Found vertex at index 0
🔍 [ADD_MARKER_TRACE] Initialized arMarkerIDs array with 3 empty slots
🔍 [ADD_MARKER_TRACE] Array ready, setting index 0
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[0]:
   Old value: ''
   New value: '37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700'
   Updated arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "", ""]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "", ""]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 37F9E6E5 to triangle vertex 0
📍 Advanced to next vertex: index=1, vertexID=90EA7A4A
🎯 Guiding user to Map Point (3411.7, 5005.7)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 9E947C28 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 37F9E6E5 for vertex 9E947C28
📍 getCurrentVertexID: returning vertex[1] = 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [FOCUSED_POINT] placingVertices state - focusing on 90EA7A4A
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 26006ECE at AR(-6.16, -1.12, 0.54) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 26006ECE
   currentVertexID: 90EA7A4A
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 90EA7A4A
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 90EA7A4A.jpg (554 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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

📸 [PHOTO_TRACE] Captured photo for MapPoint 90EA7A4A
🔗 AR Marker planted at AR(-6.16, -1.12, 0.54) meters for Map Point (3411.7, 5005.7) pixels
📍 registerMarker called for MapPoint 90EA7A4A
🖼 Photo '90EA7A4A.jpg' linked to MapPoint 90EA7A4A
💾 Saving AR Marker:
   Marker ID: 26006ECE-26B0-4DA7-B1C7-30F8559EE16A
   Linked Map Point: 90EA7A4A-5D3E-4D9D-8239-AA9F9023E82C
   AR Position: (-6.16, -1.12, 0.54) meters
   Map Coordinates: (3411.7, 5005.7) pixels
📍 Saved marker 26006ECE-26B0-4DA7-B1C7-30F8559EE16A (MapPoint: 90EA7A4A-5D3E-4D9D-8239-AA9F9023E82C)
💾 Saving AR Marker with session context:
   Marker ID: 26006ECE-26B0-4DA7-B1C7-30F8559EE16A
   Session ID: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Session Time: 2025-11-17 22:30:56 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: CFB06EE1
   vertexMapPointID: 90EA7A4A
   markerID: 26006ECE
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: CFB06EE1
   Current arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 1
🔍 [ADD_MARKER_TRACE] Array ready, setting index 1
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[1]:
   Old value: ''
   New value: '26006ECE-26B0-4DA7-B1C7-30F8559EE16A'
   Updated arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", ""]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", ""]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", ""]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "26006ECE", ""]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", ""]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker 26006ECE to triangle vertex 1
📍 Advanced to next vertex: index=2, vertexID=58BA635B
🎯 Guiding user to Map Point (3691.9, 4799.2)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 90EA7A4A (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 26006ECE for vertex 90EA7A4A
📍 getCurrentVertexID: returning vertex[2] = 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [PIP_ONCHANGE] Calibration state changed: Placing Vertices (index: 1)
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [FOCUSED_POINT] placingVertices state - focusing on 58BA635B
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker A4E9D193 at AR(0.97, -1.14, 0.07) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x000000010687f8a8 $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: A4E9D193
   currentVertexID: 58BA635B
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 58BA635B
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: 58BA635B.jpg (676 KB)

================================================================================
💾 DATA SAVE TRACE: MapPointStore.save()
================================================================================
   [SAVE-1] MapPointStore.save() CALLED
   [SAVE-2] Instance ID: F867F6CA...
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
🔗 AR Marker planted at AR(0.97, -1.14, 0.07) meters for Map Point (3691.9, 4799.2) pixels
📍 registerMarker called for MapPoint 58BA635B
🖼 Photo '58BA635B.jpg' linked to MapPoint 58BA635B
💾 Saving AR Marker:
   Marker ID: A4E9D193-8215-4865-A0F7-50B3DE6BCF52
   Linked Map Point: 58BA635B-D29D-481B-95F5-202A8A432D04
   AR Position: (0.97, -1.14, 0.07) meters
   Map Coordinates: (3691.9, 4799.2) pixels
📍 Saved marker A4E9D193-8215-4865-A0F7-50B3DE6BCF52 (MapPoint: 58BA635B-D29D-481B-95F5-202A8A432D04)
💾 Saving AR Marker with session context:
   Marker ID: A4E9D193-8215-4865-A0F7-50B3DE6BCF52
   Session ID: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Session Time: 2025-11-17 22:30:56 +0000
   Storage Key: ARWorldMapStore (saved successfully)
🔍 [ADD_MARKER_TRACE] Called with:
   triangleID: CFB06EE1
   vertexMapPointID: 58BA635B
   markerID: A4E9D193
🔍 [ADD_MARKER_TRACE] Triangle found:
   Triangle ID: CFB06EE1
   Current arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", ""]
   Current arMarkerIDs.count: 3
🔍 [ADD_MARKER_TRACE] Found vertex at index 2
🔍 [ADD_MARKER_TRACE] Array ready, setting index 2
🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[2]:
   Old value: ''
   New value: 'A4E9D193-8215-4865-A0F7-50B3DE6BCF52'
   Updated arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
🔍 [ADD_MARKER_TRACE] Verifying update BEFORE save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106937ae4 $s11TapResolver18TrianglePatchStoreC012_addMarkerToC033_1038F30D4546FD018964946DBEC54D69LL10triangleID014vertexMapPointO006markerO0y10Foundation4UUIDV_A2KtF + 9000
   2   TapResolver.debug.dylib             0x00000001069355c0 $s11TapResolver18TrianglePatchStoreC011addMarkerToC010triangleID014vertexMapPointJ006markerJ0y10Foundation4UUIDV_A2JtFyyXEfU_ + 100
   3   TapResolver.debug.dylib             0x0000000106934544 $sIg_Ieg_TR + 20
   4   TapResolver.debug.dylib             0x000000010693459c $sIeg_IyB_TR + 24
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "26006ECE", "A4E9D193"]
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
🔍 [ADD_MARKER_TRACE] Verifying update AFTER save:
   triangles[1].arMarkerIDs = ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
✅ [ADD_MARKER_TRACE] Saved triangles to storage
✅ Added marker A4E9D193 to triangle vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint 58BA635B (3/3)
⚠️ Cannot compute quality: Only found 2/3 AR markers
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106938c80 $s11TapResolver18TrianglePatchStoreC14markCalibrated_7qualityy10Foundation4UUIDV_SftF + 824
   2   TapResolver.debug.dylib             0x0000000106785708 $s11TapResolver24ARCalibrationCoordinatorC19finalizeCalibration33_F64506FEE7F9EF4E533DE967F641E0F2LL3foryAA13TrianglePatchV_tF + 480
   3   TapResolver.debug.dylib             0x0000000106783898 $s11TapResolver24ARCalibrationCoordinatorC14registerMarker10mapPointID6markery10Foundation4UUIDV_AA8ARMarkerVtF + 12548
   4   TapResolver.debug.dylib             0x00000001068819bc $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A8_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A19_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA13_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A19_SgtFQOyAiEEA43_yQrA__A44_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA21_yAiEE12cornerRadius_11antialiasedQrA19__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA44__A44_AE9AlignmentVtFQOyA33__Qo__A24_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A42_tGG_Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAiEEA75_yQrqd__ANA76_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyAE4TextV_A40_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA96__Qo__A99_A99_tGGtGG_Qo__Qo__A24_Qo__Qo__AiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA40_yAGyA32__A96_tGG_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEEA47__A48_QrA19__SbtFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA13_yQrSdFQOyAiEEA14_A15_A16_QrA19__A19_tFQOyAiEE7overlay_A55_Qrqd___A57_tAeHRd__lFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA24_G_Qo__A96_Qo__Qo__Qo__Qo_GSgtGGAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA38_yAGyAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA40_yAGyA33__A96_tGG_Qo__Qo__A24_Qo__Qo__A115_tGG_Qo_SgAiEEA43_yQrA__A44_tFQOyA40_yAGyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA133_yAE6CircleVA24_G_Qo__A159_A159_tGG_Qo_AiEEA43_yQrA__A44_tFQOyA96__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA52_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA55_QrA44__A44_A44_A44_A44_A44_A57_tFQOyA163__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA123_yAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA45_yQrqd__AEA46_Rd__lFQOyA21_yAiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyAiEEA22_yQrA25_FQOyA38_yA108_G_Qo__Qo__Qo__A24_Qo__Qo_G_A63_Qo__Qo__Qo_AiEEA43_yQrA__A44_tFQOyAiEEA52_A53_A54_A55_QrA44__A44_A57_tFQOyA42__Qo__Qo_GtGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyAiEEA43_yQrA__A44_tFQOyA38_yAGyA96__AiEEA47__A48_QrA19__SbtFQOyAiEEA49__A50_Qrqd___A_tAEA51_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA96_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA96__SSQo_GG_AE20SegmentedPickerStyleVQo__A172_Qo__Qo_tGG_Qo__Qo_A178_tGG_Qo_SgAiEEA13_yQrSdFQOyA38_yAGyA42__AiEEA43_yQrA__A44_tFQOyA40_yAGyA186__A186_tGG_Qo_tGG_Qo_SgtGyXEfU_yA7_12NotificationVcfU2_ + 10388
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "26006ECE", "A4E9D193"]
   Calibrated: true
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Marked triangle CFB06EE1 as calibrated (quality: 0%)
🔍 Triangle CFB06EE1 state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["37F9E6E5", "26006ECE", "A4E9D193"]
🎉 ARCalibrationCoordinator: Triangle CFB06EE1 calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for CFB06EE1
⚠️ Triangle doesn't have 3 AR markers yet
🔄 Reset currentVertexIndex to 0 for next calibration
ℹ️ Calibration complete. User can now fill triangle or manually start next calibration.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker A4E9D193 for vertex 58BA635B
📍 getCurrentVertexID: returning vertex[0] = 9E947C28
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
🔍 [PIP_ONCHANGE] Calibration state changed: Ready to Fill
🎯 [PIP_ONCHANGE] Triggering triangle frame calculation
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
✅ [PIP_ONCHANGE] Applied triangle framing transform
🎯 PiP Map: Triangle complete - fitting all 3 vertices
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds:
   Corner A: (3288, 4699)
   Corner B: (3791, 5105)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.492, offset: (273.4, -396.8)
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: CFB06EE1
   Features: 2262
   Size: 13.6 MB
   Path: /var/mobile/Containers/Data/Application/924E3D28-15DF-4EFE-B833-7A162B05F8A9/Documents/locations/museum/ARSpatial/Strategies/worldmap/CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB.armap
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x0000000106939bf4 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for8filenamey10Foundation4UUIDV_SStF + 428
   2   TapResolver.debug.dylib             0x000000010678a354 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3848
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "26006ECE", "A4E9D193"]
   Calibrated: true
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename 'CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB.armap' for triangle CFB06EE1
🔍 [SAVE_TRACE] save() called
   Thread: <_NSMainThread: 0x10529dd90>{number = 1, name = main}
   Triangle count: 10
   Triangle[0] markers: ["9042529A-436A-49B2-ADFB-B5DB4112E136", "08307331-4DCF-4966-A48B-BACBDDFB36A2", "42FE0EAC-DF82-42F3-94EB-DB5C179ABA45"]
   Triangle[1] markers: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
   Triangle[2] markers: []
🔍 [SAVE_TRACE] Call stack:
   0   TapResolver.debug.dylib             0x000000010693b378 $s11TapResolver18TrianglePatchStoreC4saveyyF + 2660
   1   TapResolver.debug.dylib             0x000000010693a358 $s11TapResolver18TrianglePatchStoreC19setWorldMapFilename3for12strategyName8filenamey10Foundation4UUIDV_S2StF + 512
   2   TapResolver.debug.dylib             0x000000010678a3e4 $s11TapResolver24ARCalibrationCoordinatorC23saveWorldMapForTriangle33_F64506FEE7F9EF4E533DE967F641E0F2LLyyAA0I5PatchVFySo07ARWorldG0CSg_s5Error_pSgtcfU_ + 3992
   3   TapResolver.debug.dylib             0x0000000106a03e3c $s11TapResolver15ARViewContainerV0C11CoordinatorC18getCurrentWorldMap10completionyySo07ARWorldI0CSg_s5Error_pSgtc_tFyAJ_ALtcfU_ + 112
   4   TapResolver.debug.dylib             0x0000000106a03ee8 $sSo10ARWorldMapCSgs5Error_pSgIeggg_ACSo7NSErrorCSgIeyByy_TR + 148
💾 Saved 10 triangle(s)
💾 Saving Triangle 19A9999C:
   Vertices: ["B9714AA0", "58BA635B", "9E947C28"]
   AR Markers: ["9042529A", "08307331", "42FE0EAC"]
   Calibrated: true
   Quality: 0%
💾 Saving Triangle CFB06EE1:
   Vertices: ["9E947C28", "90EA7A4A", "58BA635B"]
   AR Markers: ["37F9E6E5", "26006ECE", "A4E9D193"]
   Calibrated: true
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
   AR Markers: ["CD8098C5", "6FDE5941", "32B96469"]
   Calibrated: true
   Quality: 0%
✅ Set world map filename 'CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB.armap' for strategy 'ARWorldMap' on triangle CFB06EE1
✅ Saved ARWorldMap for triangle CFB06EE1
   Strategy: worldmap (ARWorldMap)
   Features: 2262
   Center: (3497, 4871)
   Radius: 4.73m
   Filename: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB.armap
🎯 [FILL_TRIANGLE_BTN] Button tapped
   Current state: Ready to Fill
🎯 CalibrationState → Survey Mode
🎯 [FILL_TRIANGLE_BTN] Entering survey mode
   New state: Survey Mode
✅ [FILL_TRIANGLE] Found triangle CFB06EE1
   arMarkerIDs: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
   vertexIDs: ["9E947C28", "90EA7A4A", "58BA635B"]
🧹 Cleared survey markers
🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility
   Current session ID: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Triangle ID: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB
🔍 [SURVEY_VALIDATION] Current session ID: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs count: 3
🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs contents: ["37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700", "26006ECE-26B0-4DA7-B1C7-30F8559EE16A", "A4E9D193-8215-4865-A0F7-50B3DE6BCF52"]
🔍 [SURVEY_VALIDATION] Triangle vertexIDs: ["9E947C28", "90EA7A4A", "58BA635B"]
🔍 [SURVEY_VALIDATION] Checking vertex[0] 9E947C28
   arMarkerIDs.count: 3
   arMarkerIDs[0]: '37F9E6E5-06BE-40A6-B6E7-0EC0D0D89700' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[0] 9E947C28: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[1] 90EA7A4A
   arMarkerIDs.count: 3
   arMarkerIDs[1]: '26006ECE-26B0-4DA7-B1C7-30F8559EE16A' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[1] 90EA7A4A: Found in placedMarkers (current session)
🔍 [SURVEY_VALIDATION] Checking vertex[2] 58BA635B
   arMarkerIDs.count: 3
   arMarkerIDs[2]: 'A4E9D193-8215-4865-A0F7-50B3DE6BCF52' (isEmpty: false)
✅ [SURVEY_VALIDATION] Vertex[2] 58BA635B: Found in placedMarkers (current session)
📊 [SURVEY_VALIDATION] Summary:
   Current session markers: 3/3
   Other session markers: 0
   ✅ 9E947C28 via placedMarkers
   ✅ 90EA7A4A via placedMarkers
   ✅ 58BA635B via placedMarkers
✅ [SURVEY_VALIDATION] All 3 vertices from current session - proceeding
📍 Plotting points within triangle A(3388.7, 4808.3) B(3411.7, 5005.7) C(3691.9, 4799.2)
🔍 [SURVEY_3D] Getting AR positions for triangle vertices
   Current session: 25A31CC9-972A-4D52-91CA-FFB27560DB0B
   Triangle has 3 marker IDs
✅ [SURVEY_3D] Vertex[0] 9E947C28: current session (placedMarkers) at SIMD3<Float>(-4.748169, -1.1262375, -2.9536114)
   Session: 25A31CC9
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[1] 90EA7A4A: current session (placedMarkers) at SIMD3<Float>(-6.1612105, -1.1204045, 0.54175234)
   Session: 25A31CC9
   Source: current session (placedMarkers)
✅ [SURVEY_3D] Vertex[2] 58BA635B: current session (placedMarkers) at SIMD3<Float>(0.9690461, -1.138774, 0.06522809)
   Session: 25A31CC9
   Source: current session (placedMarkers)
🔍 [SURVEY_3D] Collected 3/3 AR positions
✅ [SURVEY_3D] All markers from current session - safe to proceed
🌍 Planting Survey Markers within triangle A(-4.75, -1.13, -2.95) B(-6.16, -1.12, 0.54) C(0.97, -1.14, 0.07)
📏 Map scale set: 43.832027 pixels per meter (1 meter = 43.832027 pixels)
📍 Generated 18 survey points at 1.0m spacing
📊 2D Survey Points: s1(3691.9, 4799.2) s2(3635.9, 4840.5) s3(3579.8, 4881.8) s4(3523.8, 4923.1) s5(3467.7, 4964.4) s6(3411.7, 5005.7) s7(3631.3, 4801.0) s8(3575.2, 4842.3) s9(3519.2, 4883.6) s10(3463.1, 4924.9) s11(3407.1, 4966.2) s12(3570.6, 4802.9) s13(3514.6, 4844.1) s14(3458.5, 4885.4) s15(3510.0, 4804.7) s16(3453.9, 4846.0) s17(3449.3, 4806.5) s18(3388.7, 4808.3) 
📍 Survey Marker placed at (0.97, -1.13, 0.07)
📍 Survey Marker placed at (0.97, -1.13, 0.07)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(0.97, -1.13, 0.07)
📍 Survey marker placed at map(3691.9, 4799.2) → AR(0.97, -1.13, 0.07)
📍 Survey Marker placed at (-0.46, -1.13, 0.16)
📍 Survey Marker placed at (-0.46, -1.13, 0.16)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-0.46, -1.13, 0.16)
📍 Survey marker placed at map(3635.9, 4840.5) → AR(-0.46, -1.13, 0.16)
📍 Survey Marker placed at (-1.88, -1.13, 0.26)
📍 Survey Marker placed at (-1.88, -1.13, 0.26)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-1.88, -1.13, 0.26)
📍 Survey marker placed at map(3579.8, 4881.8) → AR(-1.88, -1.13, 0.26)
📍 Survey Marker placed at (-3.31, -1.13, 0.35)
📍 Survey Marker placed at (-3.31, -1.13, 0.35)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-3.31, -1.13, 0.35)
📍 Survey marker placed at map(3523.8, 4923.1) → AR(-3.31, -1.13, 0.35)
📍 Survey Marker placed at (-4.74, -1.13, 0.45)
📍 Survey Marker placed at (-4.74, -1.13, 0.45)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-4.74, -1.13, 0.45)
📍 Survey marker placed at map(3467.7, 4964.4) → AR(-4.74, -1.13, 0.45)
📍 Survey Marker placed at (-6.16, -1.13, 0.54)
📍 Survey Marker placed at (-6.16, -1.13, 0.54)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-6.16, -1.13, 0.54)
📍 Survey marker placed at map(3411.7, 5005.7) → AR(-6.16, -1.13, 0.54)
📍 Survey Marker placed at (-0.17, -1.13, -0.54)
📍 Survey Marker placed at (-0.17, -1.13, -0.54)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-0.17, -1.13, -0.54)
📍 Survey marker placed at map(3631.3, 4801.0) → AR(-0.17, -1.13, -0.54)
📍 Survey Marker placed at (-1.60, -1.13, -0.44)
📍 Survey Marker placed at (-1.60, -1.13, -0.44)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-1.60, -1.13, -0.44)
📍 Survey marker placed at map(3575.2, 4842.3) → AR(-1.60, -1.13, -0.44)
📍 Survey Marker placed at (-3.03, -1.13, -0.35)
📍 Survey Marker placed at (-3.03, -1.13, -0.35)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-3.03, -1.13, -0.35)
📍 Survey marker placed at map(3519.2, 4883.6) → AR(-3.03, -1.13, -0.35)
📍 Survey Marker placed at (-4.45, -1.13, -0.25)
📍 Survey Marker placed at (-4.45, -1.13, -0.25)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-4.45, -1.13, -0.25)
📍 Survey marker placed at map(3463.1, 4924.9) → AR(-4.45, -1.13, -0.25)
📍 Survey Marker placed at (-5.88, -1.13, -0.16)
📍 Survey Marker placed at (-5.88, -1.13, -0.16)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-5.88, -1.13, -0.16)
📍 Survey marker placed at map(3407.1, 4966.2) → AR(-5.88, -1.13, -0.16)
📍 Survey Marker placed at (-1.32, -1.13, -1.14)
📍 Survey Marker placed at (-1.32, -1.13, -1.14)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-1.32, -1.13, -1.14)
📍 Survey marker placed at map(3570.6, 4802.9) → AR(-1.32, -1.13, -1.14)
📍 Survey Marker placed at (-2.74, -1.13, -1.05)
📍 Survey Marker placed at (-2.74, -1.13, -1.05)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-2.74, -1.13, -1.05)
📍 Survey marker placed at map(3514.6, 4844.1) → AR(-2.74, -1.13, -1.05)
📍 Survey Marker placed at (-4.17, -1.13, -0.95)
📍 Survey Marker placed at (-4.17, -1.13, -0.95)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-4.17, -1.13, -0.95)
📍 Survey marker placed at map(3458.5, 4885.4) → AR(-4.17, -1.13, -0.95)
📍 Survey Marker placed at (-2.46, -1.13, -1.75)
📍 Survey Marker placed at (-2.46, -1.13, -1.75)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-2.46, -1.13, -1.75)
📍 Survey marker placed at map(3510.0, 4804.7) → AR(-2.46, -1.13, -1.75)
📍 Survey Marker placed at (-3.89, -1.13, -1.65)
📍 Survey Marker placed at (-3.89, -1.13, -1.65)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-3.89, -1.13, -1.65)
📍 Survey marker placed at map(3453.9, 4846.0) → AR(-3.89, -1.13, -1.65)
📍 Survey Marker placed at (-3.60, -1.13, -2.35)
📍 Survey Marker placed at (-3.60, -1.13, -2.35)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-3.60, -1.13, -2.35)
📍 Survey marker placed at map(3449.3, 4806.5) → AR(-3.60, -1.13, -2.35)
📍 Survey Marker placed at (-4.75, -1.13, -2.95)
📍 Survey Marker placed at (-4.75, -1.13, -2.95)
📍 Placed survey marker at map(3388.7, 4808.3) → AR(-4.75, -1.13, -2.95)
📍 Survey marker placed at map(3388.7, 4808.3) → AR(-4.75, -1.13, -2.95)
📊 3D Survey Markers: s1(-4.74, -1.13, 0.45) s2(-1.88, -1.13, 0.26) s3(0.97, -1.13, 0.07) s4(-6.16, -1.13, 0.54) s5(-3.31, -1.13, 0.35) s6(-3.60, -1.13, -2.35) s7(-2.46, -1.13, -1.75) s8(-3.03, -1.13, -0.35) s9(-5.88, -1.13, -0.16) s10(-4.75, -1.13, -2.95) s11(-1.60, -1.13, -0.44) s12(-2.74, -1.13, -1.05) s13(-1.32, -1.13, -1.14) s14(-4.17, -1.13, -0.95) s15(-0.17, -1.13, -0.54) s16(-3.89, -1.13, -1.65) s17(-4.45, -1.13, -0.25) s18(-0.46, -1.13, 0.16) 
✅ Placed 18 survey markers
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [PIP_MAP] State changed: Survey Mode
🔍 [PIP_ONCHANGE] Calibration state changed: Survey Mode
🔍 [TAP_TRACE] Tap detected
   Current mode: triangleCalibration(triangleID: CFB06EE1-9EDE-4AFE-ABC8-A5EF971EF8EB)
👆 [TAP_TRACE] Tap ignored in triangle calibration mode — use Place Marker button
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear
🚀 ARViewLaunchContext: Dismissed AR view