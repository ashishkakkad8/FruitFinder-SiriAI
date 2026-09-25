import AppIntents
import Foundation
import Vision
import VisualIntelligence
import VideoToolbox
import CoreGraphics
import ImageIO

@available(iOS 27.0, *)
struct FruitEntity: AppEntity, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let details: String

    static let defaultQuery = FruitEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Fruit")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(emoji) \(name)",
            subtitle: "\(details)",
            image: .init(systemName: "leaf.fill")
        )
    }

    init(fruit: Fruit) {
        self.id = fruit.name.lowercased()
        self.name = fruit.name
        self.emoji = fruit.emoji
        self.details = fruit.details
    }
}

@available(iOS 27.0, *)
struct FruitEntityQuery: EntityQuery {
    func entities(for identifiers: [FruitEntity.ID]) async throws -> [FruitEntity] {
        await FruitCatalog.all
            .filter { identifiers.contains($0.name.lowercased()) }
            .map(FruitEntity.init(fruit:))
    }

    func suggestedEntities() async throws -> [FruitEntity] {
        await FruitCatalog.all.map(FruitEntity.init(fruit:))
    }
}

@available(iOS 27.0, *)
struct FruitVisualSearchQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [FruitEntity] {
        // Fast path: Visual Intelligence labels.
        let labelMatches = await FruitCatalog.all.filter { fruit in
            fruit.aliases.contains { alias in
                input.labels.contains { label in
                    let normalizedLabel = label
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    return normalizedLabel == alias.lowercased()
                }
            }
        }

        if !labelMatches.isEmpty {
            return labelMatches.map(FruitEntity.init(fruit:))
        }

        // Robust path: inspect the captured pixel buffer with Vision.
        guard let pixelBuffer = input.pixelBuffer else {
            return []
        }

        let visionMatches = try await FruitVisionMatcher.classify(pixelBuffer: pixelBuffer)
        if !visionMatches.isEmpty {
            return visionMatches.map(FruitEntity.init(fruit:))
        }

        // Image-similarity fallback. This follows Apple's feature-print approach.
        return try await FruitFeaturePrintCatalog.shared.search(pixelBuffer: pixelBuffer)
    }
}

@available(iOS 27.0, *)
enum FruitVisionMatcher {
    static func classify(pixelBuffer: CVReadOnlyPixelBuffer) async throws -> [Fruit] {
        var cgImage: CGImage?

        _ = pixelBuffer.withUnsafeBuffer { buffer in
            VTCreateCGImageFromCVPixelBuffer(
                buffer,
                options: nil,
                imageOut: &cgImage
            )
        }

        guard let cgImage else {
            return []
        }

        let request = ClassifyImageRequest()
        let observations = try await request.perform(on: cgImage)
            .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.90) }
            .sorted { $0.confidence > $1.confidence }

        for observation in observations {
            let identifier = observation.identifier
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if let fruit = FruitCatalog.all.first(where: { fruit in
                fruit.aliases.contains { alias in
                    identifier.contains(alias.lowercased())
                }
            }) {
                return [fruit]
            }
        }

        return []
    }
}

@available(iOS 27.0, *)
actor FruitFeaturePrintCatalog {
    static let shared = FruitFeaturePrintCatalog()

    private struct Entry: Sendable {
        let fruit: FruitEntity
        let featurePrint: FeaturePrintObservation
    }

    private var entries: [Entry] = []
    private var prepared = false

    func search(pixelBuffer: CVReadOnlyPixelBuffer) async throws -> [FruitEntity] {
        if !prepared {
            await prepare()
        }

        guard !entries.isEmpty else {
            return []
        }

        var cgImage: CGImage?

        _ = pixelBuffer.withUnsafeBuffer { buffer in
            VTCreateCGImageFromCVPixelBuffer(
                buffer,
                options: nil,
                imageOut: &cgImage
            )
        }

        guard let cgImage else {
            return []
        }

        let request = GenerateImageFeaturePrintRequest()
        let queryPrint = try await request.perform(on: cgImage)

        let matches = try entries.compactMap { entry -> (FruitEntity, Double)? in
            let distance = try queryPrint.distance(to: entry.featurePrint)

            // Apple demonstrates a distance threshold for feature-print search.
            guard distance <= 1.25 else {
                return nil
            }

            return (entry.fruit, distance)
        }
        .sorted { lhs, rhs in
            lhs.1 < rhs.1
        }
        .prefix(5)
        .map { $0.0 }

        return matches
    }

    private func prepare() async {
        defer { prepared = true }

        let referenceNames: [(String, String, String)] = [
            ("AppleReference", "png", "apple")
        ]

        for (resourceName, fileExtension, fruitID) in referenceNames {
            guard let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: fileExtension
            ) else {
                continue
            }

            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
                  let fruit = await FruitCatalog.all.first(where: {
                      $0.name.lowercased() == fruitID
                  }) else {
                continue
            }

            do {
                let request = GenerateImageFeaturePrintRequest()
                let featurePrint = try await request.perform(on: cgImage)
                entries.append(
                    Entry(
                        fruit: FruitEntity(fruit: fruit),
                        featurePrint: featurePrint
                    )
                )
            } catch {
                continue
            }
        }
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct FruitSemanticContentSearchIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Fruit Finder"
    static let openAppWhenRun: Bool = true

    var semanticContent: SemanticContentDescriptor

    func perform() async throws -> some IntentResult {
        let matches = try await FruitVisualSearchQuery().values(for: semanticContent)

        if let fruit = matches.first {
            await SearchRouter.shared.openFruit(id: fruit.id)
        } else if let label = semanticContent.labels.first {
            await SearchRouter.shared.setQuery(label)
        }

        return .result()
    }
}

@available(iOS 27.0, *)
struct OpenFruitIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Fruit"

    @Parameter(title: "Fruit")
    var target: FruitEntity

    func perform() async throws -> some IntentResult {
        await SearchRouter.shared.openFruit(id: target.id)
        return .result()
    }
}
