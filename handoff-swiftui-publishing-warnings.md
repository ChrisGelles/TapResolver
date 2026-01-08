# Handoff Document: SwiftUI "Publishing Changes" Warnings

## The Warning

```
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
```

This warning appears **20 times** during app startup and location changes, not during survey marker operations.

---

## What It Means

SwiftUI has a rule: when it's in the middle of computing a view's `body`, you cannot modify `@Published` properties that would trigger another view update. Doing so causes a re-entrant update cycle — SwiftUI is trying to read state while you're simultaneously writing state.

**Simplified example of the anti-pattern:**

```swift
struct BadView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        Text(viewModel.text)
            .onAppear {
                // This might fire DURING body evaluation
                viewModel.updateText()  // ← Modifies @Published property
            }
    }
}
```

---

## When It Happens in TapResolver

From the Xcode log, the warnings cluster around:

1. **App launch** — Initial view hierarchy construction
2. **Location changes** — When switching between "home" and "museum"
3. **AR view presentation** — When entering AR mode

**Timing correlation from log:**

```
📖 [DATA_LOAD] locations.museum.BeaconLists_beacons_v1: 19 items
Publishing changes from within view updates is not allowed...
Publishing changes from within view updates is not allowed...
📍 MapPointStore: Location changed, reloading...
Publishing changes from within view updates is not allowed...
```

The warnings appear immediately after data loads and during store reloads.

---

## Likely Causes

### Hypothesis 1: Store Initialization During View Construction

If a store's `init()` method triggers `@Published` property changes, and that store is created as a `@StateObject` in a view, the publish happens during view construction.

**Pattern to look for:**

```swift
@MainActor
class SomeStore: ObservableObject {
    @Published var data: [Item] = []
    
    init() {
        loadData()  // ← If this sets self.data, it publishes during init
    }
    
    func loadData() {
        self.data = loadFromDisk()  // ← This triggers @Published
    }
}
```

**Fix:** Defer the load until after init:

```swift
init() {
    // Don't load here
}

func configure() {
    loadData()  // Called explicitly after view is constructed
}
```

Or use `Task`:

```swift
init() {
    Task { @MainActor in
        loadData()  // Deferred to next RunLoop cycle
    }
}
```

### Hypothesis 2: Notification Handlers Modifying State

If a `NotificationCenter` observer fires during view updates and modifies `@Published` state:

```swift
.onReceive(NotificationCenter.default.publisher(for: .locationDidChange)) { _ in
    store.reload()  // ← Modifies @Published properties
}
```

The `.onReceive` might fire during view body evaluation if the notification is posted synchronously from another view's update.

**Fix:** Wrap in `Task` to defer:

```swift
.onReceive(NotificationCenter.default.publisher(for: .locationDidChange)) { _ in
    Task { @MainActor in
        store.reload()
    }
}
```

### Hypothesis 3: Cascading @Published Updates

Store A's `@Published` change triggers Store B's update (via Combine or observation), which triggers Store C, etc. — all within a single view update cycle.

**Pattern:**

```swift
// In LocationManager
$currentLocationID
    .sink { id in
        mapPointStore.reload(for: id)  // ← Triggers @Published in MapPointStore
        surveyPointStore.setLocation(id)  // ← Triggers @Published in SurveyPointStore
    }
```

**Fix:** Break the synchronous chain with `Task` or `DispatchQueue.main.async`.

### Hypothesis 4: @EnvironmentObject Access Triggering Lazy Init

If an `@EnvironmentObject` is accessed for the first time during view body evaluation, and its init loads data synchronously, the publish happens during body.

---

## Diagnostic Approach

### Step 1: Add Timing Logs

Add print statements at the start of each store's `init()`:

```swift
init() {
    print("🔵 [INIT_TRACE] SomeStore.init() START")
    // ... existing code ...
    print("🔵 [INIT_TRACE] SomeStore.init() END")
}
```

### Step 2: Add @Published Mutation Logs

Temporarily add `willSet` observers:

```swift
@Published var data: [Item] = [] {
    willSet {
        print("🟡 [PUBLISH_TRACE] SomeStore.data willSet, count: \(newValue.count)")
    }
}
```

### Step 3: Correlate with Warning

Run the app, watch for:

```
🔵 [INIT_TRACE] MapPointStore.init() START
🟡 [PUBLISH_TRACE] MapPointStore.mapPoints willSet, count: 70
Publishing changes from within view updates is not allowed...
🔵 [INIT_TRACE] MapPointStore.init() END
```

This tells you exactly which store and which property is the culprit.

---

## Stores to Investigate

Based on the log timing, these stores are active during the warning windows:

| Store | Initializes | Loads Data | @Published Properties |
|-------|-------------|------------|----------------------|
| `MapPointStore` | At app launch | Yes, in init | `mapPoints`, others |
| `SurveyPointStore` | At app launch | Yes, on location change | `surveyPoints` |
| `TrianglePatchStore` | At app launch | Yes, in init | `triangles` |
| `BeaconListsStore` | At app launch | Yes, in init | `beacons` |
| `LocationManager` | At app launch | Yes (from UserDefaults) | `currentLocationID` |
| `HUDPanelsState` | At app launch | Yes (from UserDefaults) | Multiple panel states |

---

## Potential Fixes (Once Root Cause Identified)

### Fix A: Defer Loading with Task

```swift
init() {
    Task { @MainActor in
        self.loadData()
    }
}
```

### Fix B: Use a "configured" Flag

```swift
@Published private(set) var isConfigured = false

init() {
    // Don't load
}

func configure() {
    guard !isConfigured else { return }
    loadData()
    isConfigured = true
}
```

Call `configure()` from `.onAppear` or `.task`.

### Fix C: Break Notification Chains

Wrap notification handlers in `Task`:

```swift
NotificationCenter.default.addObserver(forName: .locationDidChange, ...) { _ in
    Task { @MainActor in
        self.handleLocationChange()
    }
}
```

### Fix D: Use @MainActor.assumeIsolated Carefully

In some cases, wrapping synchronous code can help, but this is advanced and error-prone.

---

## Impact Assessment

**Current severity: Low**

The warnings indicate undefined behavior, but in practice:
- The app doesn't crash
- Data loads correctly
- UI renders properly

However:
- Performance could be degraded (redundant view recomputes)
- Edge case bugs could exist (race conditions, stale data)
- Future iOS versions might enforce this more strictly

**Recommendation:** Fix when time permits, not urgent.

---

## Related Code Locations

- `TapResolverApp.swift` — App entry point, creates StateObjects
- `MapPointStore.swift` — Large store with complex init
- `LocationManager.swift` — Publishes on location change
- `HUDPanelsState.swift` — Loads from UserDefaults in init
- Any `.onReceive` or `.onChange` modifiers that call store methods

---

## Summary

| What | Details |
|------|---------|
| Warning | "Publishing changes from within view updates is not allowed" |
| Frequency | 20 times per app launch |
| When | Startup, location changes |
| Root cause | Unknown — likely store init or notification handler |
| Severity | Low (cosmetic, no crashes) |
| Fix approach | Add tracing, identify culprit store, defer with Task |
