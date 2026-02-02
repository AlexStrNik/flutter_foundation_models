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
        instructions: String?,
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

            if let instructions = instructions {
                sessions[sessionId] = LanguageModelSession(tools: flutterTools, instructions: instructions)
            } else {
                sessions[sessionId] = LanguageModelSession(tools: flutterTools)
            }
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

    func respondTo(
        sessionId: String,
        prompt: String,
        options: GenerationOptionsMessage?,
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

        let generationOptions = convertOptions(options)

        Task {
            do {
                let result = try await session.respond(to: prompt, options: generationOptions)
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

    func respondToWithSchema(
        sessionId: String,
        prompt: String,
        schema: [String?: Any?],
        includeSchemaInPrompt: Bool,
        options: GenerationOptionsMessage?,
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
            let schemaDict = schema.compactMapKeys { $0 }
            let generationSchema = try GenerationSchema.fromJson(schemaDict)
            let generationOptions = convertOptions(options)

            Task {
                do {
                    let result = try await session.respond(
                        to: prompt,
                        schema: generationSchema,
                        includeSchemaInPrompt: includeSchemaInPrompt,
                        options: generationOptions
                    )
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

    private func convertOptions(_ options: GenerationOptionsMessage?) -> GenerationOptions {
        guard let options = options else {
            return GenerationOptions()
        }

        var sampling: GenerationOptions.SamplingMode? = nil
        if let samplingMsg = options.sampling {
            switch samplingMsg.type {
            case .greedy:
                sampling = .greedy
            case .topK:
                if let k = samplingMsg.topK {
                    if let seed = samplingMsg.seed {
                        sampling = .random(top: Int(k), seed: UInt64(seed))
                    } else {
                        sampling = .random(top: Int(k))
                    }
                }
            case .topP:
                if let threshold = samplingMsg.probabilityThreshold {
                    if let seed = samplingMsg.seed {
                        sampling = .random(probabilityThreshold: threshold, seed: UInt64(seed))
                    } else {
                        sampling = .random(probabilityThreshold: threshold)
                    }
                }
            }
        }

        var maxTokens: Int? = nil
        if let max = options.maximumResponseTokens {
            maxTokens = Int(max)
        }

        return GenerationOptions(
            sampling: sampling,
            temperature: options.temperature,
            maximumResponseTokens: maxTokens
        )
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
