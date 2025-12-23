import Foundation
import Combine

final class LocationManager: ObservableObject {
    @Published var currentLocationID: String
    @Published var showLocationMenu: Bool = true  // Start at Location Menu

    private var bag = Set<AnyCancellable>()

    init() {
        let last = UserDefaults.standard.string(forKey: "locations.lastOpened.v1") ?? "home"
        self.currentLocationID = last

        // Keep PersistenceContext aligned (no UX change now; enables smooth switching later).
        $currentLocationID
            .removeDuplicates()
            .sink { id in
                PersistenceContext.shared.locationID = id
                UserDefaults.standard.set(id, forKey: "locations.lastOpened.v1")
                // Defer notification to next runloop to avoid "Publishing changes from within view updates"
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .locationDidChange, object: nil)
                }
            }
            .store(in: &bag)
    }

    func setCurrentLocation(_ id: String) {
        currentLocationID = id
    }
}
