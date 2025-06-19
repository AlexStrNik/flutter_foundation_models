import FoundationModels

extension GeneratedContent {
    static func fromJson(_ json: Any) -> GeneratedContent {
        if let stringValue = json as? String {
            return GeneratedContent(stringValue)
        } else if let intValue = json as? Int {
            return GeneratedContent(intValue)
        } else if let doubleValue = json as? Double {
            return GeneratedContent(doubleValue)
        } else if let boolValue = json as? Bool {
            return GeneratedContent(boolValue)
        } else if let arrayValue = json as? [Any] {
            return GeneratedContent(arrayValue.map { fromJson($0) })
        } else if let dictValue = json as? [String: Any] {
            var properties: [(String, any ConvertibleToGeneratedContent)] = []
            for (key, value) in dictValue {
                properties.append(
                    (key, GeneratedContent.fromJson(value))
                )
            }

            // https://developer.apple.com/forums/thread/788937
            let kvp = unsafeBitCast(
                DynamicKeyValuePairs(_elements: properties),
                to: KeyValuePairs<String, any ConvertibleToGeneratedContent>.self
            )
            return GeneratedContent(
                properties: kvp
            )
        } else {
            fatalError("[GeneratedContent] Unsupported JSON type: \(type(of: json))")
        }
    }
}

struct DynamicKeyValuePairs<K, V> {
    let _elements: [(K, V)]

    init(_elements: [(K, V)]) {
        self._elements = _elements
    }
}
