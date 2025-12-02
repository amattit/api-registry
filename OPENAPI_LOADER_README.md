# OpenAPI Specification Loader

Этот модуль предоставляет функционал для автоматической загрузки и импорта OpenAPI спецификаций в API Registry.

## Возможности

- Загрузка OpenAPI спецификаций по URL
- Автоматическое создание или обновление сервисов
- Импорт всех endpoints из спецификации
- Сохранение метаданных endpoints (параметры, схемы запросов/ответов, авторизация)
- Поддержка полной замены данных при повторной загрузке

## API Endpoints

### POST /api/v1/openapi/load

Загружает OpenAPI спецификацию по указанному URL и создает/обновляет сервис с endpoints.

**Тело запроса:**
```json
{
  "url": "https://example.com/openapi.json",
  "overwrite": true
}
```

**Параметры:**
- `url` (string, обязательный) - URL для загрузки OpenAPI спецификации
- `overwrite` (boolean, опциональный) - Заменить ли существующие данные (по умолчанию: true)

**Ответ:**
```json
{
  "success": true,
  "message": "OpenAPI specification loaded successfully",
  "serviceId": "123e4567-e89b-12d3-a456-426614174000",
  "endpointsCreated": 45,
  "endpointsUpdated": 0
}
```

### GET /api/v1/openapi/status/{serviceId}

Получает статус загруженного сервиса.

**Параметры:**
- `serviceId` (UUID) - Идентификатор сервиса

**Ответ:**
```json
{
  "serviceId": "123e4567-e89b-12d3-a456-426614174000",
  "serviceName": "api-gateway-composer",
  "description": "API Gateway Composer Service",
  "endpointsCount": 45,
  "lastUpdated": "2023-12-02T10:30:00Z",
  "tags": ["Auth", "Collection", "Tracks", "Image"]
}
```

## Примеры использования

### Загрузка спецификации с внешнего URL

```bash
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://api.example.com/openapi.json",
    "overwrite": true
  }'
```

### Загрузка спецификации без перезаписи

```bash
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://api.example.com/openapi.json",
    "overwrite": false
  }'
```

### Проверка статуса загруженного сервиса

```bash
curl http://localhost:8080/api/v1/openapi/status/123e4567-e89b-12d3-a456-426614174000
```

## Поддерживаемые форматы

- OpenAPI 3.0.x
- OpenAPI 3.1.x
- JSON формат

## Обработка данных

### Сервисы

При загрузке спецификации создается или обновляется сервис со следующими данными:
- **Название**: из `info.title`
- **Описание**: из `info.description`
- **Владелец**: "OpenAPI Import"
- **Теги**: извлекаются из всех endpoints
- **Тип**: APPLICATION

### Endpoints

Для каждого пути и HTTP метода создается endpoint с:
- **Путь**: из ключа paths
- **HTTP метод**: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- **Описание**: из `summary` или `description`
- **Схема запроса**: параметры и тело запроса
- **Схемы ответов**: для всех статус кодов
- **Авторизация**: из `security`
- **Метаданные**: operationId, теги, дополнительная информация

## Логирование

Все операции логируются с указанием:
- URL загружаемой спецификации
- ID созданного/обновленного сервиса
- Количество созданных/обновленных endpoints
- Ошибки при загрузке или парсинге

## Обработка ошибок

### Возможные ошибки:

- **400 Bad Request**: Неверный формат URL или невалидная спецификация
- **404 Not Found**: Спецификация не найдена по указанному URL
- **422 Unprocessable Entity**: Ошибка валидации данных запроса
- **500 Internal Server Error**: Внутренняя ошибка сервера

### Примеры ошибок:

```json
{
  "error": true,
  "reason": "Invalid URL format"
}
```

```json
{
  "error": true,
  "reason": "Failed to fetch OpenAPI specification: HTTP 404"
}
```

```json
{
  "error": true,
  "reason": "Failed to parse OpenAPI specification: Invalid JSON"
}
```

## Тестирование

Для тестирования функционала можно использовать тестовый сервер:

```python
# Запуск тестового сервера с OpenAPI спецификацией
python test_openapi_server.py
```

Затем загрузить спецификацию:

```bash
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://localhost:12001/openapi.json",
    "overwrite": true
  }'
```

## Архитектура

### Компоненты:

1. **OpenAPILoaderController** - HTTP контроллер для обработки запросов
2. **OpenAPILoaderService** - Бизнес-логика загрузки и обработки спецификаций
3. **OpenAPILoaderDTO** - Структуры данных для запросов и ответов
4. **OpenAPISpec** - Модели для парсинга OpenAPI спецификаций

### Процесс загрузки:

1. Получение запроса с URL спецификации
2. Загрузка спецификации по HTTP
3. Парсинг JSON в структуры данных
4. Поиск или создание сервиса
5. Обработка всех endpoints из спецификации
6. Сохранение в базу данных
7. Возврат результата операции

## Требования

- Swift 5.10+
- Vapor 4.89.0+
- Fluent 4.8.0+
- PostgreSQL 15+