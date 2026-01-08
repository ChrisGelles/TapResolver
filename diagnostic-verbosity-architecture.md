# Diagnostic Verbosity Control System

## Overview

A category-based logging control system that lets developers adjust diagnostic output verbosity at runtime. Built on the existing `FileLogger` infrastructure, extending the global `print()` pattern.

---

## Categories

| ID | Name | Description |
|----|------|-------------|
| `facing` | Facing | AR North calculation, compass rose, directional tracking |
| `ghosts` | Ghosts | Ghost marker prediction, placement, adjustment, grounding |
| `calibration` | Calibration | Zone corners, session transforms, bilinear setup |
| `baking` | Baking | Canonical position updates, distortion vectors, position history |
| `survey` | Survey | Dwell sessions, beacon sampling, sphere enter/exit |
| `triangles` | Triangles | Adjacent activation, vertex rotation, mesh operations |
| `arkit` | ARKit | Session lifecycle, tracking state, drift detection |
| `interaction` | Interaction | Taps, hit tests, gestures, haptics |
| `dataIO` | Data I/O | UserDefaults, encode/decode, save/load diagnostics |
| `purge` | Purge | Data cleanup, orphan removal, reset operations |

---

## Verbosity Levels

```swift
enum DiagnosticVerbosity: Int, Codable, CaseIterable {
    case off = 0      // Silent
    case brief = 1    // Summary at session end
    case verbose = 2  // Every occurrence
}
```

**Behavior:**

| Level | During Session | At Session End |
|-------|----------------|----------------|
| `verbose` | Print immediately | — |
| `brief` | Accumulate silently | Print summary |
| `off` | Discard | — |

---

## Core API

### Primary Function

```swift
/// Log a diagnostic message with category-based verbosity control.
///
/// - Parameters:
///   - category: The diagnostic category
///   - message: The log message (verbose mode only)
///   - briefData: Key-value pairs accumulated for brief-mode summary
///
/// Usage:
///   diagLog(.facing, "AR north angle: \(angle)°")
///   diagLog(.facing, "Computed heading", briefData: ["angle": angle])
///
func diagLog(
    _ category: DiagnosticCategory,
    _ message: String,
    briefData: [String: Any]? = nil
)
```

### Session Lifecycle

```swift
/// Call when a logical session ends (e.g., dwell complete, calibration done)
/// Flushes accumulated brief-mode data for all categories.
func diagLogFlush()

/// Call to flush a specific category only
func diagLogFlush(_ category: DiagnosticCategory)
```

---

## File Structure

```
TapResolver/
├── Utils/
│   ├── FileLogger.swift                 # Existing - unchanged
│   ├── DiagnosticLogger.swift           # NEW - diagLog(), flush, accumulator
│   └── DiagnosticVerbosityStore.swift   # NEW - UserDefaults persistence
└── UI/
    └── Debug/
        └── DiagnosticVerbosityPanel.swift  # NEW - Settings UI
```

---

## DiagnosticLogger.swift

```swift
import Foundation

// MARK: - Category Definition

enum DiagnosticCategory: String, CaseIterable, Identifiable {
    case facing       = "facing"
    case ghosts       = "ghosts"
    case calibration  = "calibration"
    case baking       = "baking"
    case survey       = "survey"
    case triangles    = "triangles"
    case arkit        = "arkit"
    case interaction  = "interaction"
    case dataIO       = "dataIO"
    case purge        = "purge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .facing:      return "Facing"
        case .ghosts:      return "Ghosts"
        case .calibration: return "Calibration"
        case .baking:      return "Baking"
        case .survey:      return "Survey"
        case .triangles:   return "Triangles"
        case .arkit:       return "ARKit"
        case .interaction: return "Interaction"
        case .dataIO:      return "Data I/O"
        case .purge:       return "Purge"
        }
    }
    
    var description: String {
        switch self {
        case .facing:      return "AR North calculation, compass rose, directional tracking"
        case .ghosts:      return "Ghost marker prediction, placement, adjustment"
        case .calibration: return "Zone corners, session transforms, bilinear setup"
        case .baking:      return "Canonical positions, distortion vectors, history"
        case .survey:      return "Dwell sessions, beacon sampling, sphere events"
        case .triangles:   return "Adjacent activation, vertex rotation, mesh ops"
        case .arkit:       return "Session lifecycle, tracking state, drift detection"
        case .interaction: return "Taps, hit tests, gestures, haptics"
        case .dataIO:      return "UserDefaults, encode/decode, save/load"
        case .purge:       return "Data cleanup, orphan removal, resets"
        }
    }
}

// MARK: - Verbosity Level

enum DiagnosticVerbosity: Int, Codable, CaseIterable {
    case off = 0
    case brief = 1
    case verbose = 2
    
    var displayName: String {
        switch self {
        case .off:     return "Off"
        case .brief:   return "Brief"
        case .verbose: return "Verbose"
        }
    }
}

// MARK: - Logger Singleton

final class DiagnosticLogger {
    static let shared = DiagnosticLogger()
    
    private let store = DiagnosticVerbosityStore.shared
    private var accumulators: [DiagnosticCategory: [[String: Any]]] = [:]
    private let queue = DispatchQueue(label: "com.tapresolver.diaglog")
    
    private init() {
        // Initialize empty accumulators for each category
        for category in DiagnosticCategory.allCases {
            accumulators[category] = []
        }
    }
    
    /// Log a diagnostic message
    func log(
        _ category: DiagnosticCategory,
        _ message: String,
        briefData: [String: Any]? = nil
    ) {
        let verbosity = store.verbosity(for: category)
        
        switch verbosity {
        case .off:
            return
            
        case .verbose:
            print("[\(category.rawValue.uppercased())] \(message)")
            
        case .brief:
            if let data = briefData {
                queue.sync {
                    accumulators[category]?.append(data)
                }
            }
        }
    }
    
    /// Flush accumulated brief-mode data for all categories
    func flush() {
        for category in DiagnosticCategory.allCases {
            flush(category)
        }
    }
    
    /// Flush accumulated brief-mode data for a specific category
    func flush(_ category: DiagnosticCategory) {
        guard store.verbosity(for: category) == .brief else { return }
        
        let data: [[String: Any]]
        queue.sync {
            data = accumulators[category] ?? []
            accumulators[category] = []
        }
        
        guard !data.isEmpty else { return }
        
        // Generate summary based on category
        let summary = summarize(category: category, data: data)
        print("📊 [\(category.rawValue.uppercased())_SUMMARY] \(summary)")
    }
    
    /// Generate a summary string from accumulated data
    private func summarize(category: DiagnosticCategory, data: [[String: Any]]) -> String {
        let count = data.count
        
        // Category-specific summaries can be added here
        // For now, generic summary
        if let lastAngle = data.last?["angle"] as? Double {
            return "\(count) samples, final: \(String(format: "%.1f", lastAngle))°"
        }
        
        return "\(count) samples recorded"
    }
}

// MARK: - Global Function

/// Primary diagnostic logging function
func diagLog(
    _ category: DiagnosticCategory,
    _ message: String,
    briefData: [String: Any]? = nil
) {
    DiagnosticLogger.shared.log(category, message, briefData: briefData)
}

/// Flush all category accumulators (call at session end)
func diagLogFlush() {
    DiagnosticLogger.shared.flush()
}

/// Flush specific category accumulator
func diagLogFlush(_ category: DiagnosticCategory) {
    DiagnosticLogger.shared.flush(category)
}
```

---

## DiagnosticVerbosityStore.swift

```swift
import Foundation

final class DiagnosticVerbosityStore: ObservableObject {
    static let shared = DiagnosticVerbosityStore()
    
    private let defaults = UserDefaults.standard
    private let keyPrefix = "diag.verbosity."
    
    /// Default verbosity for new categories
    private let defaultVerbosity: DiagnosticVerbosity = .verbose
    
    private init() {}
    
    /// Get verbosity level for a category
    func verbosity(for category: DiagnosticCategory) -> DiagnosticVerbosity {
        let key = keyPrefix + category.rawValue
        if defaults.object(forKey: key) != nil {
            let raw = defaults.integer(forKey: key)
            return DiagnosticVerbosity(rawValue: raw) ?? defaultVerbosity
        }
        return defaultVerbosity
    }
    
    /// Set verbosity level for a category
    func setVerbosity(_ verbosity: DiagnosticVerbosity, for category: DiagnosticCategory) {
        let key = keyPrefix + category.rawValue
        defaults.set(verbosity.rawValue, forKey: key)
        objectWillChange.send()
    }
    
    /// Reset all categories to default
    func resetAll() {
        for category in DiagnosticCategory.allCases {
            let key = keyPrefix + category.rawValue
            defaults.removeObject(forKey: key)
        }
        objectWillChange.send()
    }
}
```

---

## DiagnosticVerbosityPanel.swift

```swift
import SwiftUI

struct DiagnosticVerbosityPanel: View {
    @ObservedObject private var store = DiagnosticVerbosityStore.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DiagnosticCategory.allCases) { category in
                    CategoryRow(category: category, store: store)
                }
                
                Section {
                    Button("Reset All to Verbose") {
                        store.resetAll()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Diagnostic Verbosity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CategoryRow: View {
    let category: DiagnosticCategory
    @ObservedObject var store: DiagnosticVerbosityStore
    
    private var verbosity: DiagnosticVerbosity {
        store.verbosity(for: category)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.headline)
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: Binding(
                get: { verbosity },
                set: { store.setVerbosity($0, for: category) }
            )) {
                ForEach(DiagnosticVerbosity.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}
```

---

## Integration: DebugSettingsPanel

Add button after "Clear Log" in `HUDContainer.swift`:

```swift
// NEW: Diagnostic Verbosity button
Button {
    showDiagnosticVerbosity = true
} label: {
    VStack(spacing: 8) {
        Image(systemName: "slider.horizontal.3")
            .font(.system(size: 24))
        Text("Verbosity")
            .font(.system(size: 12, weight: .medium))
    }
    .foregroundColor(.primary)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
}
.buttonStyle(.plain)
.sheet(isPresented: $showDiagnosticVerbosity) {
    DiagnosticVerbosityPanel()
}
```

---

## Migration Strategy

**Phase 1: Infrastructure (This PR)**
- Create `DiagnosticLogger.swift`
- Create `DiagnosticVerbosityStore.swift`
- Create `DiagnosticVerbosityPanel.swift`
- Add Verbosity button to DebugSettingsPanel

**Phase 2+: Incremental Adoption**
- Replace noisy `print()` calls with `diagLog()` as encountered
- No bulk refactor — organic migration during feature work
- Priority: high-frequency logs like `[AR_NORTH]`, `[BILINEAR_EXTRAP]`

---

## Example Migration

**Before:**
```swift
print("🧭 [AR_NORTH] South=(\(sx), \(sz)) North=(\(nx), \(nz)) → AR north angle=\(angle)°")
```

**After:**
```swift
diagLog(.facing, "South=(\(sx), \(sz)) North=(\(nx), \(nz)) → angle=\(angle)°",
        briefData: ["angle": angle])
```

**Brief mode output (at session end):**
```
📊 [FACING_SUMMARY] 200 samples, final: -163.4°
```

---

## Notes

- `diagLog()` uses existing `print()` which routes through `FileLogger`
- Thread-safe via internal dispatch queue
- Categories can be added by extending the enum
- UI automatically picks up new categories via `CaseIterable`
