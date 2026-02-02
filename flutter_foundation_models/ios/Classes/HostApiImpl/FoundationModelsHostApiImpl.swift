import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

class FoundationModelsHostApiImpl: FoundationModelsHostApi {
    #if canImport(FoundationModels)
    private var sessions = [String: LanguageModelSession]()
    private var activeStreams = [String: Task<Void, Never>]()
    #endif

    private var flutterApi: FoundationModelsFlutterApi?

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = FoundationModelsFlutterApi(binaryMessenger: binaryMessenger)
    }

    func isAvailable() throws -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }

    func createSession(
        tools: [ToolDefinitionMessage],
        instructions: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func destroySession(
        sessionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func respondTo(
        sessionId: String,
        prompt: String,
        options: GenerationOptionsMessage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func respondToWithSchema(
        sessionId: String,
        prompt: String,
        schema: [String?: Any?],
        includeSchemaInPrompt: Bool,
        options: GenerationOptionsMessage?,
        completion: @escaping (Result<[String?: Any?], Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func streamResponseToWithSchema(
        sessionId: String,
        prompt: String,
        schema: [String?: Any?],
        includeSchemaInPrompt: Bool,
        options: GenerationOptionsMessage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
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
                let generationOptions = convertOptions(options)

                let streamId = UUID().uuidString

                let task = Task {
                    do {
                        let stream = session.streamResponse(
                            to: prompt,
                            schema: generationSchema,
                            includeSchemaInPrompt: includeSchemaInPrompt,
                            options: generationOptions
                        )

                        var finalContent: [String?: Any?]? = nil

                        for try await snapshot in stream {
                            // Check if task was cancelled
                            if Task.isCancelled { break }

                            // Convert rawContent to dictionary
                            let jsonData = snapshot.rawContent.jsonString.data(using: .utf8)!
                            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any?] {
                                let mappedContent = jsonDict.mapToOptionalKeys()
                                finalContent = mappedContent

                                // Send snapshot to Flutter
                                await MainActor.run {
                                    self.flutterApi?.onStreamSnapshot(
                                        streamId: streamId,
                                        partialContent: mappedContent
                                    ) { _ in }
                                }
                            }
                        }

                        // Stream completed
                        if !Task.isCancelled, let content = finalContent {
                            await MainActor.run {
                                self.flutterApi?.onStreamComplete(
                                    streamId: streamId,
                                    finalContent: content
                                ) { _ in }
                            }
                        }
                    } catch {
                        if !Task.isCancelled {
                            await MainActor.run {
                                self.flutterApi?.onStreamError(
                                    streamId: streamId,
                                    errorCode: "STREAM_ERROR",
                                    errorMessage: error.localizedDescription
                                ) { _ in }
                            }
                        }
                    }

                    // Clean up
                    self.activeStreams.removeValue(forKey: streamId)
                }

                activeStreams[streamId] = task
                completion(.success(streamId))

            } catch {
                completion(.failure(PigeonError(
                    code: "SCHEMA_ERROR",
                    message: "Failed to parse generation schema: \(error.localizedDescription)",
                    details: nil
                )))
            }
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func cancelStream(
        streamId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let task = activeStreams[streamId] {
                task.cancel()
                activeStreams.removeValue(forKey: streamId)
            }
            completion(.success(()))
            return
        }
        #endif
        completion(.success(()))
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
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
    #endif
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
