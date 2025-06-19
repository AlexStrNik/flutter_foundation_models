import Foundation
import FoundationModels

fileprivate typealias JSON = [String: Any]

extension GenerationSchema {
    static func fromJson(
        _ json: [String: Any]
    ) throws -> GenerationSchema {
        guard let root = json["root"] as? JSON else {
            fatalError("[GenerationSchema] missing root")
        }
        guard let dependencies = json["dependencies"] as? [JSON] else {
            fatalError("[GenerationSchema] missing dependencies")
        }
        
        return try GenerationSchema(
            root: DynamicGenerationSchema.fromJson(root),
            dependencies: dependencies.map { DynamicGenerationSchema.fromJson($0) }
        )
    }
}

extension DynamicGenerationSchema {
  fileprivate static func fromJson(
    _ json: JSON
  ) -> DynamicGenerationSchema {
    guard let kind = json["kind"] as? String else {
      fatalError("[DynamicGenerationSchema] missing kind")
    }

    switch kind {
    case "ValueGenerationSchema":
      return fromValueGenerationSchema(json)
    case "ArrayGenerationSchema":
      return fromArrayGenerationSchema(json)
    case "DictionaryGenerationSchema":
      return fromDictionaryGenerationSchema(json)
    case "AnyOfGenerationSchema":
      return fromAnyOfGenerationSchema(json)
    case "AnyOfStringsGenerationSchema":
      return fromAnyOfStringsGenerationSchema(json)
    case "StructGenerationSchema":
      return fromStructGenerationSchema(json)
    default:
      fatalError("[DynamicGenerationSchema] unknown kind: \(kind)")
    }
  }

  fileprivate static func fromValueGenerationSchema(
    _ json: JSON
  ) -> DynamicGenerationSchema {
    guard let typeName = json["type"] as? String else {
      fatalError("[DynamicGenerationSchema] missing type for ValueGenerationSchema")
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
      fatalError("[DynamicGenerationSchema] unknown type for ValueGenerationSchema: \(typeName)")
    }
  }

  fileprivate static func fromArrayGenerationSchema(
    _ json: JSON
  ) -> DynamicGenerationSchema {
    guard let arrayOfJson = json["arrayOf"] as? JSON else {
      fatalError("[DynamicGenerationSchema] missing or invalid arrayOf for ArrayGenerationSchema")
    }

    let arrayOf = fromJson(arrayOfJson)

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
  ) -> DynamicGenerationSchema {
    guard let dictionaryOfJson = json["dictionaryOf"] as? JSON else {
      fatalError(
        "[DynamicGenerationSchema] missing or invalid dictionaryOf for DictionaryGenerationSchema"
      )
    }
    let dictionaryOf = fromJson(dictionaryOfJson)

    return DynamicGenerationSchema(dictionaryOf: dictionaryOf)
  }

  fileprivate static func fromAnyOfGenerationSchema(
    _ json: JSON
  ) -> DynamicGenerationSchema {
    guard let name = json["name"] as? String else {
      fatalError("[DynamicGenerationSchema] missing name for AnyOfGenerationSchema")
    }

    guard let anyOfJsonArray = json["anyOf"] as? [JSON] else {
      fatalError("[DynamicGenerationSchema] missing anyOf for AnyOfGenerationSchema")
    }

    let description = json["description"] as? String
    let schemas: [DynamicGenerationSchema] = anyOfJsonArray.map {
      fromJson($0)
    }

    if schemas.isEmpty {
      fatalError("[DynamicGenerationSchema] no valid schemas found in anyOf")
    }

    return DynamicGenerationSchema(
      name: name,
      description: description,
      anyOf: schemas
    )
  }

  fileprivate static func fromAnyOfStringsGenerationSchema(
    _ json: JSON
  ) -> DynamicGenerationSchema {
    guard let name = json["name"] as? String else {
      fatalError("[DynamicGenerationSchema] missing name for AnyOfStringsGenerationSchema")
    }

    guard let anyOfStrings = json["anyOf"] as? [String] else {
      fatalError("[DynamicGenerationSchema] missing anyOf for AnyOfStringsGenerationSchema")
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
  ) -> DynamicGenerationSchema {
    guard let name = json["name"] as? String else {
      fatalError("[DynamicGenerationSchema] missing name for StructGenerationSchema")
    }

    guard let propertiesJsonArray = json["properties"] as? [JSON] else {
      fatalError("[DynamicGenerationSchema] missing properties for StructGenerationSchema")
    }

    let description = json["description"] as? String
    let properties: [DynamicGenerationSchema.Property] = propertiesJsonArray.map {
      DynamicGenerationSchema.Property.fromJson($0)
    }

    if properties.isEmpty {
      fatalError("[DynamicGenerationSchema] no valid properties found in struct")
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
    ) -> DynamicGenerationSchema.Property {
        guard let name: String = json["name"] as? String else {
            fatalError(
                "[DynamicGenerationSchema.Property] missing name for DynamicGenerationSchemaProperty"
            )
        }
        guard let schemaJson = json["schema"] as? JSON else {
            fatalError(
                "[DynamicGenerationSchema.Property] missing schema for DynamicGenerationSchemaProperty"
            )
        }
        let schema = DynamicGenerationSchema.fromJson(schemaJson)
        
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
