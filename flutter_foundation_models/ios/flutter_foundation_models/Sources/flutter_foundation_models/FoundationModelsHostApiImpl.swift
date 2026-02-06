import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, *)
final class ModelStorage {
    static let shared = ModelStorage()

    private init() {}

    var adapters = [String: SystemLanguageModel.Adapter]()
    var models = [String: SystemLanguageModel]()
    var sessions = [String: LanguageModelSession]()
    var activeStreams = [String: Task<Void, Never>]()
}
#endif

class FoundationModelsHostApiImpl: FoundationModelsHostApi {
    private var flutterApi: FoundationModelsFlutterApi?

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = FoundationModelsFlutterApi(binaryMessenger: binaryMessenger)
    }

    func isAvailable() throws -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    func getModelAvailability() throws -> ModelAvailabilityMessage {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return ModelAvailabilityMessage(isAvailable: true, unavailableReason: nil)
            case .unavailable(let reason):
                return ModelAvailabilityMessage(isAvailable: false, unavailableReason: "\(reason)")
            @unknown default:
                return ModelAvailabilityMessage(isAvailable: false, unavailableReason: "Unknown availability status")
            }
        }
        #endif
        return ModelAvailabilityMessage(isAvailable: false, unavailableReason: "Foundation Models API is not available on this device")
    }

    func createAdapter(
        name: String?,
        assetPath: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let adapterId = UUID().uuidString
                let adapter: SystemLanguageModel.Adapter

                if let assetPath = assetPath {
                    // Resolve Flutter asset path to file URL
                    let key = FlutterDartProject.lookupKey(forAsset: assetPath)
                    guard let bundlePath = Bundle.main.path(forResource: key, ofType: nil) else {
                        completion(.failure(PigeonError(
                            code: "ASSET_NOT_FOUND",
                            message: "Asset not found: \(assetPath)",
                            details: nil
                        )))
                        return
                    }
                    let fileURL = URL(fileURLWithPath: bundlePath)
                    adapter = try SystemLanguageModel.Adapter(fileURL: fileURL)
                } else if let name = name {
                    adapter = try SystemLanguageModel.Adapter(name: name)
                } else {
                    completion(.failure(PigeonError(
                        code: "INVALID_ARGUMENTS",
                        message: "Either name or assetPath must be provided",
                        details: nil
                    )))
                    return
                }

                ModelStorage.shared.adapters[adapterId] = adapter
                completion(.success(adapterId))
            } catch {
                completion(.failure(PigeonError(
                    code: "CREATE_ADAPTER_ERROR",
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

    func destroyAdapter(
        adapterId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            ModelStorage.shared.adapters.removeValue(forKey: adapterId)
            completion(.success(()))
            return
        }
        #endif
        completion(.success(()))
    }

    func createModel(
        configuration: ModelConfigurationMessage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let modelId = UUID().uuidString

            // Determine guardrails
            let guardrails: SystemLanguageModel.Guardrails
            if let guardrailsType = configuration?.guardrails {
                guardrails = switch guardrailsType {
                case .defaultGuardrails:
                    .default
                case .permissiveContentTransformations:
                    .permissiveContentTransformations
                }
            } else {
                guardrails = .default
            }

            if let adapterId = configuration?.adapterId {
                // Create with adapter from adapters map
                guard let adapter = ModelStorage.shared.adapters[adapterId] else {
                    completion(.failure(PigeonError(
                        code: "ADAPTER_NOT_FOUND",
                        message: "Adapter \(adapterId) not found",
                        details: nil
                    )))
                    return
                }
                ModelStorage.shared.models[modelId] = SystemLanguageModel(adapter: adapter, guardrails: guardrails)
            } else {
                // Create with useCase
                let useCase: SystemLanguageModel.UseCase
                if let useCaseType = configuration?.useCase {
                    useCase = switch useCaseType {
                    case .general:
                        .general
                    case .contentTagging:
                        .contentTagging
                    }
                } else {
                    useCase = .general
                }
                ModelStorage.shared.models[modelId] = SystemLanguageModel(useCase: useCase, guardrails: guardrails)
            }
            completion(.success(modelId))
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func destroyModel(
        modelId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            ModelStorage.shared.models.removeValue(forKey: modelId)
            completion(.success(()))
            return
        }
        #endif
        completion(.success(()))
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func getModel(_ modelId: String) throws -> SystemLanguageModel {
        if modelId == "default" {
            return SystemLanguageModel.default
        }
        guard let model = ModelStorage.shared.models[modelId] else {
            throw PigeonError(code: "MODEL_NOT_FOUND", message: "Model \(modelId) not found", details: nil)
        }
        return model
    }
    #endif

    func createSession(
        modelId: String,
        tools: [ToolDefinitionMessage],
        instructions: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let model = try getModel(modelId)
                let sessionId = UUID().uuidString
                let flutterTools = try tools.map { tool -> FlutterTool in
                    try FlutterTool(
                        sessionId: sessionId,
                        toolDefinition: tool,
                        flutterApi: flutterApi!
                    )
                }

                if let instructions = instructions {
                    ModelStorage.shared.sessions[sessionId] = LanguageModelSession(model: model, tools: flutterTools, instructions: instructions)
                } else {
                    ModelStorage.shared.sessions[sessionId] = LanguageModelSession(model: model, tools: flutterTools)
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

    func createSessionWithTranscript(
        modelId: String,
        tools: [ToolDefinitionMessage],
        transcriptJson: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let model = try getModel(modelId)
                let sessionId = UUID().uuidString
                let flutterTools = try tools.map { tool -> FlutterTool in
                    try FlutterTool(
                        sessionId: sessionId,
                        toolDefinition: tool,
                        flutterApi: flutterApi!
                    )
                }

                guard let jsonData = transcriptJson.data(using: .utf8) else {
                    throw PigeonError(code: "INVALID_JSON", message: "Invalid transcript JSON", details: nil)
                }
                let nativeTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
                ModelStorage.shared.sessions[sessionId] = LanguageModelSession(model: model, tools: flutterTools, transcript: nativeTranscript)
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
            guard ModelStorage.shared.sessions[sessionId] != nil else {
                completion(.failure(PigeonError(
                    code: "SESSION_NOT_FOUND",
                    message: "Session with id \(sessionId) not found",
                    details: nil
                )))
                return
            }

            ModelStorage.shared.sessions.removeValue(forKey: sessionId)
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

    func getSessionTranscript(
        sessionId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
                completion(.failure(PigeonError(
                    code: "SESSION_NOT_FOUND",
                    message: "Session with id \(sessionId) not found",
                    details: nil
                )))
                return
            }

            do {
                let jsonData = try JSONEncoder().encode(session.transcript)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    throw PigeonError(code: "ENCODE_ERROR", message: "Failed to encode transcript", details: nil)
                }
                completion(.success(jsonString))
            } catch {
                completion(.failure(PigeonError(
                    code: "TRANSCRIPT_ERROR",
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

    func isSessionResponding(
        sessionId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
                completion(.failure(PigeonError(
                    code: "SESSION_NOT_FOUND",
                    message: "Session with id \(sessionId) not found",
                    details: nil
                )))
                return
            }

            completion(.success(session.isResponding))
            return
        }
        #endif
        completion(.failure(PigeonError(
            code: "UNAVAILABLE",
            message: "Foundation Models API is not available on this device",
            details: nil
        )))
    }

    func prewarmSession(
        sessionId: String,
        promptPrefix: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
                completion(.failure(PigeonError(
                    code: "SESSION_NOT_FOUND",
                    message: "Session with id \(sessionId) not found",
                    details: nil
                )))
                return
            }

            if let prefix = promptPrefix {
                session.prewarm(promptPrefix: Prompt(prefix))
            } else {
                session.prewarm()
            }
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
        completion: @escaping (Result<TextResponseMessage, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
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
                    let transcriptJson = encodeTranscriptEntries(Array(result.transcriptEntries))
                    completion(.success(TextResponseMessage(
                        content: result.content,
                        transcriptJson: transcriptJson
                    )))
                } catch {
                    completion(.failure(mapGenerationError(error)))
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

    func streamResponseTo(
        sessionId: String,
        prompt: String,
        options: GenerationOptionsMessage?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
                completion(.failure(PigeonError(
                    code: "SESSION_NOT_FOUND",
                    message: "Session with id \(sessionId) not found",
                    details: nil
                )))
                return
            }

            let generationOptions = convertOptions(options)
            let streamId = UUID().uuidString

            let task = Task {
                do {
                    let stream = session.streamResponse(to: prompt, options: generationOptions)

                    var finalText = ""

                    for try await snapshot in stream {
                        if Task.isCancelled { break }

                        finalText = snapshot.content

                        await MainActor.run {
                            self.flutterApi?.onTextStreamUpdate(
                                streamId: streamId,
                                text: snapshot.content
                            ) { _ in }
                        }
                    }

                    if !Task.isCancelled {
                        let response = try await stream.collect()
                        let transcriptJson = self.encodeTranscriptEntries(Array(response.transcriptEntries))
                        await MainActor.run {
                            self.flutterApi?.onTextStreamComplete(
                                streamId: streamId,
                                finalText: response.content,
                                transcriptJson: transcriptJson
                            ) { _ in }
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        let (errorCode, errorMessage) = self.extractErrorInfo(error)
                        await MainActor.run {
                            self.flutterApi?.onStreamError(
                                streamId: streamId,
                                errorCode: errorCode,
                                errorMessage: errorMessage
                            ) { _ in }
                        }
                    }
                }

                ModelStorage.shared.activeStreams.removeValue(forKey: streamId)
            }

            ModelStorage.shared.activeStreams[streamId] = task
            completion(.success(streamId))
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
        completion: @escaping (Result<StructuredResponseMessage, Error>) -> Void
    ) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = ModelStorage.shared.sessions[sessionId] else {
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
                        let rawContentJson = result.rawContent.jsonString
                        let jsonData = result.content.jsonString.data(using: .utf8)!
                        let resultJson = try JSONSerialization.jsonObject(with: jsonData)
                        let transcriptJson = encodeTranscriptEntries(Array(result.transcriptEntries))

                        if let resultDict = resultJson as? [String: Any?] {
                            let mappedResult = resultDict.mapToOptionalKeys()
                            completion(.success(StructuredResponseMessage(
                                content: mappedResult,
                                rawContent: rawContentJson,
                                transcriptJson: transcriptJson
                            )))
                        } else {
                            completion(.failure(PigeonError(
                                code: "INVALID_RESPONSE",
                                message: "Response is not a valid dictionary",
                                details: nil
                            )))
                        }
                    } catch {
                        completion(.failure(mapGenerationError(error)))
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
            guard let session = ModelStorage.shared.sessions[sessionId] else {
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

                        // Stream completed - collect final response with transcript entries
                        if !Task.isCancelled {
                            let response = try await stream.collect()
                            let rawContentJson = response.rawContent.jsonString
                            let transcriptJson = self.encodeTranscriptEntries(Array(response.transcriptEntries))

                            let jsonData = response.content.jsonString.data(using: .utf8)!
                            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any?] {
                                let mappedContent = jsonDict.mapToOptionalKeys()
                                await MainActor.run {
                                    self.flutterApi?.onStreamComplete(
                                        streamId: streamId,
                                        finalContent: mappedContent,
                                        rawContent: rawContentJson,
                                        transcriptJson: transcriptJson
                                    ) { _ in }
                                }
                            }
                        }
                    } catch {
                        if !Task.isCancelled {
                            let (errorCode, errorMessage) = self.extractErrorInfo(error)
                            await MainActor.run {
                                self.flutterApi?.onStreamError(
                                    streamId: streamId,
                                    errorCode: errorCode,
                                    errorMessage: errorMessage
                                ) { _ in }
                            }
                        }
                    }

                    // Clean up
                    ModelStorage.shared.activeStreams.removeValue(forKey: streamId)
                }

                ModelStorage.shared.activeStreams[streamId] = task
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
            if let task = ModelStorage.shared.activeStreams[streamId] {
                task.cancel()
                ModelStorage.shared.activeStreams.removeValue(forKey: streamId)
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

    @available(iOS 26.0, *)
    private func mapGenerationError(_ error: Error) -> PigeonError {
        if let generationError = error as? LanguageModelSession.GenerationError {
            let (errorCode, message, debugDescription) = mapGenerationErrorType(generationError)
            return PigeonError(
                code: errorCode,
                message: message,
                details: debugDescription
            )
        }
        return PigeonError(
            code: "unknown",
            message: error.localizedDescription,
            details: nil
        )
    }

    @available(iOS 26.0, *)
    private func mapGenerationErrorType(_ error: LanguageModelSession.GenerationError) -> (String, String, String?) {
        switch error {
        case .exceededContextWindowSize(let context):
            return ("exceededContextWindowSize", error.localizedDescription, context.debugDescription)
        case .assetsUnavailable(let context):
            return ("assetsUnavailable", error.localizedDescription, context.debugDescription)
        case .guardrailViolation(let context):
            return ("guardrailViolation", error.localizedDescription, context.debugDescription)
        case .unsupportedGuide(let context):
            return ("unsupportedGuide", error.localizedDescription, context.debugDescription)
        case .unsupportedLanguageOrLocale(let context):
            return ("unsupportedLanguageOrLocale", error.localizedDescription, context.debugDescription)
        case .decodingFailure(let context):
            return ("decodingFailure", error.localizedDescription, context.debugDescription)
        case .rateLimited(let context):
            return ("rateLimited", error.localizedDescription, context.debugDescription)
        case .concurrentRequests(let context):
            return ("concurrentRequests", error.localizedDescription, context.debugDescription)
        case .refusal(_, let context):
            return ("refusal", error.localizedDescription, context.debugDescription)
        @unknown default:
            return ("unknown", error.localizedDescription, nil)
        }
    }

    @available(iOS 26.0, *)
    private func extractErrorInfo(_ error: Error) -> (String, String) {
        if let generationError = error as? LanguageModelSession.GenerationError {
            let (errorCode, message, _) = mapGenerationErrorType(generationError)
            return (errorCode, message)
        }
        return ("unknown", error.localizedDescription)
    }

    @available(iOS 26.0, *)
    private func encodeTranscriptEntries(_ entries: [Transcript.Entry]) -> String {
        do {
            let transcript = Transcript(entries: entries)
            let jsonData = try JSONEncoder().encode(transcript)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
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
