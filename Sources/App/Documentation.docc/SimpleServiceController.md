# SimpleServiceController

Контроллер для управления сервисами и их окружениями через REST API.

## Обзор

`SimpleServiceController` предоставляет полный набор операций CRUD для управления сервисами, их окружениями и генерации OpenAPI спецификаций. Контроллер реализует RESTful API с поддержкой валидации, обработки ошибок и бизнес-логики.

```swift
struct SimpleServiceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let services = routes.grouped("services")
        
        // Service CRUD
        services.post(use: create)
        services.get(":serviceId", use: show)
        services.patch(":serviceId", use: update)
        services.delete(":serviceId", use: delete)
        services.get(use: list)
        
        // Service environments
        services.put(":serviceId", "environments", ":envCode", use: upsertEnvironment)
        services.delete(":serviceId", "environments", ":envCode", use: deleteEnvironment)
        
        // OpenAPI generation
        services.post(":serviceId", "generate-openapi", use: generateOpenAPI)
    }
}
```

## API Endpoints

### Управление сервисами

| Метод | Путь | Описание | Контроллер |
|-------|------|----------|------------|
| POST | `/services` | Создание нового сервиса | `create` |
| GET | `/services` | Получение списка всех сервисов | `list` |
| GET | `/services/{serviceId}` | Получение сервиса по ID | `show` |
| PATCH | `/services/{serviceId}` | Обновление сервиса | `update` |
| DELETE | `/services/{serviceId}` | Удаление сервиса | `delete` |

### Управление окружениями

| Метод | Путь | Описание | Контроллер |
|-------|------|----------|------------|
| PUT | `/services/{serviceId}/environments/{envCode}` | Создание/обновление окружения | `upsertEnvironment` |
| DELETE | `/services/{serviceId}/environments/{envCode}` | Удаление окружения | `deleteEnvironment` |

### Генерация документации

| Метод | Путь | Описание | Контроллер |
|-------|------|----------|------------|
| POST | `/services/{serviceId}/generate-openapi` | Генерация OpenAPI спецификации | `generateOpenAPI` |

## Методы контроллера

### create(req: Request) -> ServiceResponse

Создает новый сервис в системе.

#### Бизнес-логика

1. **Валидация входных данных**: Проверка корректности `CreateServiceRequest`
2. **Проверка уникальности**: Проверка, что сервис с таким именем не существует
3. **Создание сервиса**: Создание новой записи в базе данных
4. **Возврат результата**: Возврат `ServiceResponse` с данными созданного сервиса

#### Параметры

- `req: Request` - HTTP запрос с данными `CreateServiceRequest`

#### Возвращает

- `ServiceResponse` - Данные созданного сервиса

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Validation Error | Некорректные входные данные |
| 409 | Conflict | Сервис с таким именем уже существует |
| 500 | Internal Error | Ошибка базы данных |

#### Пример использования

```http
POST /services
Content-Type: application/json

{
    "name": "user-service",
    "description": "Сервис управления пользователями",
    "owner": "backend-team",
    "tags": ["users", "authentication"],
    "serviceType": "APPLICATION",
    "supportsDatabase": true,
    "proxy": false
}
```

```json
{
    "serviceId": "123e4567-e89b-12d3-a456-426614174000",
    "name": "user-service",
    "description": "Сервис управления пользователями",
    "owner": "backend-team",
    "tags": ["users", "authentication"],
    "serviceType": "APPLICATION",
    "supportsDatabase": true,
    "proxy": false,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z",
    "environments": null
}
```

### show(req: Request) -> ServiceResponse

Получает информацию о сервисе по его ID.

#### Бизнес-логика

1. **Извлечение ID**: Получение `serviceId` из параметров URL
2. **Поиск сервиса**: Поиск сервиса в базе данных
3. **Проверка существования**: Проверка, что сервис найден
4. **Возврат результата**: Возврат `ServiceResponse`

#### Параметры

- `req: Request` - HTTP запрос с параметром `serviceId`

#### Возвращает

- `ServiceResponse` - Данные сервиса

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID сервиса |
| 404 | Not Found | Сервис не найден |

#### Пример использования

```http
GET /services/123e4567-e89b-12d3-a456-426614174000
```

### list(req: Request) -> [ServiceResponse]

Получает список всех сервисов в системе.

#### Бизнес-логика

1. **Запрос к БД**: Получение всех сервисов из базы данных
2. **Преобразование**: Конвертация моделей в DTO
3. **Возврат списка**: Возврат массива `ServiceResponse`

#### Параметры

- `req: Request` - HTTP запрос

#### Возвращает

- `[ServiceResponse]` - Массив всех сервисов

#### Пример использования

```http
GET /services
```

```json
[
    {
        "serviceId": "123e4567-e89b-12d3-a456-426614174000",
        "name": "user-service",
        "description": "Сервис управления пользователями",
        "owner": "backend-team",
        "tags": ["users", "authentication"],
        "serviceType": "APPLICATION",
        "supportsDatabase": true,
        "proxy": false,
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z",
        "environments": null
    }
]
```

### update(req: Request) -> ServiceResponse

Обновляет существующий сервис.

#### Бизнес-логика

1. **Извлечение ID**: Получение `serviceId` из параметров URL
2. **Поиск сервиса**: Поиск сервиса в базе данных
3. **Валидация данных**: Проверка `UpdateServiceRequest`
4. **Проверка уникальности**: Проверка уникальности нового имени (если изменяется)
5. **Обновление полей**: Обновление только переданных полей
6. **Сохранение**: Сохранение изменений в базе данных
7. **Возврат результата**: Возврат обновленного `ServiceResponse`

#### Параметры

- `req: Request` - HTTP запрос с данными `UpdateServiceRequest`

#### Возвращает

- `ServiceResponse` - Обновленные данные сервиса

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID или данные |
| 404 | Not Found | Сервис не найден |
| 409 | Conflict | Новое имя уже используется |

#### Пример использования

```http
PATCH /services/123e4567-e89b-12d3-a456-426614174000
Content-Type: application/json

{
    "description": "Обновленное описание сервиса",
    "tags": ["users", "authentication", "jwt"]
}
```

### delete(req: Request) -> HTTPStatus

Удаляет сервис из системы.

#### Бизнес-логика

1. **Извлечение ID**: Получение `serviceId` из параметров URL
2. **Поиск сервиса**: Поиск сервиса в базе данных
3. **Проверка существования**: Проверка, что сервис найден
4. **Удаление**: Удаление сервиса и связанных данных (каскадно)
5. **Возврат статуса**: Возврат HTTP 204 No Content

#### Параметры

- `req: Request` - HTTP запрос с параметром `serviceId`

#### Возвращает

- `HTTPStatus` - Статус 204 No Content

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID сервиса |
| 404 | Not Found | Сервис не найден |

#### Пример использования

```http
DELETE /services/123e4567-e89b-12d3-a456-426614174000
```

### upsertEnvironment(req: Request) -> ServiceEnvironmentResponse

Создает новое или обновляет существующее окружение сервиса.

#### Бизнес-логика

1. **Извлечение параметров**: Получение `serviceId` и `envCode` из URL
2. **Проверка сервиса**: Проверка существования родительского сервиса
3. **Валидация данных**: Проверка данных окружения
4. **Поиск существующего**: Поиск существующего окружения
5. **Создание или обновление**: 
   - Если существует - обновление полей
   - Если не существует - создание нового
6. **Сохранение**: Сохранение в базе данных
7. **Возврат результата**: Возврат `ServiceEnvironmentResponse`

#### Параметры

- `req: Request` - HTTP запрос с данными окружения

#### Возвращает

- `ServiceEnvironmentResponse` - Данные окружения

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректные параметры |
| 404 | Not Found | Сервис не найден |

#### Пример использования

```http
PUT /services/123e4567-e89b-12d3-a456-426614174000/environments/prod
Content-Type: application/json

{
    "displayName": "Production",
    "host": "https://api.example.com",
    "config": {
        "timeoutMs": 10000,
        "retries": 3,
        "downstreamOverrides": {
            "payment-service": "https://payments.prod.example.com"
        }
    },
    "status": "ACTIVE"
}
```

### deleteEnvironment(req: Request) -> HTTPStatus

Удаляет окружение сервиса.

#### Бизнес-логика

1. **Извлечение параметров**: Получение `serviceId` и `envCode` из URL
2. **Поиск окружения**: Поиск окружения в базе данных
3. **Проверка существования**: Проверка, что окружение найдено
4. **Удаление**: Удаление окружения
5. **Возврат статуса**: Возврат HTTP 204 No Content

#### Параметры

- `req: Request` - HTTP запрос с параметрами `serviceId` и `envCode`

#### Возвращает

- `HTTPStatus` - Статус 204 No Content

#### Пример использования

```http
DELETE /services/123e4567-e89b-12d3-a456-426614174000/environments/staging
```

### generateOpenAPI(req: Request) -> Response

Генерирует OpenAPI спецификацию для сервиса.

#### Бизнес-логика

1. **Извлечение параметров**: Получение `serviceId` и `env` из запроса
2. **Поиск сервиса**: Поиск сервиса в базе данных
3. **Поиск окружения**: Поиск указанного окружения
4. **Загрузка эндпоинтов**: Получение всех эндпоинтов сервиса с зависимостями
5. **Генерация спецификации**: Создание OpenAPI 3.0 спецификации
6. **Выбор формата**: Определение формата ответа (JSON/YAML)
7. **Возврат спецификации**: Возврат сгенерированной спецификации

#### Параметры

- `req: Request` - HTTP запрос с query параметрами:
  - `env` (обязательный) - код окружения
  - `format` (опциональный) - формат ответа (`json` или `yaml`)

#### Возвращает

- `Response` - OpenAPI спецификация в JSON или YAML формате

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Отсутствует параметр env |
| 404 | Not Found | Сервис или окружение не найдены |

#### Пример использования

```http
POST /services/123e4567-e89b-12d3-a456-426614174000/generate-openapi?env=prod&format=json
```

```json
{
    "openapi": "3.0.0",
    "info": {
        "title": "user-service",
        "description": "Сервис управления пользователями",
        "version": "1.0.0"
    },
    "servers": [
        {
            "url": "https://api.example.com",
            "description": "prod environment"
        }
    ],
    "paths": {
        "/users": {
            "get": {
                "summary": "Получить список пользователей",
                "operationId": "get_users",
                "responses": {
                    "200": {
                        "description": "Success"
                    }
                }
            }
        }
    }
}
```

## Валидация и обработка ошибок

### Валидация входных данных

Контроллер использует встроенную валидацию Vapor для проверки DTO:

```swift
try CreateServiceRequest.validate(content: req)
let createRequest = try req.content.decode(CreateServiceRequest.self)
```

### Обработка ошибок

#### Стандартные ошибки

```swift
// Некорректный UUID
guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
    throw Abort(.badRequest, reason: "Invalid service ID")
}

// Сервис не найден
guard let service = try await Service.find(serviceId, on: req.db) else {
    throw Abort(.notFound, reason: "Service not found")
}

// Конфликт имен
if let _ = try await Service.query(on: req.db)
    .filter(\.$name == createRequest.name)
    .first() {
    throw Abort(.conflict, reason: "Service with name '\(createRequest.name)' already exists")
}
```

#### Пользовательские ошибки

```swift
enum ServiceError: Error {
    case invalidServiceType
    case environmentNotConfigured
    case dependencyNotFound
}

extension ServiceError: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .invalidServiceType:
            return .badRequest
        case .environmentNotConfigured:
            return .preconditionFailed
        case .dependencyNotFound:
            return .notFound
        }
    }
    
    var reason: String {
        switch self {
        case .invalidServiceType:
            return "Неподдерживаемый тип сервиса"
        case .environmentNotConfigured:
            return "Окружение не настроено"
        case .dependencyNotFound:
            return "Зависимость не найдена"
        }
    }
}
```

## Безопасность и авторизация

### Middleware для аутентификации

```swift
func boot(routes: RoutesBuilder) throws {
    let services = routes.grouped("services")
    
    // Публичные эндпоинты (только чтение)
    services.get(use: list)
    services.get(":serviceId", use: show)
    
    // Защищенные эндпоинты (требуют аутентификации)
    let protected = services.grouped(UserAuthenticator())
    protected.post(use: create)
    protected.patch(":serviceId", use: update)
    protected.delete(":serviceId", use: delete)
    protected.put(":serviceId", "environments", ":envCode", use: upsertEnvironment)
    protected.delete(":serviceId", "environments", ":envCode", use: deleteEnvironment)
}
```

### Авторизация по ролям

```swift
func create(req: Request) async throws -> ServiceResponse {
    let user = try req.auth.require(User.self)
    
    // Проверка прав на создание сервисов
    guard user.hasPermission(.createService) else {
        throw Abort(.forbidden, reason: "Insufficient permissions")
    }
    
    // ... остальная логика
}
```

## Мониторинг и логирование

### Логирование операций

```swift
func create(req: Request) async throws -> ServiceResponse {
    req.logger.info("Creating new service", metadata: [
        "user_id": .string(req.auth.get(User.self)?.id?.uuidString ?? "anonymous"),
        "service_name": .string(createRequest.name)
    ])
    
    // ... логика создания
    
    req.logger.info("Service created successfully", metadata: [
        "service_id": .string(service.id!.uuidString),
        "service_name": .string(service.name)
    ])
    
    return ServiceResponse(from: service)
}
```

### Метрики

```swift
import Metrics

func create(req: Request) async throws -> ServiceResponse {
    let timer = Timer(label: "service_creation_duration")
    let start = DispatchTime.now()
    
    defer {
        let end = DispatchTime.now()
        let duration = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
        timer.recordSeconds(duration)
        
        Counter(label: "services_created_total").increment()
    }
    
    // ... логика создания
}
```

## Связанные типы

- <doc:ServiceDTOs> - DTO для работы с сервисами
- <doc:ServiceEnvironmentDTOs> - DTO для окружений
- <doc:Service> - Модель сервиса
- <doc:ServiceEnvironment> - Модель окружения

## Лучшие практики

### Транзакции

```swift
func create(req: Request) async throws -> ServiceResponse {
    return try await req.db.transaction { database in
        // Создание сервиса
        let service = Service(...)
        try await service.save(on: database)
        
        // Создание окружения по умолчанию
        let defaultEnv = ServiceEnvironment(...)
        try await defaultEnv.save(on: database)
        
        return ServiceResponse(from: service)
    }
}
```

### Кэширование

```swift
func list(req: Request) async throws -> [ServiceResponse] {
    let cacheKey = "services:all"
    
    if let cached = try await req.cache.get(cacheKey, as: [ServiceResponse].self) {
        return cached
    }
    
    let services = try await Service.query(on: req.db).all()
    let responses = services.map { ServiceResponse(from: $0) }
    
    try await req.cache.set(cacheKey, to: responses, expiresIn: .minutes(5))
    
    return responses
}
```

### Пагинация

```swift
func list(req: Request) async throws -> Page<ServiceResponse> {
    let page = try req.query.get(Int.self, at: "page") ?? 1
    let per = min(try req.query.get(Int.self, at: "per") ?? 20, 100)
    
    let services = try await Service.query(on: req.db)
        .paginate(PageRequest(page: page, per: per))
    
    return services.map { ServiceResponse(from: $0) }
}
```