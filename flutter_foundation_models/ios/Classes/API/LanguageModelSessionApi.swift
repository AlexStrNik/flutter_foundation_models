import Flutter
import Foundation
import FoundationModels

class LanguageModelSessionApi: NSObject, FlutterPlugin {
    private var instances = [String: LanguageModelSession]()
    private var toolChannels = [String: FlutterMethodChannel]()
    
    private var registrar: FlutterPluginRegistrar?
    
    static let shared = LanguageModelSessionApi()
    
    override private init() {}
    
    static func register(
        with registrar: FlutterPluginRegistrar
    ) {
        let channel = FlutterMethodChannel(
            name: "flutter_foundation_models.LanguageModelSessionApi",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(shared, channel: channel)
        shared.registrar = registrar
    }
    
    public func toolCall(
        tool: FlutterTool,
        arguments: Any,
        completion: @escaping (Any?, NSError?) -> Void
    ) {
        guard let toolChannel = toolChannels[tool.sessionId] else {
            completion(
                nil,
                NSError(
                    domain: "LanguageModelSessionApi",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Session not found"]
                )
            )
            return
        }
        toolChannel.invokeMethod(
            tool.name,
            arguments: arguments,
            result: {
                completion($0, nil)
            }
        )
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard let args = call.arguments as? [String: Any],
                  let tools = args["tools"] as? [[String: Any]] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Missing or invalid arguments",
                        details: nil
                    )
                )
                return
            }
            
            do {
                result(
                    try handleInit(tools: tools)
                )
            }
            catch {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Missing or invalid arguments",
                        details: nil
                    )
                )
            }
            
        case "deinit":
            guard let args = call.arguments as? [String: Any],
                  let sessionId = args["sessionId"] as? String
            else {
                result(
                    FlutterError(
                        code: "INIT_ERROR",
                        message: "Failed to create a session",
                        details: nil
                    )
                )
                return
            }
            
            handleDeinit(
                sessionId: sessionId,
                completion: { error in
                    if let error = error {
                        result(
                            FlutterError(
                                code: "DEINIT_ERROR",
                                message: error.localizedDescription,
                                details: nil)
                        )
                    } else {
                        result(nil)
                    }
                }
            )
            
        case "respondWithSchema":
            guard let args = call.arguments as? [String: Any],
                  let sessionId = args["sessionId"] as? String,
                  let prompt = args["prompt"] as? String,
                  let schema = args["schema"] as? [String: Any]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Missing or invalid arguments",
                        details: nil
                    )
                )
                return
            }
            
            handleRespondWithSchema(
                sessionId: sessionId,
                prompt: prompt,
                schema: schema,
                completion: { response, error in
                    if let error = error {
                        result(
                            FlutterError(
                                code: "RESPOND_ERROR",
                                message: error.localizedDescription,
                                details: nil
                            )
                        )
                    } else if let response = response {
                        result(response)
                    } else {
                        result(
                            FlutterError(
                                code: "UNKNOWN_ERROR",
                                message: "Failed to generate response",
                                details: nil
                            )
                        )
                    }
                })
            
        case "respond":
            guard let args = call.arguments as? [String: Any],
                  let sessionId = args["sessionId"] as? String,
                  let prompt = args["prompt"] as? String
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Missing or invalid arguments",
                        details: nil
                    )
                )
                return
            }
            
            handleRespond(
                sessionId: sessionId,
                prompt: prompt,
                completion: { response, error in
                    if let error = error {
                        result(
                            FlutterError(
                                code: "RESPOND_ERROR",
                                message: error.localizedDescription,
                                details: nil
                            )
                        )
                    } else if let response = response {
                        result(response)
                    } else {
                        result(
                            FlutterError(
                                code: "UNKNOWN_ERROR",
                                message: "Failed to generate response",
                                details: nil
                            )
                        )
                    }
                })
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func handleInit(
        tools: [[String:Any]]
    ) throws -> String {
        let uuid = UUID().uuidString
        instances[uuid] = LanguageModelSession(
            tools: try tools.map {
                try FlutterTool.fromJson($0, sessionId: uuid)
            }
        )
        toolChannels[uuid] = FlutterMethodChannel(
            name: "flutter_foundation_models.ToolChannel.\(uuid)",
            binaryMessenger: registrar!.messenger()
        )
        return uuid
    }
    
    func handleDeinit(sessionId: String, completion: @escaping (Error?) -> Void) {
        guard instances[sessionId] != nil else {
            completion(
                NSError(
                    domain: "LanguageModelSessionApi",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Session not found"]
                )
            )
            return
        }
        
        instances.removeValue(forKey: sessionId)
        completion(nil)
    }
    
    func handleRespondWithSchema(
        sessionId: String,
        prompt: String,
        schema: [String: Any],
        completion: @escaping (Any?, Error?) -> Void
    ) {
        do {
            guard let session = instances[sessionId] else {
                completion(
                    nil,
                    NSError(
                        domain: "LanguageModelSessionApi",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Session not found"]
                    )
                )
                return
            }
            
            let generationSchema = try GenerationSchema.fromJson(schema)
            
            Task {
                do {
                    let result = try await session.respond(to: prompt, schema: generationSchema)
                    let resultJson = try result.content.toJson(with: schema)
                    
                    completion(resultJson, nil)
                } catch {
                    completion(
                        nil,
                        NSError(
                            domain: "LanguageModelSessionApi",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to generate repsonse"]
                        )
                    )
                }
            }
        } catch {
            completion(
                nil,
                NSError(
                    domain: "LanguageModelSessionApi",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create generation schema"]
                )
            )
        }
    }
    
    func handleRespond(
        sessionId: String,
        prompt: String,
        completion: @escaping (Any?, Error?) -> Void
    ) {
        guard let session = instances[sessionId] else {
            completion(
                nil,
                NSError(
                    domain: "LanguageModelSessionApi",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Session not found"]
                )
            )
            return
        }
        
        Task {
            do {
                let result = try await session.respond(to: prompt)
                
                completion(result.content, nil)
            } catch {
                print(error)
                completion(
                    nil,
                    NSError(
                        domain: "LanguageModelSessionApi",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to generate repsonse"]
                    )
                )
            }
        }
    }
}
