import FoundationModels

private typealias JSON = [String: Any]

extension FlutterTool {
    static func fromJson(
        _ json: [String: Any],
        sessionId: String
    ) throws -> FlutterTool {
        guard let name = json["name"] as? String else {
            fatalError("[FlutterTool] Missing name in json")
        }
        guard let description = json["description"] as? String else {
            fatalError("[FlutterTool] Missing description in json")
        }
        guard let parameters = json["parameters"] as? JSON else {
            fatalError("[FlutterTool] Missing parameters in json")
        }

        return FlutterTool(
            sessionId: sessionId,
            name: name,
            description: description,
            schema: parameters,
            parameters: try GenerationSchema.fromJson(parameters)
        )
    }
}
