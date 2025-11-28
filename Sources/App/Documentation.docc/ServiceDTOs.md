# Service DTOs

Объекты передачи данных для работы с сервисами через API.

## Обзор

Service DTOs предоставляют структуры данных для создания, обновления и получения информации о сервисах через REST API. Все DTO реализуют протокол `Content` для автоматической сериализации/десериализации JSON.

## CreateServiceRequest

DTO для создания нового сервиса.

```swift
struct CreateServiceRequest: Content, Validatable {
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
}
```

### Поля

| Поле | Тип | Описание | Обязательное |
|------|-----|----------|--------------|
| `name` | `String` | Уникальное имя сервиса | Да |
| `description` | `String?` | Описание назначения сервиса | Нет |
| `owner` | `String` | Команда или владелец сервиса | Да |
| `tags` | `[String]` | Теги для категоризации | Да |
| `serviceType` | `ServiceType` | Тип сервиса | Да |
| `supportsDatabase` | `Bool` | Поддерживает ли БД | Да |
| `proxy` | `Bool` | Является ли прокси | Да |

### Валидация

```swift
static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: !.empty && .count(1...255))
    validations.add("owner", as: String.self, is: !.empty && .count(1...255))
    validations.add("tags", as: [String].self)
    validations.add("serviceType", as: ServiceType.self)
    validations.add("supportsDatabase", as: Bool.self)
    validations.add("proxy", as: Bool.self)
}
```

### Пример использования

#### HTTP запрос

```http
POST /services
Content-Type: application/json

{
    "name": "user-authentication-service",
    "description": "Сервис аутентификации и авторизации пользователей",
    "owner": "identity-team",
    "tags": ["authentication", "users", "security"],
    "serviceType": "APPLICATION",
    "supportsDatabase": true,
    "proxy": false
}
```

#### Swift код

```swift
let createRequest = CreateServiceRequest(
    name: "payment-service",
    description: "Сервис обработки платежей",
    owner: "payments-team",
    tags: ["payments", "billing", "financial"],
    serviceType: .APPLICATION,
    supportsDatabase: true,
    proxy: false
)

// Отправка запроса
let response = try await client.post("services") { req in
    try req.content.encode(createRequest)
}
```

## UpdateServiceRequest

DTO для обновления существующего сервиса. Все поля опциональны - обновляются только переданные поля.

```swift
struct UpdateServiceRequest: Content, Validatable {
    let name: String?
    let description: String?
    let owner: String?
    let tags: [String]?
    let serviceType: ServiceType?
    let supportsDatabase: Bool?
    let proxy: Bool?
}
```

### Поля

| Поле | Тип | Описание |
|------|-----|----------|
| `name` | `String?` | Новое имя сервиса |
| `description` | `String?` | Новое описание |
| `owner` | `String?` | Новый владелец |
| `tags` | `[String]?` | Новые теги |
| `serviceType` | `ServiceType?` | Новый тип сервиса |
| `supportsDatabase` | `Bool?` | Новое значение поддержки БД |
| `proxy` | `Bool?` | Новое значение прокси |

### Валидация

```swift
static func validations(_ validations: inout Validations) {
    validations.add("name", as: String?.self, is: .nil || (!.empty && .count(1...255)), required: false)
    validations.add("owner", as: String?.self, is: .nil || (!.empty && .count(1...255)), required: false)
    validations.add("tags", as: [String]?.self, required: false)
    validations.add("serviceType", as: ServiceType?.self, required: false)
    validations.add("supportsDatabase", as: Bool?.self, required: false)
    validations.add("proxy", as: Bool?.self, required: false)
}
```

### Примеры использования

#### Обновление описания и тегов

```http
PATCH /services/123e4567-e89b-12d3-a456-426614174000
Content-Type: application/json

{
    "description": "Обновленное описание сервиса аутентификации",
    "tags": ["authentication", "users", "security", "jwt", "oauth"]
}
```

#### Изменение типа сервиса

```http
PATCH /services/123e4567-e89b-12d3-a456-426614174000
Content-Type: application/json

{
    "serviceType": "PROXY",
    "proxy": true
}
```

#### Swift код

```swift
let updateRequest = UpdateServiceRequest(
    name: nil, // Не изменяем
    description: "Обновленное описание сервиса",
    owner: "new-team",
    tags: ["updated", "tags"],
    serviceType: nil, // Не изменяем
    supportsDatabase: nil, // Не изменяем
    proxy: nil // Не изменяем
)

let response = try await client.patch("services/\(serviceId)") { req in
    try req.content.encode(updateRequest)
}
```

## ServiceResponse

DTO для возврата информации о сервисе.

```swift
struct ServiceResponse: Content {
    let serviceId: UUID
    let name: String
    let description: String?
    let owner: String
    let tags: [String]
    let serviceType: ServiceType
    let supportsDatabase: Bool
    let proxy: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let environments: [ServiceEnvironmentResponse]?
}
```

### Поля

| Поле | Тип | Описание |
|------|-----|----------|
| `serviceId` | `UUID` | Уникальный идентификатор |
| `name` | `String` | Имя сервиса |
| `description` | `String?` | Описание сервиса |
| `owner` | `String` | Владелец сервиса |
| `tags` | `[String]` | Теги сервиса |
| `serviceType` | `ServiceType` | Тип сервиса |
| `supportsDatabase` | `Bool` | Поддержка БД |
| `proxy` | `Bool` | Является ли прокси |
| `createdAt` | `Date?` | Время создания |
| `updatedAt` | `Date?` | Время обновления |
| `environments` | `[ServiceEnvironmentResponse]?` | Окружения сервиса |

### Инициализация

#### Из модели Service

```swift
init(from service: Service) {
    self.serviceId = service.id!
    self.name = service.name
    self.description = service.description
    self.owner = service.owner
    self.tags = service.tags
    self.serviceType = service.serviceType
    self.supportsDatabase = service.supportsDatabase
    self.proxy = service.proxy
    self.createdAt = service.createdAt
    self.updatedAt = service.updatedAt
    self.environments = nil
}
```

#### Из модели Service с окружениями

```swift
init(from service: Service, environments: [ServiceEnvironment]) {
    self.serviceId = service.id!
    self.name = service.name
    self.description = service.description
    self.owner = service.owner
    self.tags = service.tags
    self.serviceType = service.serviceType
    self.supportsDatabase = service.supportsDatabase
    self.proxy = service.proxy
    self.createdAt = service.createdAt
    self.updatedAt = service.updatedAt
    self.environments = environments.map(ServiceEnvironmentResponse.init)
}
```

### Примеры ответов

#### Простой ответ

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
    "updatedAt": "2024-01-20T14:45:00Z",
    "environments": null
}
```

#### Ответ с окружениями

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
    "updatedAt": "2024-01-20T14:45:00Z",
    "environments": [
        {
            "environmentId": "456e7890-e89b-12d3-a456-426614174001",
            "serviceId": "123e4567-e89b-12d3-a456-426614174000",
            "code": "prod",
            "displayName": "Production",
            "host": "https://users.example.com",
            "config": {
                "timeoutMs": 10000,
                "retries": 3
            },
            "status": "ACTIVE",
            "createdAt": "2024-01-15T10:35:00Z",
            "updatedAt": "2024-01-20T14:50:00Z"
        }
    ]
}
```

## Использование в контроллерах

### Создание сервиса

```swift
func create(req: Request) async throws -> ServiceResponse {
    try CreateServiceRequest.validate(content: req)
    let createRequest = try req.content.decode(CreateServiceRequest.self)
    
    // Проверка уникальности имени
    if let _ = try await Service.query(on: req.db)
        .filter(\.$name == createRequest.name)
        .first() {
        throw Abort(.conflict, reason: "Service with name '\(createRequest.name)' already exists")
    }
    
    let service = Service(
        name: createRequest.name,
        description: createRequest.description,
        owner: createRequest.owner,
        tags: createRequest.tags,
        serviceType: createRequest.serviceType,
        supportsDatabase: createRequest.supportsDatabase,
        proxy: createRequest.proxy
    )
    
    try await service.save(on: req.db)
    return ServiceResponse(from: service)
}
```

### Обновление сервиса

```swift
func update(req: Request) async throws -> ServiceResponse {
    guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
        throw Abort(.badRequest, reason: "Invalid service ID")
    }
    
    guard let service = try await Service.find(serviceId, on: req.db) else {
        throw Abort(.notFound, reason: "Service not found")
    }
    
    try UpdateServiceRequest.validate(content: req)
    let updateRequest = try req.content.decode(UpdateServiceRequest.self)
    
    // Обновляем только переданные поля
    if let name = updateRequest.name {
        // Проверяем уникальность нового имени
        if try await Service.query(on: req.db)
            .filter(\.$name == name)
            .filter(\.$id != serviceId)
            .first() != nil {
            throw Abort(.conflict, reason: "Service with name '\(name)' already exists")
        }
        service.name = name
    }
    
    if let description = updateRequest.description {
        service.description = description
    }
    
    if let owner = updateRequest.owner {
        service.owner = owner
    }
    
    if let tags = updateRequest.tags {
        service.tags = tags
    }
    
    if let serviceType = updateRequest.serviceType {
        service.serviceType = serviceType
    }
    
    if let supportsDatabase = updateRequest.supportsDatabase {
        service.supportsDatabase = supportsDatabase
    }
    
    if let proxy = updateRequest.proxy {
        service.proxy = proxy
    }
    
    service.updatedAt = Date()
    try await service.save(on: req.db)
    
    return ServiceResponse(from: service)
}
```

### Получение сервиса

```swift
func show(req: Request) async throws -> ServiceResponse {
    guard let serviceId = req.parameters.get("serviceId", as: UUID.self) else {
        throw Abort(.badRequest, reason: "Invalid service ID")
    }
    
    guard let service = try await Service.find(serviceId, on: req.db) else {
        throw Abort(.notFound, reason: "Service not found")
    }
    
    return ServiceResponse(from: service)
}
```

### Получение списка сервисов

```swift
func list(req: Request) async throws -> [ServiceResponse] {
    let services = try await Service.query(on: req.db).all()
    return services.map { ServiceResponse(from: $0) }
}
```

## Валидация и ошибки

### Типичные ошибки валидации

| Ошибка | HTTP код | Описание |
|--------|----------|----------|
| Пустое имя | 400 | Имя сервиса не может быть пустым |
| Дублирование имени | 409 | Сервис с таким именем уже существует |
| Неверный тип | 400 | Неподдерживаемый тип сервиса |
| Пустой владелец | 400 | Владелец сервиса обязателен |

### Примеры ошибок

```json
{
    "error": true,
    "reason": "Validation failed",
    "details": [
        {
            "field": "name",
            "message": "Name is required and cannot be empty"
        },
        {
            "field": "owner",
            "message": "Owner is required"
        }
    ]
}
```

## Связанные типы

- <doc:Service> - Модель сервиса
- <doc:ServiceType> - Перечисление типов сервисов
- <doc:ServiceEnvironmentDTOs> - DTO для окружений сервисов

## Лучшие практики

### Валидация на клиенте

```swift
func validateCreateRequest(_ request: CreateServiceRequest) -> [String] {
    var errors: [String] = []
    
    if request.name.isEmpty {
        errors.append("Имя сервиса не может быть пустым")
    }
    
    if request.name.count > 255 {
        errors.append("Имя сервиса не может быть длиннее 255 символов")
    }
    
    if request.owner.isEmpty {
        errors.append("Владелец сервиса обязателен")
    }
    
    // Проверка формата тегов
    for tag in request.tags {
        if !tag.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) {
            errors.append("Тег '\(tag)' содержит недопустимые символы")
        }
    }
    
    return errors
}
```

### Обработка ошибок

```swift
do {
    let service = try await createService(request)
    return ServiceResponse(from: service)
} catch let abort as AbortError {
    switch abort.status {
    case .conflict:
        throw Abort(.conflict, reason: "Сервис с таким именем уже существует")
    case .badRequest:
        throw Abort(.badRequest, reason: "Некорректные данные запроса")
    default:
        throw abort
    }
} catch {
    throw Abort(.internalServerError, reason: "Внутренняя ошибка сервера")
}
```