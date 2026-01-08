# TapResolver

iOS app for mapping and calibrating beacon positions using AR and manual positioning.

## Features

- **AR-based mapping** - Use ARKit to capture beacon positions
- **Manual positioning** - Drag and drop beacons on map
- **Multi-location support** - Organize beacons by location
- **Beacon configuration** - Read/write settings via kBeacon integration
- **Data export** - Export maps and beacon data

## Requirements

- iOS 15.0+
- Xcode 15.0+
- CocoaPods

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   pod install
   ```
3. Open `TapResolver.xcworkspace` (not `.xcodeproj`)
4. Build and run

## Architecture

### Data Persistence

**Beacon Dots (V2)**
- Single source of truth: `BeaconDots_v2` in UserDefaults
- Consolidates: positions, elevations, txPower, locks, intervals, MAC addresses, model, firmware, session tracking
- Location-scoped: `locations.<locationID>.BeaconDots_v2`

**Migration from Legacy Data**
If you have existing data from older versions:
1. Open Debug Settings (in-app)
2. Tap "Force V2 Re-Migration"
3. Verify dots appear correctly

### Key Components

- `BeaconDotStore` - Manages beacon positions and metadata
- `MapPointStore` - Manages AR scan points
- `TrianglePatchStore` - Manages calibration triangles
- `LocationManager` - Handles multi-location switching

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and workflow.

## Documentation

- Architecture docs: See `.md` files in root directory
- Data models: `USERDEFAULTS_DATA_MODEL.md`, `TapResolverDataStructures.md`
- Function reference: `TapResolver_Function_Reference.md`

## License

[Add your license here]

