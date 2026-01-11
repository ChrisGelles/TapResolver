# TapResolver Session Handoff
**Date:** January 10, 2026  
**Status:** Ready for Phase 1 of Zone Groups Implementation

---

## What Just Got Fixed

### BeaconDotStore V2 Refactor ✅ COMPLETE

**Problem:** Split-brain architecture with `dots` array AND separate dictionaries (`elevations`, `locked`, `txPowerByID`, etc.) caused data loss. When dictionaries got wiped during location switch, `save()` would write default values.

**Solution:** Eliminated all dictionaries. Single source of truth: `@Published var dots: [BeaconDotV2]`

**Verified working:**
- `BeaconDotV2` struct holds all properties
- All getters read from `dots.first { ... }`
- All setters modify `dots[idx]` and call `save()`
- Old `Dot` struct deleted
- `BeaconOverlayDots.swift` updated to use new types

---

## What's Next: Zone Groups & SVG Import

### Architecture Document
**File:** `ZoneGroups-SVG-Import-Architecture-20260110.md` (in outputs)

Contains complete design for:
- `ZoneGroup` struct (new)
- Updated `Zone` struct (remove 4-corner limit, String IDs)
- SVG parser design
- MapPoint deduplication algorithm
- Triangle membership calculation
- Import/export flow

### Key Decisions Made

1. **Migration:** Delete existing 2 zones, fresh start
2. **UI:** Collapsible sections for zone groups
3. **Conflict resolution:** Hierarchical checks, favor import for shape updates
4. **Triangle membership UI:** Repurpose Swath Editor as Zone Editor
5. **MapPoint IDs:** Keep UUID for MapPoints, human-readable strings for Zones/ZoneGroups
6. **Deduplication threshold:** 0.5 meters

### Phase 1 Tasks (Data Model Foundation)

1. Create `ZoneGroup` struct in new file `State/ZoneGroup.swift`
2. Update `Zone` struct:
   - Change `id` from `UUID` to `String`
   - Change `cornerIDs: [UUID]` to `cornerMapPointIDs: [String]`
   - Remove 4-corner validation (`isValid` should be `>= 3`)
   - Add `groupID: String?`
   - Add `displayName: String`
3. Create `ZoneGroupStore` in new file `State/ZoneGroupStore.swift`
4. Update `ZoneStore`:
   - New persistence key `Zones_v2`
   - Migration from v1 (or just delete existing zones)
5. Add `Color+Hex` extension in `Utils/Color+Hex.swift`

### Files to Reference

From Cursor's investigation:
- `TapResolver/State/Zone.swift` - Current Zone struct
- `TapResolver/State/ZoneStore.swift` - Current persistence
- `TapResolver/State/MapPointStore.swift` - MapPoint and MapPointRole
- `TapResolver/Utils/SVGBuilder/SVGDocument.swift` - Existing SVG export

### Current Zone Struct (Must Update)

```swift
public struct Zone: Identifiable, Codable, Equatable {
    public let id: UUID                    // → Change to String
    public var name: String                // Keep, but add displayName
    public var cornerIDs: [UUID]           // → cornerMapPointIDs: [String]
    public var triangleIDs: [UUID]         // → memberTriangleIDs: [String]
    public var lastStartingCornerIndex: Int?
    public var isLocked: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    
    public var isValid: Bool {
        cornerIDs.count == 4               // → Change to >= 3
    }
}
```

### MapPointRole Already Has `.zoneCorner`

```swift
public enum MapPointRole: String, Codable, CaseIterable, Identifiable {
    case triangleEdge = "triangle_edge"
    case featureMarker = "feature_marker"
    case directionalNorth = "directional_north"
    case directionalSouth = "directional_south"
    case zoneCorner = "zone_corner"        // ← Already exists!
}
```

---

## Project Knowledge Files

The project has these knowledge files attached:
- `Previous_work_accomplished_with_Claude_Chat`
- `Cursor_as_a_Coding_Assistant`
- `Framing_instructions_to_Cursor`
- `Human-Focused_Coding_Helper_Rules`
- `TapResolver-20260106-1008.txt`

---

## Chris's Preferences (Important)

- **No ass-kissing** - Don't start with "You're absolutely right!"
- **Evidence over speculation** - Read code, trace data flow
- **Surgical changes** - Don't refactor unrelated code
- **Human synopsis first** - Explain approach before Cursor instructions
- **Cursor preamble required** - 4 critical constraints every time
- **MapPoints are atomic** - Everything references MapPoints, nothing stores raw coordinates
- **Single source of truth** - Learned the hard way with BeaconDotStore

---

## SVG File Reference

Chris uploaded: `museum-map-zones-2026-01-10-v03.svg`

Structure:
- 13 zone groups (e.g., `evolvingLife-zones`, `dynamicEarth-zones`)
- 47 zones total as `<polygon>` elements
- Colors defined in CSS `<defs>` block
- Human-readable IDs with spaces (e.g., `id="Dunk Theater"`)

---

## Opening Questions for Next Session

Likely topics:
1. "Show me the Phase 1 Cursor instructions"
2. "What's in the architecture doc?"
3. "Where did we leave off?"

The architecture doc has everything. Start by having successor read it.

---

## Token Note

This session exceeded safe limits (~220k+ tokens). Architecture doc and this handoff capture all critical context. Successor should have full runway.
