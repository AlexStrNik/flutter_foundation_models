#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(iOS 26.0, *)
struct FlutterTool: Tool {
    let sessionId: String
    let name: String
    let description: String
    let parameters: GenerationSchema
    let flutterApi: FoundationModelsFlutterApi

    init(
        sessionId: String,
        toolDefinition: ToolDefinitionMessage,
        flutterApi: FoundationModelsFlutterApi
    ) throws {
        self.sessionId = sessionId
        self.name = toolDefinition.name
        self.description = toolDefinition.description
        self.flutterApi = flutterApi

        let params = toolDefinition.parameters.compactMapKeys()
        self.parameters = try GenerationSchema.fromJson(params)
    }

    typealias Output = GeneratedContent
    typealias Arguments = GeneratedContent

    func call(arguments: GeneratedContent) async throws -> Output {
        let argumentsJson = try JSONSerialization.jsonObject(
            with: arguments.jsonString.data(using: .utf8)!
        )

        let content = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            let args = (argumentsJson as? [String: Any?])?.mapToOptionalKeys() ?? [:]

            flutterApi.invokeTool(
                sessionId: sessionId,
                toolName: name,
                arguments: args
            ) { result in
                switch result {
                case .success(let value):
                    let cleanedValue = value.compactMapKeys()
                    continuation.resume(returning: cleanedValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        let json = try! JSONSerialization.data(withJSONObject: content, options: [])
        let jsonString = String(data: json, encoding: .utf8)!

        return try Output(json: jsonString)
    }
}

private extension Dictionary where Key == String?, Value == Any? {
    func compactMapKeys() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            if let key = key, let value = value {
                result[key] = value
            }
        }
        return result
    }
}

private extension Dictionary where Key == String, Value == Any? {
    func mapToOptionalKeys() -> [String?: Any?] {
        var result: [String?: Any?] = [:]
        for (key, value) in self {
            result[key] = value
        }
        return result
    }
}
#endif
