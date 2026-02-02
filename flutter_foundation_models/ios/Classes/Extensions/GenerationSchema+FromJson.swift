import Foundation
import FoundationModels

fileprivate typealias JSON = [String: Any]

enum GenerationSchemaError: Error {
    case missingField(String)
    case unknownKind(String)
    case unknownType(String)
    case invalidSchema(String)
}

extension GenerationSchema {
    static func fromJson(
        _ json: [String: Any]
    ) throws -> GenerationSchema {
        guard let root = json["root"] as? JSON else {
            throw GenerationSchemaError.missingField("root")
        }
        guard let dependencies = json["dependencies"] as? [JSON] else {
            throw GenerationSchemaError.missingField("dependencies")
        }

        return try GenerationSchema(
            root: DynamicGenerationSchema.fromJson(root),
            dependencies: dependencies.map { try DynamicGenerationSchema.fromJson($0) }
        )
    }
}

extension DynamicGenerationSchema {
    fileprivate static func fromJson(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let kind = json["kind"] as? String else {
            throw GenerationSchemaError.missingField("kind")
        }

        switch kind {
        case "ValueGenerationSchema":
            return try fromValueGenerationSchema(json)
        case "ArrayGenerationSchema":
            return try fromArrayGenerationSchema(json)
        case "DictionaryGenerationSchema":
            return try fromDictionaryGenerationSchema(json)
        case "AnyOfGenerationSchema":
            return try fromAnyOfGenerationSchema(json)
        case "AnyOfStringsGenerationSchema":
            return try fromAnyOfStringsGenerationSchema(json)
        case "StructGenerationSchema":
            return try fromStructGenerationSchema(json)
        default:
            throw GenerationSchemaError.unknownKind(kind)
        }
    }

    fileprivate static func fromValueGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let typeName = json["type"] as? String else {
            throw GenerationSchemaError.missingField("type for ValueGenerationSchema")
        }

        switch typeName {
        case "String":
            return DynamicGenerationSchema(type: String.self)
        case "Int":
            return DynamicGenerationSchema(type: Int.self)
        case "Double":
            return DynamicGenerationSchema(type: Double.self)
        case "Bool":
            return DynamicGenerationSchema(type: Bool.self)
        default:
            throw GenerationSchemaError.unknownType(typeName)
        }
    }

    fileprivate static func fromArrayGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let arrayOfJson = json["arrayOf"] as? JSON else {
            throw GenerationSchemaError.missingField("arrayOf for ArrayGenerationSchema")
        }

        let arrayOf = try fromJson(arrayOfJson)

        let minimumElements = json["minimumElements"] as? Int
        let maximumElements = json["maximumElements"] as? Int

        return DynamicGenerationSchema(
            arrayOf: arrayOf,
            minimumElements: minimumElements,
            maximumElements: maximumElements
        )
    }

    fileprivate static func fromDictionaryGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let dictionaryOfJson = json["dictionaryOf"] as? JSON else {
            throw GenerationSchemaError.missingField("dictionaryOf for DictionaryGenerationSchema")
        }
        let dictionaryOf = try fromJson(dictionaryOfJson)

        return DynamicGenerationSchema(dictionaryOf: dictionaryOf)
    }

    fileprivate static func fromAnyOfGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let name = json["name"] as? String else {
            throw GenerationSchemaError.missingField("name for AnyOfGenerationSchema")
        }

        guard let anyOfJsonArray = json["anyOf"] as? [JSON] else {
            throw GenerationSchemaError.missingField("anyOf for AnyOfGenerationSchema")
        }

        let description = json["description"] as? String
        let schemas: [DynamicGenerationSchema] = try anyOfJsonArray.map {
            try fromJson($0)
        }

        if schemas.isEmpty {
            throw GenerationSchemaError.invalidSchema("no valid schemas found in anyOf")
        }

        return DynamicGenerationSchema(
            name: name,
            description: description,
            anyOf: schemas
        )
    }

    fileprivate static func fromAnyOfStringsGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let name = json["name"] as? String else {
            throw GenerationSchemaError.missingField("name for AnyOfStringsGenerationSchema")
        }

        guard let anyOfStrings = json["anyOf"] as? [String] else {
            throw GenerationSchemaError.missingField("anyOf for AnyOfStringsGenerationSchema")
        }

        let description = json["description"] as? String

        return DynamicGenerationSchema(
            name: name,
            description: description,
            anyOf: anyOfStrings
        )
    }

    fileprivate static func fromStructGenerationSchema(
        _ json: JSON
    ) throws -> DynamicGenerationSchema {
        guard let name = json["name"] as? String else {
            throw GenerationSchemaError.missingField("name for StructGenerationSchema")
        }

        guard let propertiesJsonArray = json["properties"] as? [JSON] else {
            throw GenerationSchemaError.missingField("properties for StructGenerationSchema")
        }

        let description = json["description"] as? String
        let properties: [DynamicGenerationSchema.Property] = try propertiesJsonArray.map {
            try DynamicGenerationSchema.Property.fromJson($0)
        }

        if properties.isEmpty {
            throw GenerationSchemaError.invalidSchema("no valid properties found in struct")
        }

        return DynamicGenerationSchema(
            name: name,
            description: description,
            properties: properties
        )
    }
}

extension DynamicGenerationSchema.Property {
    fileprivate static func fromJson(
        _ json: JSON
    ) throws -> DynamicGenerationSchema.Property {
        guard let name: String = json["name"] as? String else {
            throw GenerationSchemaError.missingField("name for DynamicGenerationSchemaProperty")
        }
        guard let schemaJson = json["schema"] as? JSON else {
            throw GenerationSchemaError.missingField("schema for DynamicGenerationSchemaProperty")
        }
        let schema = try DynamicGenerationSchema.fromJson(schemaJson)

        let description = json["description"] as? String
        let isOptional = json["isOptional"] as? Bool ?? false

        return DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: schema,
            isOptional: isOptional
        )
    }
}
