import FoundationModels

struct FlutterTool: Tool {
    let sessionId: String
    let name: String
    let description: String
    let schema: [String: any Sendable]
    let parameters: GenerationSchema

    init(
        sessionId: String,
        name: String,
        description: String,
        schema: [String: Any],
        parameters: GenerationSchema
    ) {
        self.sessionId = sessionId
        self.name = name
        self.description = description
        self.schema = schema
        self.parameters = parameters
    }

    typealias Arguments = GeneratedContent

    func call(arguments: GeneratedContent) async throws -> ToolOutput {
        let content = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            do {
                LanguageModelSessionApi.shared.toolCall(
                    tool: self,
                    arguments: try arguments.toJson(with: schema),
                    completion: { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let result {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: NSError(domain: "UnexpectedResult", code: -1, userInfo: nil))
                        }
                    }
                )
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        return ToolOutput(
            GeneratedContent.fromJson(content)
        )
    }
}
