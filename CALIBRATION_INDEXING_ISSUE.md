# Calibration Indexing Issue

## Problem

Indexing of points during triangle patch calibration is alternatingly on or off. It's still hard to predict.

When photo reference for the wrong point is displayed, it is often an indicator of imminent failure.

## Status

**Partially Fixed** - Improvements made in `bad-indexing-and-ghosts-in-progress` branch:
- Added validation and logging to `getCurrentVertexID()`
- Fixed vertex advancement to use `triangleVertices` consistently
- Added bounds checking and auto-reset for out-of-bounds indices

However, the issue may still occur intermittently and requires further investigation.

## Related Files

- `TapResolver/State/ARCalibrationCoordinator.swift` - Vertex indexing logic
- `TapResolver/ARFoundation/ARViewWithOverlays.swift` - Photo reference display
- `TapResolver/ARFoundation/ARViewContainer.swift` - Marker cleanup

## Notes

- Photo reference mismatch is a symptom, not the root cause
- Indexing state can become inconsistent between `currentVertexIndex` and `triangleVertices`
- May be related to timing/race conditions during calibration state transitions

