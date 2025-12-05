# Gesture System Rebuild Tracker

## Branch
`feature/gesture-rebuild`

## Status
- [ ] Milestone 0: Setup
- [ ] Milestone 1: Transform Store
- [ ] Milestone 2: Pan Gesture
- [ ] Milestone 3: Pinch/Rotate Bridge
- [ ] Milestone 4: Double-Tap Zoom
- [ ] Milestone 5: Overlay Pinch Guard
- [ ] Milestone 6: Cleanup
- [ ] Milestone 7: Integration Testing

---

## Files Modified

### REPLACED (new implementation)
| File | Status | Notes |
|------|--------|-------|
| `Transforms/MapTransformStore.swift` | ⬜ | Full replacement |
| `Transforms/PinchRotateCentroidBridge.swift` | ⬜ | Was NOP, now functional |

### MODIFIED (surgical changes)
| File | Struct/Function | Change | Status |
|------|-----------------|--------|--------|
| `UI/Map/MapContainer.swift` | `MapCanvas.body` | Gesture wiring | ⬜ |
| `UI/Overlays/BeaconOverlayDots.swift` | `DraggableDot.body` | Add isPinching guard | ⬜ |
| `UI/Overlays/MetricSquaresOverlay.swift` | `centerDragGesture` | Add isPinching guard | ⬜ |

### EVALUATED (may need changes)
| File | Outcome | Notes |
|------|---------|-------|
| `Transforms/GestureHandler.swift` | ⬜ | May be removed/reduced |
| `Transforms/TransformProcessor.swift` | ⬜ | Verify wiring still works |

### UNCHANGED (confirmed compatible)
| File | Reason |
|------|--------|
| `UI/Root/ContentView.swift` | No gesture code |
| `UI/Root/MapNavigationView.swift` | Only sets screenCenter (unchanged API) |
| `UI/Root/HUDContainer.swift` | Non-transformable layer |

---

## API Changes for AR Markers Branch

| Old | New | Notes |
|-----|-----|-------|
| — | `mapTransform.isPinching` | New published property |
| — | — | Method signatures unchanged |

---

## Testing Checklist

- [ ] Pan: smooth one-finger drag
- [ ] Pinch: zoom toward/away from fingers
- [ ] Rotate: spin around finger centroid
- [ ] Double-tap: zoom toward tap point
- [ ] Beacon dot drag: tracks correctly after zoom/rotate
- [ ] Metric square drag: tracks correctly after zoom/rotate
- [ ] Triangle overlay: renders correctly after transforms
- [ ] RSSI labels: position correctly after transforms