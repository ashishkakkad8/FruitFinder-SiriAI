import Foundation

struct Fruit: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let emoji: String
    let details: String
    let aliases: [String]
}

enum FruitCatalog {
    static let all: [Fruit] = [
        Fruit(name: "Apple", emoji: "🍎", details: "A crisp fruit that comes in red, green, and yellow varieties.", aliases: ["apple", "apples"]),
        Fruit(name: "Banana", emoji: "🍌", details: "A soft, sweet fruit with a yellow peel.", aliases: ["banana", "bananas"]),
        Fruit(name: "Mango", emoji: "🥭", details: "A sweet tropical fruit with juicy yellow-orange flesh.", aliases: ["mango", "mangoes", "mangos"]),
        Fruit(name: "Orange", emoji: "🍊", details: "A citrus fruit with juicy segments and a bright orange peel.", aliases: ["orange", "oranges"]),
        Fruit(name: "Strawberry", emoji: "🍓", details: "A red berry with small seeds on the outside.", aliases: ["strawberry", "strawberries"]),
        Fruit(name: "Watermelon", emoji: "🍉", details: "A large refreshing fruit with juicy pink or red flesh.", aliases: ["watermelon", "watermelons"]),
        Fruit(name: "Pineapple", emoji: "🍍", details: "A tropical fruit with a spiky skin and sweet yellow flesh.", aliases: ["pineapple", "pineapples"]),
        Fruit(name: "Kiwi", emoji: "🥝", details: "A small fruit with fuzzy brown skin and bright green flesh.", aliases: ["kiwi", "kiwis"])
    ]

    static func search(_ query: String) -> [Fruit] {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedQuery.isEmpty else {
            return all
        }

        let words = normalizedQuery
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map(String.init)
            .filter { !$0.isEmpty }

        return all.filter { fruit in
            let searchableText = ([fruit.name, fruit.details] + fruit.aliases)
                .joined(separator: " ")
                .lowercased()

            return words.allSatisfy { searchableText.contains($0) }
        }
    }
}
