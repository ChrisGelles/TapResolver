
================================================================================
🚀 TapResolver App Launch
   Date & Time: Nov 30, 2025 at 12:46:56 PM
================================================================================

🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: 81B9D8E4...
📂 Loaded 42 triangle(s)
🧱 MapPointStore init — ID: BC10B148...
📂 Loaded 42 triangle(s)
📍 ARWorldMapStore: Location changed → home
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"photoOutdated":false,"isLocked":true,"createdDate":784943511.980147,"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","y":191.99998474121094,"photoCapturedAtPositionX":896.3333282470703,"photoCapturedAtPositionY":191.99998474121094,"x":896.3333282470703,"roles":["triangle_edge"],"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"arPositionHistory":[{"timestamp":786208987...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Starting one-time legacy AR position history migration...
📦 [PURGE] Archived 30 record(s) from 4 MapPoint(s)
   Archive path: /var/mobile/Containers/Data/Application/A5FD9357-6C98-400C-886C-58388DECE43C/Documents/TapResolver-LegacyPositionHistory-2025-11-30-124657.json
✅ [PURGE] Migration complete!
   Purged 30 legacy AR position record(s)
   Affected 4 MapPoint(s)
   Ghost placement will use 2D map geometry until fresh data accumulates
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
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
🔄 MapPointStore: Starting reload for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"photoOutdated":false,"isLocked":true,"createdDate":784943511.980147,"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","y":191.99998474121094,"photoCapturedAtPositionX":896.3333282470703,"photoCapturedAtPositionY":191.99998474121094,"x":896.3333282470703,"roles":["triangle_edge"],"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"arPositionHistory":[{"timestamp":786208987...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
🔍 DEBUG: loadARMarkers() called for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Loaded 0 Anchor Package(s) for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
✅ MapPointStore: Reload complete - 22 points loaded
📍 ARWorldMapStore: Location changed → home

🔄 Checking for location metadata migration...
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/A5FD9357-6C98-400C-886C-58388DECE43C/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/A5FD9357-6C98-400C-886C-58388DECE43C/Documents/locations/museum/dots.json
   ✓ dots.json exists
   ✓ Read 1485 bytes from dots.json
✅ Location 'museum' already has all metadata fields
⚠️ No location.json found for 'default', skipping migration
✅ All locations up-to-date

🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"photoOutdated":false,"isLocked":true,"createdDate":784943511.980147,"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","y":191.99998474121094,"photoCapturedAtPositionX":896.3333282470703,"photoCapturedAtPositionY":191.99998474121094,"x":896.3333282470703,"roles":["triangle_edge"],"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"arPositionHistory":[{"timestamp":786208987...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sourceType":"calibration","positionArray":[2.7707705,-1.262866,-0.2350931],"confidenceScore":0.95,"id":"C529AAFA-9715-4EB1-B046-06423085011A","sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","timestamp":786208987.20878},{"sourceType"...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
App is being debugged, do not track this hang
Hang detected: 2.55s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.33s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 22
✅ Loaded map image for 'home' from Documents
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
📂 Loaded 42 triangle(s)
MapCanvas mapTransform: ObjectIdentifier(0x0000000158017f80) mapSize: (0.0, 0.0)
⚙️ Debug Settings Panel: OPEN
================================================================================
👁️ PURGE DIAGNOSTIC - LOCATION ISOLATION CHECK
================================================================================
📍 Current Location: 'home'

🗑️ WILL AFFECT:
   ✓ Triangles: /Documents/locations/home/dots.json
   ✓ ARWorldMaps: /Documents/locations/home/ARSpatial/
   ✓ Triangle count: 42
   ✓ Calibrated triangles: 2
   ✓ Total AR markers: 6

🛡️ WILL NOT AFFECT:
   ✓ Location '7cb98376-e31c-4245-b068-687f05630fb8' - UNTOUCHED
   ✓ Location 'museum' - UNTOUCHED

🎯 ACTION:
   Soft reset will clear calibration data but keep triangle mesh structure
   All triangles will be marked uncalibrated (isCalibrated = false)
   AR marker associations will be cleared (arMarkerIDs = [])
   Triangle vertices and mesh connectivity preserved
================================================================================
⚙️ Debug Settings Panel: CLOSED
Message from debugger: killed


================================================================================
🚀 TapResolver App Launch
   Date & Time: Nov 30, 2025 at 12:49:18 PM
================================================================================

🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: D835FBC6...
📂 Loaded 42 triangle(s)
🧱 MapPointStore init — ID: 8CB40054...
📂 Loaded 42 triangle(s)
📍 ARWorldMapStore: Location changed → home
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
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
🔄 MapPointStore: Starting reload for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
🔍 DEBUG: loadARMarkers() called for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Loaded 0 Anchor Package(s) for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
✅ MapPointStore: Reload complete - 22 points loaded
📍 ARWorldMapStore: Location changed → home

🔄 Checking for location metadata migration...
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CCBD19BB-EF6D-46BC-A748-9F7CBF548A14/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CCBD19BB-EF6D-46BC-A748-9F7CBF548A14/Documents/locations/museum/dots.json
   ✓ dots.json exists
   ✓ Read 1485 bytes from dots.json
✅ Location 'museum' already has all metadata fields
⚠️ No location.json found for 'default', skipping migration
✅ All locations up-to-date

🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","arPositionHistory":[{"timestamp":786208987.20878,"confidenceScore":0.95,"sourceType":"calibration","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30"},{"timestamp":786209690.438916,"confidenceScore":0.95,"sourceType":"calibration","positionArray":[0.8779059,-0.8577446,2.7019737],"id":"10B54E92-E34D-4D12-9FA9-4E6095EB4142","sessionID":"743251BB-D867-4CFD-AEAE...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
App is being debugged, do not track this hang
Hang detected: 2.79s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.35s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 22
✅ Loaded map image for 'home' from Documents
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","createdDate":784943511.980147,"photoCapturedAtPositionX":896.3333282470703,"y":191.99998474121094,"sessions":[],"photoCapturedAtPositionY":191.99998474121094,"x":896.3333282470703,"roles":["triangle_edge"],"isLocked":true,"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoFilename":"CDA8D91B.jpg","arPositionHistory":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
📂 Loaded 42 triangle(s)
MapCanvas mapTransform: ObjectIdentifier(0x000000010a030d80) mapSize: (0.0, 0.0)



================================================================================
🚀 TapResolver App Launch
   Date & Time: Nov 30, 2025 at 12:49:18 PM
================================================================================

🧠 ARWorldMapStore init (ARWorldMap-first architecture)
🧱 MapPointStore init — ID: D835FBC6...
📂 Loaded 42 triangle(s)
🧱 MapPointStore init — ID: 8CB40054...
📂 Loaded 42 triangle(s)
📍 ARWorldMapStore: Location changed → home
📍 MapPointStore: Location changed, reloading...
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
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
🔄 MapPointStore: Starting reload for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
Publishing changes from within view updates is not allowed, this will cause undefined behavior.

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
🔍 DEBUG: loadARMarkers() called for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
📍 Loaded 0 Anchor Package(s) for location 'home'
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
✅ MapPointStore: Reload complete - 22 points loaded
📍 ARWorldMapStore: Location changed → home

🔄 Checking for location metadata migration...
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CCBD19BB-EF6D-46BC-A748-9F7CBF548A14/Documents/locations/home/dots.json
   ✓ dots.json exists
   ✓ Read 529 bytes from dots.json
✅ Location 'home' already has all metadata fields
   🔍 Checking dots.json at: /var/mobile/Containers/Data/Application/CCBD19BB-EF6D-46BC-A748-9F7CBF548A14/Documents/locations/museum/dots.json
   ✓ dots.json exists
   ✓ Read 1485 bytes from dots.json
✅ Location 'museum' already has all metadata fields
⚠️ No location.json found for 'default', skipping migration
✅ All locations up-to-date

🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoCapturedAtPositionY":191.99998474121094,"sessions":[],"arPositionHistory":[{"sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sourceType":"calibration","timestamp":786208987.20878,"confidenceScore":0.95},{"sessionID":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
🔄 MapPointStore: Initial load for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","arPositionHistory":[{"timestamp":786208987.20878,"confidenceScore":0.95,"sourceType":"calibration","positionArray":[2.7707705,-1.262866,-0.2350931],"id":"C529AAFA-9715-4EB1-B046-06423085011A","sessionID":"9C9A5438-3C19-4EC8-9FCE-38818959DA30"},{"timestamp":786209690.438916,"confidenceScore":0.95,"sourceType":"calibration","positionArray":[0.8779059,-0.8577446,2.7019737],"id":"10B54E92-E34D-4D12-9FA9-4E6095EB4142","sessionID":"743251BB-D867-4CFD-AEAE...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
💾 Saved 22 Map Point(s)
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
App is being debugged, do not track this hang
Hang detected: 2.79s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.35s (debugger attached, not reporting)
🔍 DEBUG: activePointID on VStack appear = nil
🔍 DEBUG: Total points in store = 22
✅ Loaded map image for 'home' from Documents
🔄 MapPointStore: Starting reload for location 'home'

================================================================================
📖 DATA LOAD TRACE: PersistenceContext.read()
================================================================================
   [1] Base key requested: 'MapPoints_v1'
   [2] Current PersistenceContext.locationID: 'home'
   [3] Generated full key via key('MapPoints_v1'): 'locations.home.MapPoints_v1'
   [4] Querying UserDefaults.standard.data(forKey: 'locations.home.MapPoints_v1')
   [5] ✅ UserDefaults returned data
   [6] Data size: 14807 bytes (14.46 KB)
   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)
   [8] Raw JSON preview (first 500 chars): [{"id":"CDA8D91B-40E0-4DB1-A9DF-BE89B635752A","createdDate":784943511.980147,"photoCapturedAtPositionX":896.3333282470703,"y":191.99998474121094,"sessions":[],"photoCapturedAtPositionY":191.99998474121094,"x":896.3333282470703,"roles":["triangle_edge"],"isLocked":true,"triangleMemberships":["EB6817D6-0D89-462B-8CD1-477389E312A8","63EEDC4E-49B3-41B9-A048-A9F12E2DBDB1","1121AFA7-06C3-442D-B16F-276FC96C7327","EA3F01E6-184B-4C90-8E39-227EB4D34DEE"],"photoFilename":"CDA8D91B.jpg","arPositionHistory":...
   [9] ✅ JSONDecoder successfully decoded data
   [10] Decoded 22 items
   [12] Returning decoded data from PersistenceContext.read()
================================================================================

🧹 [PURGE] Skipped - legacy AR position history already purged
📦 Migrated 22 MapPoint(s) to include role metadata
⚠️ MapPointStore.save() blocked during reload operation
✅ MapPointStore: Reload complete - 22 points loaded
📊 [DIAG] MapPoint CDA8D91B has 3 position records
   Consensus: (1.28, -1.06, 1.80)
📊 [DIAG] MapPoint 6FCDC18C has 10 position records
   Consensus: (1.69, -1.00, -0.51)
📊 [DIAG] MapPoint 41EC22A9 has 7 position records
   Consensus: (-0.20, -1.00, -1.26)
📊 [DIAG] MapPoint 2C9EFCA9 has 10 position records
   Consensus: (-1.37, -1.01, 0.96)
🔍 DEBUG: loadARMarkers() called for location 'home'
📍 Legacy AR Markers in storage: 0 (will not be loaded)
   AR Markers are now created on-demand during AR sessions
📍 Loaded 0 Anchor Package(s) for location 'home'
✅ MapPointStore: Reload complete - 22 points loaded
📂 Loaded 42 triangle(s)
MapCanvas mapTransform: ObjectIdentifier(0x000000010a030d80) mapSize: (0.0, 0.0)
🔵 Selected triangle via long-press: 1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66
🎯 Long-press detected - starting calibration for triangle: 1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66
📱 MapNavigationView: Launching AR view for triangle calibration — FROM MapNav: 1AE7CCFF
🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle 1AE7CCFF
🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: 1AE7CCFF
ARSCNView implements focusItemsInRect: - caching for linear focus movement is limited as long as this view is on screen.
👆 Tap gesture configured
👻 Ghost marker notification listener registered
➕ Ground crosshair configured
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:275) - (err=-12784)
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:511) - (err=-12784)
🆕 New AR session started: C482FEAB-B68A-4672-90A1-F2C3DAFA91FE
   Session timestamp: 2025-11-30 17:50:18 +0000
🧪 ARView ID: triangle viewing mode for 1AE7CCFF
🧪 ARViewWithOverlays instance: 0x00000001160f5680
MapCanvas mapTransform: ObjectIdentifier(0x0000000116165f80) mapSize: (0.0, 0.0)
🎯 CalibrationState → Placing Vertices (index: 0)
🔄 Re-calibrating triangle - clearing ALL existing markers
   Old arMarkerIDs: ["0CAF7BB6-D968-45B5-BC01-15022EF5684A", "4ADE323E-55F7-4FAF-A979-30CD3F235A99", "99670AD7-5A15-4D9C-B895-11D611641704"]
🧹 [CLEAR_MARKERS] Clearing markers for triangle 1AE7CCFF
   Before: ["0CAF7BB6-D968-45B5-BC01-15022EF5684A", "4ADE323E-55F7-4FAF-A979-30CD3F235A99", "99670AD7-5A15-4D9C-B895-11D611641704"]
   After: []
💾 Saved 42 triangle(s)
✅ [CLEAR_MARKERS] Cleared and saved
   New arMarkerIDs: []
📍 Starting calibration with vertices: ["41EC22A9", "6FCDC18C", "2C9EFCA9"]
🔄 Re-calibrating triangle - clearing 3 existing markers
📍 getCurrentVertexID: returning vertex[0] = 41EC22A9
🎯 Guiding user to Map Point (72.0, 984.3)
🎯 ARCalibrationCoordinator: Starting calibration for triangle 1AE7CCFF
📍 Calibration vertices set: ["41EC22A9", "6FCDC18C", "2C9EFCA9"]
🎯 ARViewWithOverlays: Auto-initialized calibration for triangle 1AE7CCFF
🔺 Entering triangle calibration mode for triangle: 1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66
🔍 [PIP_MAP] State changed: Placing Vertices (index: 0)
🔍 [PIP_ONCHANGE] State → placingVertices(index: 0)
🔍 [PHOTO_REF] Displaying photo reference for vertex 41EC22A9
📍 PiP Map: Displaying focused point 41EC22A9 at (72, 984)
🔍 [FOCUSED_POINT] entered placingVertices state - focusing on 41EC22A9
warning: using linearization / solving fallback.
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 0EDF5EBC at AR(-0.26, -0.85, -3.33) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x00000001072c109c $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A7_Qo__Qo__A7_Qo__A7_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A21_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA15_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A21_SgtFQOyAiEEA45_yQrA__A46_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA23_yAiEE12cornerRadius_11antialiasedQrA21__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA46__A46_AE9AlignmentVtFQOyA35__Qo__A26_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A44_tGG_Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA21_FQOyA40_yAGyA42_yAGyA35__A40_yAGyAE4TextV_A98_tGGA35_tGG_A42_yAGyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA24_yQrA27_FQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA33__A98_tGG_Qo__Qo__A26_Qo__Qo__Qo_G_A110_tGGtGG_Qo__A26_Qo__Qo__Qo__Qo_SgAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__A42_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA98__Qo__A123_A123_tGGtGG_Qo__Qo__A26_Qo__Qo__AiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA42_yAGyA34__A98_tGG_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEE7overlay_A57_Qrqd___A59_tAeHRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA26_G_Qo__A98_Qo__Qo__Qo__Qo_GSgtGGAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA35__A98_tGG_Qo__Qo__A26_Qo__Qo__A139_tGG_Qo_SgAiEEA45_yQrA__A46_tFQOyA42_yAGyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA157_yAE6CircleVA26_G_Qo__A183_A183_tGG_Qo_AiEEA45_yQrA__A46_tFQOyA98__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA54_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA57_QrA46__A46_A46_A46_A46_A46_A59_tFQOyA187__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA147_yAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA40_yA132_G_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo__Qo__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA44__Qo__Qo_GtGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__AiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA98_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA98__SSQo_GG_AE20SegmentedPickerStyleVQo__A196_Qo__Qo_tGG_Qo__Qo_A202_tGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA42_yAGyA210__A210_tGG_Qo_tGG_Qo_SgtGyXEfU_yA6_12NotificationVcfU4_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 0EDF5EBC
   currentVertexID: 41EC22A9
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 41EC22A9
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 41EC22A9.jpg (366 KB)
💾 Saved 22 Map Point(s)
📸 [PHOTO_TRACE] Captured photo for MapPoint 41EC22A9
🔗 AR Marker planted at AR(-0.26, -0.85, -3.33) meters for Map Point (72.0, 984.3) pixels
📍 registerMarker called for MapPoint 41EC22A9
🖼 Photo '41EC22A9.jpg' linked to MapPoint 41EC22A9
💾 Saving AR Marker:
   Marker ID: 0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF
   Linked Map Point: 41EC22A9-E881-457F-B6E5-99BB35CF3383
   AR Position: (-0.26, -0.85, -3.33) meters
   Map Coordinates: (72.0, 984.3) pixels
📍 Saved marker 0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF (MapPoint: 41EC22A9-E881-457F-B6E5-99BB35CF3383)
💾 Saving AR Marker with session context:
   Marker ID: 0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF
   Session ID: C482FEAB-B68A-4672-90A1-F2C3DAFA91FE
   Session Time: 2025-11-30 17:50:18 +0000
   Storage Key: ARWorldMapStore (saved successfully)
📍 [SESSION_MARKERS] Stored position for 0EDF5EBC → MapPoint 41EC22A9
📍 [POSITION_HISTORY] calibration → MapPoint 41EC22A9 (#8)
   ↳ pos: (-0.26, -0.85, -3.33) @ 12:50:40 PM
💾 Saved 22 Map Point(s)
💾 Saved 42 triangle(s)
✅ Added marker 0EDF5EBC to triangle 1AE7CCFF vertex 0
📍 Advanced to next vertex: index=1, vertexID=6FCDC18C
🎯 Guiding user to Map Point (75.3, 196.0)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 41EC22A9 (1/3)
🎯 CalibrationState → Placing Vertices (index: 0)
✅ Registered marker 0EDF5EBC for vertex 41EC22A9
📍 getCurrentVertexID: returning vertex[1] = 6FCDC18C
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 0)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 18FC2645 at AR(2.92, -0.86, -0.34) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 0)
   Call stack trace:
      0   TapResolver.debug.dylib             0x00000001072c109c $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A7_Qo__Qo__A7_Qo__A7_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A21_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA15_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A21_SgtFQOyAiEEA45_yQrA__A46_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA23_yAiEE12cornerRadius_11antialiasedQrA21__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA46__A46_AE9AlignmentVtFQOyA35__Qo__A26_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A44_tGG_Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA21_FQOyA40_yAGyA42_yAGyA35__A40_yAGyAE4TextV_A98_tGGA35_tGG_A42_yAGyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA24_yQrA27_FQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA33__A98_tGG_Qo__Qo__A26_Qo__Qo__Qo_G_A110_tGGtGG_Qo__A26_Qo__Qo__Qo__Qo_SgAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__A42_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA98__Qo__A123_A123_tGGtGG_Qo__Qo__A26_Qo__Qo__AiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA42_yAGyA34__A98_tGG_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEE7overlay_A57_Qrqd___A59_tAeHRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA26_G_Qo__A98_Qo__Qo__Qo__Qo_GSgtGGAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA35__A98_tGG_Qo__Qo__A26_Qo__Qo__A139_tGG_Qo_SgAiEEA45_yQrA__A46_tFQOyA42_yAGyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA157_yAE6CircleVA26_G_Qo__A183_A183_tGG_Qo_AiEEA45_yQrA__A46_tFQOyA98__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA54_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA57_QrA46__A46_A46_A46_A46_A46_A59_tFQOyA187__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA147_yAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA40_yA132_G_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo__Qo__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA44__Qo__Qo_GtGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__AiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA98_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA98__SSQo_GG_AE20SegmentedPickerStyleVQo__A196_Qo__Qo_tGG_Qo__Qo_A202_tGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA42_yAGyA210__A210_tGG_Qo_tGG_Qo_SgtGyXEfU_yA6_12NotificationVcfU4_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 18FC2645
   currentVertexID: 6FCDC18C
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 6FCDC18C
   Calibration state: Placing Vertices (index: 0)
📸 Saved photo to disk: 6FCDC18C.jpg (305 KB)
💾 Saved 22 Map Point(s)
📸 [PHOTO_TRACE] Captured photo for MapPoint 6FCDC18C
🔗 AR Marker planted at AR(2.92, -0.86, -0.34) meters for Map Point (75.3, 196.0) pixels
📍 registerMarker called for MapPoint 6FCDC18C
🖼 Photo '6FCDC18C.jpg' linked to MapPoint 6FCDC18C
💾 Saving AR Marker:
   Marker ID: 18FC2645-EF9E-4E79-9028-F47DE97ABDB2
   Linked Map Point: 6FCDC18C-8D43-4CBE-BC3C-AACC4CA3E0FB
   AR Position: (2.92, -0.86, -0.34) meters
   Map Coordinates: (75.3, 196.0) pixels
📍 Saved marker 18FC2645-EF9E-4E79-9028-F47DE97ABDB2 (MapPoint: 6FCDC18C-8D43-4CBE-BC3C-AACC4CA3E0FB)
💾 Saving AR Marker with session context:
   Marker ID: 18FC2645-EF9E-4E79-9028-F47DE97ABDB2
   Session ID: C482FEAB-B68A-4672-90A1-F2C3DAFA91FE
   Session Time: 2025-11-30 17:50:18 +0000
   Storage Key: ARWorldMapStore (saved successfully)
📍 [SESSION_MARKERS] Stored position for 18FC2645 → MapPoint 6FCDC18C
📍 [POSITION_HISTORY] calibration → MapPoint 6FCDC18C (#11)
   ↳ pos: (2.92, -0.86, -0.34) @ 12:50:56 PM
💾 Saved 22 Map Point(s)
💾 Saved 42 triangle(s)
✅ Added marker 18FC2645 to triangle 1AE7CCFF vertex 1
📍 [GHOST_3RD] Found AR positions for 2 placed markers
   Marker 1 (41EC22A9): SIMD3<Float>(-0.26323256, -0.84985983, -3.3334115)
   Marker 2 (6FCDC18C): SIMD3<Float>(2.918609, -0.8580048, -0.34135222)
📍 [GHOST_3RD] Attempting rigid transform for 2C9EFCA9
   Historical positions: P1=(-0.21, -0.98, -1.52), P2=(1.80, -0.99, -0.49)
   Current positions: P1=(-0.26, -0.85, -3.33), P2=(2.92, -0.86, -0.34)
⚠️ [RIGID_TRANSFORM] High verification error: 2.11m
   This may indicate scale difference between sessions
📐 [RIGID_TRANSFORM] Calculated transform:
   Rotation: 16.3°
   Translation: (-0.49, 0.13, -1.82)
   Verification error: 2.111m
⚠️ [GHOST_3RD] Verification error 2.11m exceeds 1.0m threshold
   Historical consensus is unreliable - falling back to map geometry
📐 [GHOST_3RD] No consensus - calculating from 2D map geometry
👻 [GHOST_3RD] Calculated from map: (-2.80, -0.85, -0.50)
   Scale: 0.0055 AR meters per map pixel
   Rotation: 133.0°
👻 [GHOST_RENDER] Placing ghost marker for MapPoint 2C9EFCA9
✅ [GHOST_RENDER] Ghost marker rendered for MapPoint 2C9EFCA9
👻 [GHOST_3RD] Planted ghost for 3rd vertex 2C9EFCA9
📍 Advanced to next vertex: index=2, vertexID=2C9EFCA9
🎯 Guiding user to Map Point (759.1, 971.0)
✅ ARCalibrationCoordinator: Registered marker for MapPoint 6FCDC18C (2/3)
🎯 CalibrationState → Placing Vertices (index: 1)
✅ Registered marker 18FC2645 for vertex 6FCDC18C
📍 getCurrentVertexID: returning vertex[2] = 2C9EFCA9
🔍 [PIP_MAP] State changed: Placing Vertices (index: 1)
🔍 [PIP_ONCHANGE] State → placingVertices(index: 1)
🔍 [PLACE_MARKER_BTN] Button tapped
   Calibration state: Placing Vertices (index: 1)
🔍 [PLACE_MARKER_CROSSHAIR] Called
📍 Placed marker 36461CBB at AR(-2.83, -0.88, -0.61) meters
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
   Calibration state: Placing Vertices (index: 1)
   Call stack trace:
      0   TapResolver.debug.dylib             0x00000001072c109c $s11TapResolver18ARViewWithOverlaysV4bodyQrvg7SwiftUI9TupleViewVyAE0J0PAEE9onReceive_7performQrqd___y6OutputQyd__ct7Combine9PublisherRd__s5NeverO7FailureRtd__lFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K9DisappearAKQryycSg_tFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEEAJ_AKQrqd___yAMctAnORd__AqSRSlFQOyAiEE0K6AppearAKQrAU_tFQOyAiEE21edgesIgnoringSafeAreayQrAE4EdgeO3SetVFQOyAA0C9ContainerV_Qo__Qo__So20NSNotificationCenterC10FoundationEAOVQo__A7_Qo__Qo__A7_Qo__A7_Qo__AE14GeometryReaderVyAGyAiEE6zIndexyQrSdFQOyAiEE8position1x1yQr12CoreGraphics7CGFloatV_A21_tFQOyAE6ButtonVyAiEE15foregroundColoryQrAE5ColorVSgFQOyAiEE4fontyQrAE4FontVSgFQOyAE5ImageV_Qo__Qo_G_Qo__Qo__AiEEA15_yQrSdFQOyAE6VStackVyAGyAE6HStackVyAGyAE6SpacerV_AiEE7paddingyQrA__A21_SgtFQOyAiEEA45_yQrA__A46_tFQOyAiEE11buttonStyleyQrqd__AE20PrimitiveButtonStyleRd__lFQOyA23_yAiEE12cornerRadius_11antialiasedQrA21__SbtFQOyAiEE10background_07ignoreswX5EdgesQrqd___A_tAE10ShapeStyleRd__lFQOyAiEE5frame5width6height9alignmentQrA46__A46_AE9AlignmentVtFQOyA35__Qo__A26_Qo__Qo_G_AE16PlainButtonStyleVQo__Qo__Qo_tGG_A44_tGG_Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEE0K6Change2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAiEE17environmentObjectyQrqd__AN16ObservableObjectRd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAiEEA77_yQrqd__ANA78_Rd__lFQOyAA08ARPiPMapJ0V_AA13MapPointStoreCQo__AA15LocationManagerCQo__AA24ARCalibrationCoordinatorCQo__Qo__AA16CalibrationStateOQo__Qo__Qo__Qo_AiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA21_FQOyA40_yAGyA42_yAGyA35__A40_yAGyAE4TextV_A98_tGGA35_tGG_A42_yAGyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA24_yQrA27_FQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA33__A98_tGG_Qo__Qo__A26_Qo__Qo__Qo_G_A110_tGGtGG_Qo__A26_Qo__Qo__Qo__Qo_SgAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__A42_yAGyAiEE0kA7Gesture5countAKQrSi_yyctFQOyA98__Qo__A123_A123_tGGtGG_Qo__Qo__A26_Qo__Qo__AiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA42_yAGyA34__A98_tGG_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo_tGG_Qo__Qo_SgAE19_ConditionalContentVyAiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEEA49__A50_QrA21__SbtFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAA016ARReferenceImageJ0V_Qo__Qo__Qo__Qo__Qo_AiEEAvKQrAU_tFQOyAiEEA15_yQrSdFQOyAiEEA16_A17_A18_QrA21__A21_tFQOyAiEE7overlay_A57_Qrqd___A59_tAeHRd__lFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyAE06_ShapeJ0VyAE16RoundedRectangleVA26_G_Qo__A98_Qo__Qo__Qo__Qo_GSgtGGAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA40_yAGyAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA42_yAGyA35__A98_tGG_Qo__Qo__A26_Qo__Qo__A139_tGG_Qo_SgAiEEA45_yQrA__A46_tFQOyA42_yAGyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA157_yAE6CircleVA26_G_Qo__A183_A183_tGG_Qo_AiEEA45_yQrA__A46_tFQOyA98__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA54_8minWidth10idealWidth8maxWidth9minHeight11idealHeight9maxHeightA57_QrA46__A46_A46_A46_A46_A46_A59_tFQOyA187__Qo__AE8MaterialVQo__Qo_G_Qo__Qo_SgA147_yAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA47_yQrqd__AEA48_Rd__lFQOyA23_yAiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyAiEEA24_yQrA27_FQOyA40_yA132_G_Qo__Qo__Qo__A26_Qo__Qo_G_A65_Qo__Qo__Qo_AiEEA45_yQrA__A46_tFQOyAiEEA54_A55_A56_A57_QrA46__A46_A59_tFQOyA44__Qo__Qo_GtGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyAiEEA45_yQrA__A46_tFQOyA40_yAGyA98__AiEEA49__A50_QrA21__SbtFQOyAiEEA51__A52_Qrqd___A_tAEA53_Rd__lFQOyAiEE11pickerStyleyQrqd__AE11PickerStyleRd__lFQOyAE6PickerVyA98_SSAE7ForEachVySayAA22RelocalizationStrategy_pGSSAiEE3tag_15includeOptionalQrqd___SbtSHRd__lFQOyA98__SSQo_GG_AE20SegmentedPickerStyleVQo__A196_Qo__Qo_tGG_Qo__Qo_A202_tGG_Qo_SgAiEEA15_yQrSdFQOyA40_yAGyA44__AiEEA45_yQrA__A46_tFQOyA42_yAGyA210__A210_tGG_Qo_tGG_Qo_SgtGyXEfU_yA6_12NotificationVcfU4_ + 1920
      1   SwiftUI                             0x000000018ffda1b0 43149985-7D90-345D-8C31-B764E66E9C4E + 3387824
      2   SwiftUICore                         0x000000024c3bc25c 7F33A4B0-FB5C-36B0-9C41-D098C435B84D + 6173276
      3   SwiftUICore                         0x000000024bdeb0dc $s7SwiftUI6UpdateO15dispatchActionsyyFZ + 1316
      4   SwiftUICore                         0x000000024bdea578 $s7SwiftUI6UpdateO3endyyFZ + 212
🔍 [REGISTER_MARKER_TRACE] Processing marker:
   markerID: 36461CBB
   currentVertexID: 2C9EFCA9
🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)
   mapPoint.id: 2C9EFCA9
   Calibration state: Placing Vertices (index: 1)
📸 Saved photo to disk: 2C9EFCA9.jpg (442 KB)
💾 Saved 22 Map Point(s)
📸 [PHOTO_TRACE] Captured photo for MapPoint 2C9EFCA9
🔗 AR Marker planted at AR(-2.83, -0.88, -0.61) meters for Map Point (759.1, 971.0) pixels
📍 registerMarker called for MapPoint 2C9EFCA9
🖼 Photo '2C9EFCA9.jpg' linked to MapPoint 2C9EFCA9
💾 Saving AR Marker:
   Marker ID: 36461CBB-F394-41CE-AEA5-786D948E141C
   Linked Map Point: 2C9EFCA9-5778-4275-A12E-3D1D3A2101E2
   AR Position: (-2.83, -0.88, -0.61) meters
   Map Coordinates: (759.1, 971.0) pixels
📍 Saved marker 36461CBB-F394-41CE-AEA5-786D948E141C (MapPoint: 2C9EFCA9-5778-4275-A12E-3D1D3A2101E2)
💾 Saving AR Marker with session context:
   Marker ID: 36461CBB-F394-41CE-AEA5-786D948E141C
   Session ID: C482FEAB-B68A-4672-90A1-F2C3DAFA91FE
   Session Time: 2025-11-30 17:50:18 +0000
   Storage Key: ARWorldMapStore (saved successfully)
📍 [SESSION_MARKERS] Stored position for 36461CBB → MapPoint 2C9EFCA9
📏 [PLACEMENT_CHECK] Distance from ghost: 0.12m
   Ghost position: (-2.80, -0.85, -0.50)
   Actual position: (-2.83, -0.88, -0.61)
📍 [POSITION_HISTORY] calibration → MapPoint 2C9EFCA9 (#11)
   ↳ pos: (-2.83, -0.88, -0.61) @ 12:51:16 PM
💾 Saved 22 Map Point(s)
💾 Saved 42 triangle(s)
✅ Added marker 36461CBB to triangle 1AE7CCFF vertex 2
✅ ARCalibrationCoordinator: Registered marker for MapPoint 2C9EFCA9 (3/3)
⚠️ Cannot compute quality: Only found 2/3 AR markers
💾 Saved 42 triangle(s)
✅ Marked triangle 1AE7CCFF as calibrated (quality: 0%)
🔍 Triangle 1AE7CCFF state after marking:
   isCalibrated: true
   arMarkerIDs count: 3
   arMarkerIDs: ["0EDF5EBC", "18FC2645", "36461CBB"]
🎉 ARCalibrationCoordinator: Triangle 1AE7CCFF calibration complete (quality: 0%)
📐 Triangle calibration complete - drawing lines for 1AE7CCFF
⚠️ Could not find marker node for 0CAF7BB6-D968-45B5-BC01-15022EF5684A
🔍 [FINALIZE] Fresh triangle for ghost planting - arMarkerIDs: ["0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF", "18FC2645-EF9E-4E79-9028-F47DE97ABDB2", "36461CBB-F394-41CE-AEA5-786D948E141C"]
🔍 [GHOST_PLANT] Finding adjacent triangles to 1AE7CCFF
🔍 [GHOST_PLANT] Found 3 adjacent triangle(s)
⚠️ [GHOST_PLANT] Could not find MapPoint for far vertex 9E5E7332
🔍 [GHOST_CALC] Fresh triangle fetch - arMarkerIDs: ["0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF", "18FC2645-EF9E-4E79-9028-F47DE97ABDB2", "36461CBB-F394-41CE-AEA5-786D948E141C"]
📐 [GHOST_CALC] Barycentric weights: w1=0.734, w2=-0.368, w3=0.634
✅ [GHOST_CALC] Found marker 0EDF5EBC in session cache at position (-0.26, -0.85, -3.33)
✅ [GHOST_CALC] Found marker 18FC2645 in session cache at position (2.92, -0.86, -0.34)
✅ [GHOST_CALC] Found marker 36461CBB in session cache at position (-2.83, -0.88, -0.61)
👻 [GHOST_CALC] Calculated ghost position: (-3.06, -0.86, -2.71)
👻 [GHOST_RENDER] Placing ghost marker for MapPoint 8AD544F4
✅ [GHOST_RENDER] Ghost marker rendered for MapPoint 8AD544F4
👻 [GHOST_PLANT] Planted ghost for MapPoint 8AD544F4 at position SIMD3<Float>(-3.0639725, -0.862836, -2.7079618)
🔍 [GHOST_CALC] Fresh triangle fetch - arMarkerIDs: ["0EDF5EBC-CAAA-40D5-B548-A00E670E3CAF", "18FC2645-EF9E-4E79-9028-F47DE97ABDB2", "36461CBB-F394-41CE-AEA5-786D948E141C"]
📐 [GHOST_CALC] Barycentric weights: w1=-1.180, w2=0.985, w3=1.195
✅ [GHOST_CALC] Found marker 0EDF5EBC in session cache at position (-0.26, -0.85, -3.33)
✅ [GHOST_CALC] Found marker 18FC2645 in session cache at position (2.92, -0.86, -0.34)
✅ [GHOST_CALC] Found marker 36461CBB in session cache at position (-2.83, -0.88, -0.61)
👻 [GHOST_CALC] Calculated ghost position: (-0.20, -0.89, 2.87)
👻 [GHOST_RENDER] Placing ghost marker for MapPoint CDA8D91B
✅ [GHOST_RENDER] Ghost marker rendered for MapPoint CDA8D91B
👻 [GHOST_PLANT] Planted ghost for MapPoint CDA8D91B at position SIMD3<Float>(-0.20174956, -0.88799244, 2.8680284)
✅ [GHOST_PLANT] Planted 2 ghost marker(s) for adjacent triangle vertices (including previously-calibrated triangles)
🔄 Reset currentVertexIndex to 0 for next calibration
✅ Calibration complete. Ghost markers planted for adjacent triangles.
🎯 CalibrationState → Ready to Fill
✅ Calibration complete. Triangle ready to fill.
✅ Registered marker 36461CBB for vertex 2C9EFCA9
📍 getCurrentVertexID: returning vertex[0] = 41EC22A9
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
Modifying state during view update, this will cause undefined behavior.
📐 [PIP_TRANSFORM] Triangle bounds: A(-28, 95) B(859, 1084)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.202, offset: (123.1, 87.8)
🔍 [PIP_MAP] State changed: Ready to Fill
🎯 [PIP_MAP] Triangle complete - should frame entire triangle
🔍 [PIP_ONCHANGE] State → readyToFill
🎯 [PIP_ONCHANGE] Triggering triangle frame calculation
🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds
📐 [PIP_TRANSFORM] Triangle bounds: A(-28, 95) B(859, 1084)
✅ [PIP_TRANSFORM] Calculated triangle frame - scale: 0.202, offset: (123.1, 87.8)
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=0
🔍 [FOCUSED_POINT] exited placingVertices state - was focusing on 2C9EFCA9
✅ [PIP_ONCHANGE] Applied triangle framing transform
🎯 PiP Map: Triangle complete - fitting all 3 vertices
📦 Saved ARWorldMap for strategy 'worldmap'
   Triangle: 1AE7CCFF
   Features: 4879
   Size: 17.7 MB
   Path: /var/mobile/Containers/Data/Application/CCBD19BB-EF6D-46BC-A748-9F7CBF548A14/Documents/locations/home/ARSpatial/Strategies/worldmap/1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66.armap
💾 Saved 42 triangle(s)
✅ Set world map filename '1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66.armap' for triangle 1AE7CCFF
💾 Saved 42 triangle(s)
✅ Set world map filename '1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66.armap' for strategy 'ARWorldMap' on triangle 1AE7CCFF
✅ Saved ARWorldMap for triangle 1AE7CCFF
   Strategy: worldmap (ARWorldMap)
   Features: 4879
   Center: (302, 717)
   Radius: 3.17m
   Filename: 1AE7CCFF-1E1B-4A26-BEBE-5F19CA6FFF66.armap
🚀 ARViewLaunchContext: Dismissed AR view
🚀 ARViewLaunchContext: Dismissed AR view
🧹 Cleared survey markers
🧹 Cleared 3 calibration marker(s) from scene
🎯 CalibrationState → Idle (reset)
🔄 ARCalibrationCoordinator: Reset complete - all markers cleared
🧹 ARViewWithOverlays: Cleaned up on disappear