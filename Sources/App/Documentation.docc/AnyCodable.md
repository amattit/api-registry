# AnyCodable

Универсальная обертка для кодирования и декодирования произвольных типов данных в JSON.

## Обзор

`AnyCodable` - это утилитарная структура, которая позволяет работать с произвольными типами данных в JSON без необходимости знать их конкретный тип на этапе компиляции. Особенно полезна для работы с динамическими конфигурациями, схемами API и метаданными.

```swift
struct AnyCodable: Codable, Hashable, Sendable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
```

## Основные возможности

- **Универсальное кодирование**: Поддержка любых типов данных, совместимых с JSON
- **Безопасное декодирование**: Автоматическое определение типа при декодировании
- **Hashable**: Поддержка использования в качестве ключей словарей
- **Sendable**: Безопасность для использования в concurrent коде
- **Null-safety**: Корректная обработка nil значений

## Поддерживаемые типы

### Примитивные типы

| Swift тип | JSON тип | Описание |
|-----------|----------|----------|
| `String` | string | Строковые значения |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | number | Целые числа |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` | number | Беззнаковые целые |
| `Float`, `Double` | number | Числа с плавающей точкой |
| `Bool` | boolean | Логические значения |
| `nil` | null | Отсутствие значения |

### Коллекции

| Swift тип | JSON тип | Описание |
|-----------|----------|----------|
| `Array<Any>` | array | Массивы произвольных элементов |
| `Dictionary<String, Any>` | object | Объекты с строковыми ключами |
| `Set<AnyHashable>` | array | Множества (сериализуются как массивы) |

## Инициализация

### Из произвольного значения

```swift
let stringValue = AnyCodable("Hello, World!")
let intValue = AnyCodable(42)
let boolValue = AnyCodable(true)
let nilValue = AnyCodable(nil)
```

### Из коллекций

```swift
let arrayValue = AnyCodable([1, "two", true, nil])
let dictValue = AnyCodable([
    "name": "John",
    "age": 30,
    "active": true
])
```

### Из сложных структур

```swift
let complexValue = AnyCodable([
    "user": [
        "id": 123,
        "profile": [
            "name": "John Doe",
            "settings": [
                "theme": "dark",
                "notifications": true
            ]
        ]
    ],
    "permissions": ["read", "write"],
    "metadata": nil
])
```

## Кодирование (Encoding)

### Автоматическое кодирование

```swift
let config = AnyCodable([
    "timeout": 5000,
    "retries": 3,
    "endpoints": [
        "api": "https://api.example.com",
        "auth": "https://auth.example.com"
    ]
])

let encoder = JSONEncoder()
let jsonData = try encoder.encode(config)
let jsonString = String(data: jsonData, encoding: .utf8)!

print(jsonString)
// {
//   "timeout": 5000,
//   "retries": 3,
//   "endpoints": {
//     "api": "https://api.example.com",
//     "auth": "https://auth.example.com"
//   }
// }
```

### Кодирование в контексте других структур

```swift
struct ServiceConfig: Codable {
    let name: String
    let version: String
    let settings: AnyCodable
}

let serviceConfig = ServiceConfig(
    name: "user-service",
    version: "1.0.0",
    settings: AnyCodable([
        "database": [
            "host": "localhost",
            "port": 5432,
            "ssl": true
        ],
        "cache": [
            "ttl": 3600,
            "maxSize": "100MB"
        ]
    ])
)

let jsonData = try JSONEncoder().encode(serviceConfig)
```

## Декодирование (Decoding)

### Автоматическое декодирование

```swift
let jsonString = """
{
    "timeout": 5000,
    "retries": 3,
    "endpoints": {
        "api": "https://api.example.com",
        "auth": "https://auth.example.com"
    },
    "features": ["auth", "logging", "metrics"],
    "debug": true
}
"""

let jsonData = jsonString.data(using: .utf8)!
let decoder = JSONDecoder()
let config = try decoder.decode(AnyCodable.self, from: jsonData)

// Доступ к значениям
if let dict = config.value as? [String: Any] {
    let timeout = dict["timeout"] as? Int // 5000
    let endpoints = dict["endpoints"] as? [String: Any]
    let features = dict["features"] as? [String] // ["auth", "logging", "metrics"]
}
```

### Декодирование в контексте других структур

```swift
struct APIResponse: Codable {
    let status: String
    let data: AnyCodable
    let metadata: AnyCodable?
}

let jsonResponse = """
{
    "status": "success",
    "data": {
        "users": [
            {"id": 1, "name": "John"},
            {"id": 2, "name": "Jane"}
        ],
        "total": 2
    },
    "metadata": {
        "page": 1,
        "limit": 10,
        "hasMore": false
    }
}
"""

let response = try JSONDecoder().decode(APIResponse.self, from: jsonResponse.data(using: .utf8)!)
```

## Доступ к значениям

### Безопасное извлечение значений

```swift
let config = AnyCodable([
    "database": [
        "host": "localhost",
        "port": 5432,
        "credentials": [
            "username": "app_user",
            "password": "secret"
        ]
    ],
    "features": ["auth", "logging"]
])

// Извлечение вложенных значений
if let dict = config.value as? [String: Any],
   let database = dict["database"] as? [String: Any],
   let credentials = database["credentials"] as? [String: Any] {
    
    let host = database["host"] as? String // "localhost"
    let port = database["port"] as? Int // 5432
    let username = credentials["username"] as? String // "app_user"
}

// Извлечение массивов
if let dict = config.value as? [String: Any],
   let features = dict["features"] as? [String] {
    print("Features: \(features)") // ["auth", "logging"]
}
```

### Использование subscript (если реализован)

```swift
extension AnyCodable {
    subscript(key: String) -> AnyCodable? {
        guard let dict = value as? [String: Any] else { return nil }
        return dict[key].map(AnyCodable.init)
    }
    
    subscript(index: Int) -> AnyCodable? {
        guard let array = value as? [Any], index < array.count else { return nil }
        return AnyCodable(array[index])
    }
}

// Использование
let host = config["database"]?["host"]?.value as? String
let firstFeature = config["features"]?[0]?.value as? String
```

## Hashable и Equatable

### Сравнение значений

```swift
let value1 = AnyCodable("hello")
let value2 = AnyCodable("hello")
let value3 = AnyCodable("world")

print(value1 == value2) // true
print(value1 == value3) // false
```

### Использование в качестве ключей

```swift
let cache: [AnyCodable: String] = [
    AnyCodable("user_123"): "John Doe",
    AnyCodable(42): "Answer",
    AnyCodable(true): "Enabled"
]

let userName = cache[AnyCodable("user_123")] // "John Doe"
```

### Сравнение сложных структур

```swift
let config1 = AnyCodable([
    "timeout": 5000,
    "retries": 3
])

let config2 = AnyCodable([
    "timeout": 5000,
    "retries": 3
])

print(config1 == config2) // true
```

## Использование в моделях

### Конфигурация окружений

```swift
struct EnvironmentConfig: Codable {
    let timeoutMs: Int?
    let retries: Int?
    let downstreamOverrides: [String: String]?
    let customSettings: AnyCodable?
}

let config = EnvironmentConfig(
    timeoutMs: 5000,
    retries: 3,
    downstreamOverrides: ["api": "https://api.example.com"],
    customSettings: AnyCodable([
        "logging": [
            "level": "info",
            "format": "json"
        ],
        "monitoring": [
            "enabled": true,
            "interval": 30
        ]
    ])
)
```

### Схемы API эндпоинтов

```swift
struct Endpoint: Codable {
    let path: String
    let method: HTTPMethod
    let requestSchema: [String: AnyCodable]?
    let responseSchemas: [String: AnyCodable]?
}

let endpoint = Endpoint(
    path: "/users",
    method: .POST,
    requestSchema: [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "name": [
                "type": "string",
                "minLength": 1,
                "maxLength": 100
            ],
            "email": [
                "type": "string",
                "format": "email"
            ],
            "age": [
                "type": "integer",
                "minimum": 0,
                "maximum": 150
            ]
        ]),
        "required": AnyCodable(["name", "email"])
    ],
    responseSchemas: [
        "200": AnyCodable([
            "type": "object",
            "properties": [
                "id": ["type": "integer"],
                "name": ["type": "string"],
                "email": ["type": "string"],
                "createdAt": ["type": "string", "format": "date-time"]
            ]
        ]),
        "400": AnyCodable([
            "type": "object",
            "properties": [
                "error": ["type": "string"],
                "details": ["type": "array"]
            ]
        ])
    ]
)
```

## Обработка ошибок

### Ошибки кодирования

```swift
enum AnyCodableError: Error {
    case unsupportedType(Any.Type)
    case encodingFailed(String)
    case decodingFailed(String)
}

// Обработка неподдерживаемых типов
func encode<T>(_ value: T) throws -> AnyCodable {
    // Проверка поддерживаемых типов
    switch value {
    case is String, is Int, is Double, is Bool:
        return AnyCodable(value)
    case let array as [Any]:
        return AnyCodable(array)
    case let dict as [String: Any]:
        return AnyCodable(dict)
    case is NSNull:
        return AnyCodable(nil)
    default:
        throw AnyCodableError.unsupportedType(type(of: value))
    }
}
```

### Валидация данных

```swift
func validateAnyCodable(_ value: AnyCodable, against schema: [String: Any]) throws {
    guard let dict = value.value as? [String: Any] else {
        throw ValidationError("Expected object, got \(type(of: value.value))")
    }
    
    // Проверка обязательных полей
    if let required = schema["required"] as? [String] {
        for field in required {
            guard dict[field] != nil else {
                throw ValidationError("Required field '\(field)' is missing")
            }
        }
    }
    
    // Проверка типов полей
    if let properties = schema["properties"] as? [String: [String: Any]] {
        for (field, fieldSchema) in properties {
            if let fieldValue = dict[field],
               let expectedType = fieldSchema["type"] as? String {
                try validateType(fieldValue, expectedType: expectedType)
            }
        }
    }
}
```

## Производительность

### Оптимизация для больших объемов данных

```swift
// Ленивое декодирование для больших JSON
struct LazyAnyCodable: Codable {
    private let jsonData: Data
    private var _cachedValue: Any?
    
    var value: Any {
        if let cached = _cachedValue {
            return cached
        }
        
        let decoded = try! JSONSerialization.jsonObject(with: jsonData)
        _cachedValue = decoded
        return decoded
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.jsonData = try container.decode(Data.self)
    }
}
```

### Кэширование хэшей

```swift
struct CachedAnyCodable: Hashable {
    let value: Any
    private let _hashValue: Int
    
    init<T>(_ value: T) {
        self.value = value
        self._hashValue = computeHash(for: value)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(_hashValue)
    }
}
```

## Связанные типы

- <doc:EnvironmentConfig> - Использует AnyCodable для гибкой конфигурации
- <doc:Endpoint> - Использует для схем запросов и ответов
- <doc:ServiceEnvironment> - Содержит AnyCodable конфигурации

## Лучшие практики

### Типобезопасность

```swift
// Создание типобезопасных оберток
struct DatabaseConfig {
    private let anyCodable: AnyCodable
    
    init(_ anyCodable: AnyCodable) {
        self.anyCodable = anyCodable
    }
    
    var host: String? {
        (anyCodable.value as? [String: Any])?["host"] as? String
    }
    
    var port: Int? {
        (anyCodable.value as? [String: Any])?["port"] as? Int
    }
    
    var maxConnections: Int {
        ((anyCodable.value as? [String: Any])?["max_connections"] as? Int) ?? 10
    }
}
```

### Валидация схем

```swift
protocol SchemaValidatable {
    func validate(against schema: [String: Any]) throws
}

extension AnyCodable: SchemaValidatable {
    func validate(against schema: [String: Any]) throws {
        let validator = JSONSchemaValidator(schema: schema)
        try validator.validate(self.value)
    }
}
```

### Безопасная сериализация

```swift
extension AnyCodable {
    func toJSONString(prettyPrinted: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = .prettyPrinted
        }
        
        let data = try encoder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [],
                debugDescription: "Unable to convert to UTF-8 string"
            ))
        }
        
        return string
    }
}
```