import Foundation
import CoreGraphics
import FoundationModels

@available(iOS 27.0, *)
enum FruitAIService {
    static func identifyFruit(in image: CGImage) async throws -> String {
        let model = SystemLanguageModel.default

        guard model.isAvailable else {
            throw FruitAIError.modelUnavailable
        }

        let session = LanguageModelSession(
            instructions: """
            You identify common fruits in photographs.
            Return only the common fruit name, such as Apple, Banana, Mango, Orange, Strawberry, Watermelon, Pineapple, or Kiwi.
            If the image does not clearly contain one of those fruits, return Unknown.
            Do not add explanations, punctuation, or confidence scores.
            """
        )

        let response = try await session.respond {
            "Identify the fruit in this image."
            Attachment(image)
        }

        return response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum FruitAIError: LocalizedError {
    case modelUnavailable
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence is not available on this device."
        case .invalidImage:
            return "The selected image could not be read."
        }
    }
}
