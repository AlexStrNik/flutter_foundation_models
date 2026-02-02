import Flutter
import Foundation
import FoundationModels

class FoundationModelsHostApiImpl: FoundationModelsHostApi {
    private var sessions = [String: LanguageModelSession]()
    private var flutterApi: FoundationModelsFlutterApi?

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = FoundationModelsFlutterApi(binaryMessenger: binaryMessenger)
    }

    func createSession(
        tools: [ToolDefinitionMessage],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            let sessionId = UUID().uuidString
            let flutterTools = try tools.map { tool -> FlutterTool in
                try FlutterTool(
                    sessionId: sessionId,
                    toolDefinition: tool,
                    flutterApi: flutterApi!
                )
            }

            sessions[sessionId] = LanguageModelSession(tools: flutterTools)
            completion(.success(sessionId))
        } catch {
            completion(.failure(PigeonError(
                code: "CREATE_SESSION_ERROR",
                message: error.localizedDescription,
                details: nil
            )))
        }
    }

    func destroySession(
        sessionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard sessions[sessionId] != nil else {
            completion(.failure(PigeonError(
                code: "SESSION_NOT_FOUND",
                message: "Session with id \(sessionId) not found",
                details: nil
            )))
            return
        }

        sessions.removeValue(forKey: sessionId)
        completion(.success(()))
    }

    func respond(
        sessionId: String,
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let session = sessions[sessionId] else {
            completion(.failure(PigeonError(
                code: "SESSION_NOT_FOUND",
                message: "Session with id \(sessionId) not found",
                details: nil
            )))
            return
        }

        Task {
            do {
                let result = try await session.respond(to: prompt)
                completion(.success(result.content))
            } catch {
                completion(.failure(PigeonError(
                    code: "RESPOND_ERROR",
                    message: error.localizedDescription,
                    details: nil
                )))
            }
        }
    }

    func respondWithSchema(
        sessionId: String,
        prompt: String,
        schema: [String?: Any?],
        completion: @escaping (Result<[String?: Any?], Error>) -> Void
    ) {
        guard let session = sessions[sessionId] else {
            completion(.failure(PigeonError(
                code: "SESSION_NOT_FOUND",
                message: "Session with id \(sessionId) not found",
                details: nil
            )))
            return
        }

        do {
            let schemaDict = schema.compactMapKeys()
            let generationSchema = try GenerationSchema.fromJson(schemaDict)

            Task {
                do {
                    let result = try await session.respond(to: prompt, schema: generationSchema)
                    let jsonData = result.content.jsonString.data(using: .utf8)!
                    let resultJson = try JSONSerialization.jsonObject(with: jsonData)

                    if let resultDict = resultJson as? [String: Any?] {
                        let mappedResult = resultDict.mapToOptionalKeys()
                        completion(.success(mappedResult))
                    } else {
                        completion(.failure(PigeonError(
                            code: "INVALID_RESPONSE",
                            message: "Response is not a valid dictionary",
                            details: nil
                        )))
                    }
                } catch {
                    completion(.failure(PigeonError(
                        code: "RESPOND_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    )))
                }
            }
        } catch {
            completion(.failure(PigeonError(
                code: "SCHEMA_ERROR",
                message: "Failed to parse generation schema: \(error.localizedDescription)",
                details: nil
            )))
        }
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
