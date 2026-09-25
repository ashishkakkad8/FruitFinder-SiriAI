import Foundation
import Combine

@MainActor
final class SearchRouter: ObservableObject {
    static let shared = SearchRouter()

    @Published private(set) var query = ""

    private init() {}

    func setQuery(_ query: String) {
        self.query = query
    }
}
