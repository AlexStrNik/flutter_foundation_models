//
//  GeneratedContent+ToJson.swift
//  Pods
//
//  Created by Aleksandr Strizhnev on 19.06.2025.
//

import FoundationModels

private typealias JSON = Any
private typealias JSONObject = [String: JSON]

extension GeneratedContent {
    func toJson(
        with schema: [String: Any]
    ) throws -> Any {
        guard let root = schema["root"] as? JSONObject else {
            fatalError("[GeneratedContent] Missing root in schema")
        }
        guard let dependencies = schema["dependencies"] as? [JSONObject] else {
            fatalError("[GeneratedContent] Missing dependencies in schema")
        }
        
        return try toJsonWithDynamicSchema(root)
    }
    
    fileprivate func toJsonWithDynamicSchema(
        _ schema: JSONObject
    ) throws -> Any {
        guard let kind = schema["kind"] as? String else {
            fatalError("[GeneratedContent] Missing kind in schema")
        }

        switch kind {
        case "ValueGenerationSchema":
            return try valueToJson(with: schema)
        case "ArrayGenerationSchema":
            return try arrayToJson(with: schema)
        case "DictionaryGenerationSchema":
            return try dictionaryToJson(with: schema)
        case "AnyOfGenerationSchema":
            return try anyOfToJson(with: schema)
        case "AnyOfStringsGenerationSchema":
            return try anyOfStringsToJson(with: schema)
        case "StructGenerationSchema":
            return try structToJson(with: schema)
        default:
            fatalError("[GeneratedContent] Unknown schema kind: \(kind)")
        }
    }

    fileprivate func valueToJson(
        with schema: JSONObject
    ) throws -> Any {
        guard let typeName = schema["type"] as? String else {
            fatalError("[GeneratedContent] Missing type in ValueGenerationSchema")
        }

        switch typeName {
        case "String":
            return try self.value(String.self)
        case "Int":
            return try self.value(Int.self)
        case "Double":
            return try self.value(Double.self)
        case "Bool":
            return try self.value(Bool.self)
        default:
            fatalError("[GeneratedContent] Unknown type in ValueGenerationSchema: \(typeName)")
        }
    }

    fileprivate func arrayToJson(
        with schema: JSONObject
    ) throws -> [JSON] {
        guard let elementSchema = schema["arrayOf"] as? JSONObject else {
            fatalError("[GeneratedContent] Missing arrayOf in ArrayGenerationSchema")
        }

        return try self.elements().map {
            try $0.toJsonWithDynamicSchema(elementSchema)
        }
    }

    fileprivate func dictionaryToJson(
        with schema: JSONObject
    ) throws -> [String: Any] {
        guard let valueSchema = schema["dictionaryOf"] as? JSONObject else {
            fatalError("[GeneratedContent] Missing dictionaryOf in DictionaryGenerationSchema")
        }

        let properties = try self.properties()
        var result = [String: Any]()

        for (key, content) in properties {
            result[key] = try content.toJsonWithDynamicSchema(valueSchema)
        }

        return result
    }

    fileprivate func anyOfToJson(
        with schema: JSONObject
    ) throws -> Any {
        guard let variantsSchemas = schema["anyOf"] as? [JSONObject] else {
            fatalError("[GeneratedContent] Missing anyOf in AnyOfGenerationSchema")
        }

        for variantSchema in variantsSchemas {
            do {
                return try self.toJsonWithDynamicSchema(variantSchema)
            } catch {
                continue
            }
        }

        fatalError("[GeneratedContent] None of the variants of AnyOfGenerationSchema matched")
    }

    fileprivate func anyOfStringsToJson(
        with schema: JSONObject
    ) throws -> Any {
        return try self.value(String.self)
    }

    fileprivate func structToJson(
        with schema: JSONObject
    ) throws -> [String: Any] {
        guard let propertiesSchema = schema["properties"] as? [JSONObject] else {
            fatalError("[GeneratedContent] Missing properties in StructGenerationSchema")
        }

        let contentProperties = try self.properties()
        var result = [String: Any]()

        for propertySchema in propertiesSchema {
            guard let propertyName = propertySchema["name"] as? String,
                let propertySchemaObj = propertySchema["schema"] as? JSONObject,
                let isOptional = propertySchema["isOptional"] as? Bool
            else {
                continue
            }

            if let propertyContent = contentProperties[propertyName] {
                do {
                    result[propertyName] = try propertyContent.toJsonWithDynamicSchema(propertySchemaObj)
                } catch {
                    if isOptional {
                        continue
                    } else {
                        fatalError(
                            "[GeneratedContent] Missing properties in StructGenerationSchema")
                    }
                }
            } else {
                if !isOptional {
                    fatalError("[GeneratedContent] Missing properties in StructGenerationSchema")
                }
            }
        }

        return result
    }
}
