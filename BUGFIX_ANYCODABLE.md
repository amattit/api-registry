# Исправление ошибки AnyCodable Encoding

## Проблема

При загрузке OpenAPI спецификаций возникала ошибка кодирования:

```
▿ EncodingError
  ▿ invalidValue : 2 elements
    ▿ .0 : AnyCodable
      ▿ value : 1 element
        ▿ 0 : 2 elements
          - key : "schema"
          ▿ value : 2 elements
            ▿ 0 : 2 elements
              - key : "type"
              - value : "integer"
            ▿ 1 : 2 elements
              - key : "title"
              - value : "Entity Name"
    ▿ .1 : Context
      ▿ codingPath : 2 elements
        ▿ 0 : _JSONKey(stringValue: "content", intValue: nil)
        ▿ 1 : _JSONKey(stringValue: "application/json", intValue: nil)
      - debugDescription : "AnyCodable value cannot be encoded"
```

## Причина

Ошибка возникала из-за попытки закодировать сложные вложенные структуры `AnyCodable`, которые содержали:
- Словари с `AnyCodable` значениями
- Массивы кортежей
- Глубоко вложенные структуры данных

`AnyCodable` не может правильно сериализовать такие сложные структуры в JSON.

## Решение

### 1. Добавлены вспомогательные функции

```swift
// Конвертация AnyCodable словарей в простые словари
private func convertAnyCodableDict(_ dict: [String: AnyCodable]) -> [String: Any] {
    var result: [String: Any] = [:]
    
    for (key, value) in dict {
        result[key] = convertAnyCodableValue(value)
    }
    
    return result
}

// Рекурсивная конвертация AnyCodable значений
private func convertAnyCodableValue(_ value: AnyCodable) -> Any {
    switch value.value {
    case let dict as [String: AnyCodable]:
        return convertAnyCodableDict(dict)
    case let array as [AnyCodable]:
        return array.map { convertAnyCodableValue($0) }
    case let dict as [String: Any]:
        return dict
    case let array as [Any]:
        return array
    default:
        return value.value
    }
}
```

### 2. Исправлены методы обработки схем

#### buildRequestSchema
```swift
// Было:
schema["content"] = AnyCodable(content)

// Стало:
let contentDict = convertAnyCodableDict(content)
schema["content"] = AnyCodable(contentDict)
```

#### buildResponseSchemas
```swift
// Было:
responseData["content"] = AnyCodable(content)

// Стало:
responseData["content"] = convertAnyCodableDict(content)
```

#### buildMetadata
```swift
// Было:
return metadata.isEmpty ? nil : ["metadata": AnyCodable(metadata)]

// Стало:
var result: [String: AnyCodable] = [:]
for (key, value) in metadata {
    result[key] = AnyCodable(value)
}
return result
```

### 3. Улучшена обработка параметров

```swift
// Было:
paramData["schema"] = AnyCodable(schema)

// Стало:
paramDict["schema"] = convertAnyCodableDict(paramSchema)
```

## Результат

После исправления:
- ✅ Устранена ошибка `AnyCodable value cannot be encoded`
- ✅ Корректная сериализация сложных OpenAPI схем
- ✅ Правильная обработка вложенных структур данных
- ✅ Сохранение всех метаданных endpoints

## Тестирование

Для проверки исправления используйте:

```bash
# Запуск тестового скрипта
python test_fix.py

# Или ручное тестирование
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{"url": "http://localhost:12001/openapi.json", "overwrite": true}'
```

## Технические детали

### Проблемные структуры

OpenAPI спецификации содержат сложные вложенные структуры:

```json
{
  "content": {
    "application/json": {
      "schema": {
        "type": "integer",
        "title": "Entity Name"
      }
    }
  }
}
```

### Решение на уровне типов

1. **Конвертация на входе**: Преобразование `[String: AnyCodable]` в `[String: Any]`
2. **Рекурсивная обработка**: Обход всех вложенных структур
3. **Безопасная сериализация**: Использование простых типов Swift для JSON

### Совместимость

- ✅ Обратная совместимость с существующим кодом
- ✅ Сохранение всех данных OpenAPI спецификации
- ✅ Корректная работа с базой данных
- ✅ Поддержка всех типов OpenAPI схем

## Файлы изменений

- `Sources/App/Services/OpenAPILoaderService.swift` - основные исправления
- `test_fix.py` - тестовый скрипт для проверки

## Commit

```
fix: Resolve AnyCodable encoding error in OpenAPI loader

- Fix AnyCodable encoding issues when processing complex nested structures
- Add helper functions to convert AnyCodable dictionaries to plain dictionaries
- Improve error handling for JSON serialization of OpenAPI schemas
- Ensure proper conversion of request/response schemas and parameters
```