import AppIntents

@available(iOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct SearchFruitIntent: ShowInAppSearchResultsIntent {
    static let title: LocalizedStringResource = "Search Fruit Finder"
    static let searchScopes: [StringSearchScope] = [.general]

    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult {
        let searchTerm = criteria.term.trimmingCharacters(in: .whitespacesAndNewlines)

        await SearchRouter.shared.setQuery(searchTerm)

        return .result()
    }
}
