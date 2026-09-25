import Foundation
import Combine

@MainActor
final class SearchRouter: ObservableObject {
    static let shared = SearchRouter()

    @Published private(set) var query = ""
    @Published var selectedFruit: Fruit?

    private init() {}

    func setQuery(_ query: String) {
        self.query = query
        self.selectedFruit = nil
    }

    func openFruit(id: String) {
        selectedFruit = FruitCatalog.all.first {
            $0.name.lowercased() == id.lowercased()
        }
        if let selectedFruit {
            query = selectedFruit.name
        }
    }
}
