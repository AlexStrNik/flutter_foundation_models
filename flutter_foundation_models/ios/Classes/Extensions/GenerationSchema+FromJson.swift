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

        // Extract constraints from JSON
        let enumValues = json["enum"] as? [String]
        let pattern = json["pattern"] as? String
        let minimum = json["minimum"] as? NSNumber
        let maximum = json["maximum"] as? NSNumber

        switch typeName {
        case "String":
            var guides: [GenerationGuide<String>] = []

            // Handle enum constraint (constant or anyOf)
            if let values = enumValues {
                if values.count == 1 {
                    guides.append(.constant(values[0]))
                } else if values.count > 1 {
                    guides.append(.anyOf(values))
                }
            }

            // Handle pattern constraint
            if let regexPattern = pattern {
                if let regex = try? Regex(regexPattern) {
                    guides.append(.pattern(regex))
                }
            }

            return DynamicGenerationSchema(type: String.self, guides: guides)

        case "Int":
            var guides: [GenerationGuide<Int>] = []

            if let min = minimum, let max = maximum {
                guides.append(.range(min.intValue...max.intValue))
            } else if let min = minimum {
                guides.append(.minimum(min.intValue))
            } else if let max = maximum {
                guides.append(.maximum(max.intValue))
            }

            return DynamicGenerationSchema(type: Int.self, guides: guides)

        case "Double":
            var guides: [GenerationGuide<Double>] = []

            if let min = minimum, let max = maximum {
                guides.append(.range(min.doubleValue...max.doubleValue))
            } else if let min = minimum {
                guides.append(.minimum(min.doubleValue))
            } else if let max = maximum {
                guides.append(.maximum(max.doubleValue))
            }

            return DynamicGenerationSchema(type: Double.self, guides: guides)

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
