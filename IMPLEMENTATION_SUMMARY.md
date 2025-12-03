# Реализация функционала загрузки OpenAPI спецификаций

## Обзор

Реализован полный функционал для автоматической загрузки и импорта OpenAPI спецификаций в API Registry. Система позволяет загружать спецификации по URL, автоматически создавать или обновлять сервисы и импортировать все endpoints с их метаданными.

## Реализованные компоненты

### 1. Модели данных (DTOs)

**Файл:** `Sources/App/DTOs/OpenAPILoaderDTO.swift`

- `LoadOpenAPISpecRequest` - запрос на загрузку спецификации
- `LoadOpenAPISpecResponse` - ответ с результатами загрузки
- `ServiceLoadStatusResponse` - статус загруженного сервиса
- `OpenAPISpec` - модель для парсинга OpenAPI спецификаций
- Вспомогательные структуры для параметров, запросов и ответов

### 2. Сервис загрузки

**Файл:** `Sources/App/Services/OpenAPILoaderService.swift`

Основной сервис, реализующий бизнес-логику:

- `loadAndProcessOpenAPISpec()` - главный метод загрузки и обработки
- `fetchOpenAPISpec()` - загрузка спецификации по HTTP
- `findOrCreateService()` - поиск или создание сервиса
- `processEndpoints()` - обработка всех endpoints
- `createOrUpdateEndpoint()` - создание/обновление отдельного endpoint
- Методы для построения схем запросов, ответов и метаданных

### 3. HTTP контроллер

**Файл:** `Sources/App/Controllers/OpenAPILoaderController.swift`

REST API контроллер с endpoints:

- `POST /api/v1/openapi/load` - загрузка спецификации
- `GET /api/v1/openapi/status/{serviceId}` - статус сервиса

### 4. Тесты

**Файл:** `Tests/AppTests/OpenAPILoaderTests.swift`

Unit тесты для проверки функционала:

- Тест загрузки валидной спецификации
- Тест обработки невалидного URL
- Тест получения статуса сервиса

### 5. Вспомогательные файлы

- `test_openapi_server.py` - тестовый HTTP сервер для демонстрации
- `demo_openapi_loader.py` - демонстрационный скрипт
- `OPENAPI_LOADER_README.md` - подробная документация

## Ключевые возможности

### ✅ Загрузка спецификаций по URL
- Поддержка HTTP/HTTPS URL
- Валидация формата URL
- Обработка ошибок сети и HTTP

### ✅ Парсинг OpenAPI спецификаций
- Поддержка OpenAPI 3.0.x и 3.1.x
- Извлечение информации о сервисе (название, описание, версия)
- Парсинг всех paths и HTTP методов
- Обработка параметров, схем запросов и ответов

### ✅ Управление сервисами
- Автоматическое создание новых сервисов
- Обновление существующих сервисов
- Извлечение тегов из endpoints
- Установка метаданных сервиса

### ✅ Управление endpoints
- Создание endpoints для всех paths и методов
- Сохранение схем запросов и ответов
- Обработка параметров (path, query, header)
- Сохранение информации об авторизации
- Полная замена endpoints при повторной загрузке

### ✅ Обработка ошибок
- Валидация входных данных
- Обработка сетевых ошибок
- Парсинг JSON с детальными сообщениями об ошибках
- Логирование всех операций

## API Endpoints

### POST /api/v1/openapi/load

Загружает OpenAPI спецификацию и создает/обновляет сервис.

**Запрос:**
```json
{
  "url": "https://example.com/openapi.json",
  "overwrite": true
}
```

**Ответ:**
```json
{
  "success": true,
  "message": "OpenAPI specification loaded successfully",
  "serviceId": "uuid",
  "endpointsCreated": 45,
  "endpointsUpdated": 0
}
```

### GET /api/v1/openapi/status/{serviceId}

Получает статус загруженного сервиса.

**Ответ:**
```json
{
  "serviceId": "uuid",
  "serviceName": "api-gateway-composer",
  "description": "Service description",
  "endpointsCount": 45,
  "lastUpdated": "2023-12-02T10:30:00Z",
  "tags": ["Auth", "Collection", "Tracks"]
}
```

## Пример использования

1. **Запуск тестового сервера:**
```bash
python test_openapi_server.py
```

2. **Загрузка спецификации:**
```bash
curl -X POST http://localhost:8080/api/v1/openapi/load \
  -H "Content-Type: application/json" \
  -d '{"url": "http://localhost:12001/openapi.json", "overwrite": true}'
```

3. **Проверка статуса:**
```bash
curl http://localhost:8080/api/v1/openapi/status/{serviceId}
```

4. **Демонстрационный скрипт:**
```bash
python demo_openapi_loader.py
```

## Обработка данных из примера спецификации

Из предоставленной спецификации `api-gateway-composer` будет извлечено:

- **Сервис:** "api-gateway-composer" v0.1.0
- **55 endpoints** из различных категорий:
  - Auth (3 endpoints)
  - Collection (4 endpoints) 
  - Tracks (2 endpoints)
  - Image (1 endpoint)
  - Releases (1 endpoint)
  - Playlist (8 endpoints)
  - Podcast (3 endpoints)
  - И другие...

- **Метаданные для каждого endpoint:**
  - HTTP метод и путь
  - Описание (summary)
  - Параметры (path, query, header)
  - Схемы запросов и ответов
  - Информация об авторизации
  - Теги и дополнительные метаданные

## Интеграция с существующим кодом

Новый функционал полностью интегрирован с существующей архитектурой:

- Использует существующие модели `Service` и `Endpoint`
- Подключен к системе маршрутизации Vapor
- Использует существующую базу данных PostgreSQL
- Совместим с существующими миграциями
- Следует паттернам проекта (Controller-Service-Model)

## Файлы изменений

### Новые файлы:
- `Sources/App/DTOs/OpenAPILoaderDTO.swift`
- `Sources/App/Services/OpenAPILoaderService.swift`
- `Sources/App/Controllers/OpenAPILoaderController.swift`
- `Tests/AppTests/OpenAPILoaderTests.swift`
- `OPENAPI_LOADER_README.md`
- `test_openapi_server.py`
- `demo_openapi_loader.py`

### Измененные файлы:
- `Sources/App/routes.swift` - добавлен новый контроллер

## Требования для запуска

- Swift 5.10+
- Vapor 4.89.0+
- Fluent 4.8.0+
- PostgreSQL 15+
- Доступ к интернету для загрузки спецификаций

## Следующие шаги

1. Запустить проект с Docker Compose
2. Протестировать функционал с реальными OpenAPI спецификациями
3. Добавить поддержку аутентификации для защищенных URL
4. Реализовать планировщик для автоматического обновления спецификаций
5. Добавить веб-интерфейс для управления загруженными спецификациями