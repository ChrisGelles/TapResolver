import Foundation
import Combine

final class LocationManager: ObservableObject {
    @Published var currentLocationID: String
    @Published var showLocationMenu: Bool = false

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
            }
            .store(in: &bag)
    }

    func setCurrentLocation(_ id: String) {
        currentLocationID = id
    }
}
