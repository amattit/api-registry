# DatabaseController

Контроллер для управления экземплярами баз данных и их связями с сервисами.

## Обзор

`DatabaseController` предоставляет REST API для управления экземплярами баз данных в системе и их связями с сервисами. Поддерживает различные типы СУБД и позволяет настраивать подключения для разных окружений.

```swift
struct DatabaseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let databases = routes.grouped("databases")
        
        // Database CRUD
        databases.post(use: create)
        databases.get(use: list)
        databases.get(":databaseId", use: show)
        databases.patch(":databaseId", use: update)
        databases.delete(":databaseId", use: delete)
        
        // Service database link management
        let services = routes.grouped("services", ":serviceId", "databases")
        services.post(use: createServiceDbLink)
        services.get(use: listServiceDbLinks)
        services.delete(":databaseId", use: deleteServiceDbLink)
    }
}
```

## API Endpoints

### Управление базами данных

| Метод | Путь | Описание | Контроллер |
|-------|------|----------|------------|
| POST | `/databases` | Создание новой БД | `create` |
| GET | `/databases` | Получение списка всех БД | `list` |
| GET | `/databases/{databaseId}` | Получение БД по ID | `show` |
| PATCH | `/databases/{databaseId}` | Обновление БД | `update` |
| DELETE | `/databases/{databaseId}` | Удаление БД | `delete` |

### Управление связями сервис-БД

| Метод | Путь | Описание | Контроллер |
|-------|------|----------|------------|
| POST | `/services/{serviceId}/databases` | Создание связи сервиса с БД | `createServiceDbLink` |
| GET | `/services/{serviceId}/databases` | Получение связей сервиса с БД | `listServiceDbLinks` |
| DELETE | `/services/{serviceId}/databases/{databaseId}` | Удаление связи сервиса с БД | `deleteServiceDbLink` |

## Методы управления базами данных

### create(req: Request) -> DatabaseResponse

Создает новый экземпляр базы данных в системе.

#### Бизнес-логика

1. **Валидация входных данных**: Проверка корректности `CreateDatabaseRequest`
2. **Проверка уникальности**: Проверка, что БД с таким именем не существует
3. **Валидация строки подключения**: Проверка формата connection string для типа СУБД
4. **Создание экземпляра**: Создание новой записи в базе данных
5. **Возврат результата**: Возврат `DatabaseResponse` с данными созданной БД

#### Параметры

- `req: Request` - HTTP запрос с данными `CreateDatabaseRequest`

#### Возвращает

- `DatabaseResponse` - Данные созданной базы данных

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Validation Error | Некорректные входные данные |
| 409 | Conflict | БД с таким именем уже существует |
| 500 | Internal Error | Ошибка базы данных |

#### Пример использования

```http
POST /databases
Content-Type: application/json

{
    "name": "users-postgres-prod",
    "description": "Основная PostgreSQL база для пользователей",
    "databaseType": "POSTGRESQL",
    "connectionString": "postgresql://app_user:password@db.example.com:5432/users_db",
    "config": {
        "max_connections": "100",
        "ssl_mode": "require",
        "statement_timeout": "30000"
    }
}
```

```json
{
    "databaseId": "456e7890-e89b-12d3-a456-426614174001",
    "name": "users-postgres-prod",
    "description": "Основная PostgreSQL база для пользователей",
    "databaseType": "POSTGRESQL",
    "connectionString": "postgresql://app_user:***@db.example.com:5432/users_db",
    "config": {
        "max_connections": "100",
        "ssl_mode": "require",
        "statement_timeout": "30000"
    },
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
}
```

### show(req: Request) -> DatabaseResponse

Получает информацию о базе данных по её ID.

#### Бизнес-логика

1. **Извлечение ID**: Получение `databaseId` из параметров URL
2. **Поиск БД**: Поиск базы данных в системе
3. **Проверка существования**: Проверка, что БД найдена
4. **Маскировка паролей**: Скрытие чувствительной информации в connection string
5. **Возврат результата**: Возврат `DatabaseResponse`

#### Параметры

- `req: Request` - HTTP запрос с параметром `databaseId`

#### Возвращает

- `DatabaseResponse` - Данные базы данных

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID базы данных |
| 404 | Not Found | База данных не найдена |

#### Пример использования

```http
GET /databases/456e7890-e89b-12d3-a456-426614174001
```

### list(req: Request) -> [DatabaseResponse]

Получает список всех баз данных в системе.

#### Бизнес-логика

1. **Запрос к БД**: Получение всех экземпляров БД
2. **Маскировка паролей**: Скрытие чувствительной информации
3. **Преобразование**: Конвертация моделей в DTO
4. **Возврат списка**: Возврат массива `DatabaseResponse`

#### Параметры

- `req: Request` - HTTP запрос

#### Возвращает

- `[DatabaseResponse]` - Массив всех баз данных

#### Пример использования

```http
GET /databases
```

```json
[
    {
        "databaseId": "456e7890-e89b-12d3-a456-426614174001",
        "name": "users-postgres-prod",
        "description": "Основная PostgreSQL база для пользователей",
        "databaseType": "POSTGRESQL",
        "connectionString": "postgresql://app_user:***@db.example.com:5432/users_db",
        "config": {
            "max_connections": "100",
            "ssl_mode": "require"
        },
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
    },
    {
        "databaseId": "789e1234-e89b-12d3-a456-426614174002",
        "name": "session-redis-prod",
        "description": "Redis для пользовательских сессий",
        "databaseType": "REDIS",
        "connectionString": "redis://session_app:***@cache.example.com:6379/0",
        "config": {
            "max_memory": "2gb",
            "maxmemory_policy": "allkeys-lru"
        },
        "createdAt": "2024-01-15T11:00:00Z",
        "updatedAt": "2024-01-15T11:00:00Z"
    }
]
```

### update(req: Request) -> DatabaseResponse

Обновляет существующую базу данных.

#### Бизнес-логика

1. **Извлечение ID**: Получение `databaseId` из параметров URL
2. **Поиск БД**: Поиск базы данных в системе
3. **Валидация данных**: Проверка `UpdateDatabaseRequest`
4. **Проверка уникальности**: Проверка уникальности нового имени (если изменяется)
5. **Валидация connection string**: Проверка нового connection string (если изменяется)
6. **Обновление полей**: Обновление только переданных полей
7. **Сохранение**: Сохранение изменений в базе данных
8. **Возврат результата**: Возврат обновленного `DatabaseResponse`

#### Параметры

- `req: Request` - HTTP запрос с данными `UpdateDatabaseRequest`

#### Возвращает

- `DatabaseResponse` - Обновленные данные базы данных

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID или данные |
| 404 | Not Found | База данных не найдена |
| 409 | Conflict | Новое имя уже используется |

#### Пример использования

```http
PATCH /databases/456e7890-e89b-12d3-a456-426614174001
Content-Type: application/json

{
    "description": "Обновленное описание PostgreSQL базы",
    "config": {
        "max_connections": "150",
        "ssl_mode": "require",
        "statement_timeout": "45000"
    }
}
```

### delete(req: Request) -> HTTPStatus

Удаляет базу данных из системы.

#### Бизнес-логика

1. **Извлечение ID**: Получение `databaseId` из параметров URL
2. **Поиск БД**: Поиск базы данных в системе
3. **Проверка использования**: Проверка, что БД не используется сервисами
4. **Удаление**: Удаление базы данных
5. **Возврат статуса**: Возврат HTTP 204 No Content

#### Параметры

- `req: Request` - HTTP запрос с параметром `databaseId`

#### Возвращает

- `HTTPStatus` - Статус 204 No Content

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID базы данных |
| 404 | Not Found | База данных не найдена |
| 409 | Conflict | БД используется сервисами |

#### Пример использования

```http
DELETE /databases/456e7890-e89b-12d3-a456-426614174001
```

## Методы управления связями сервис-БД

### createServiceDbLink(req: Request) -> ServiceDbLinkResponse

Создает связь между сервисом и базой данных для определенного окружения.

#### Бизнес-логика

1. **Извлечение serviceId**: Получение ID сервиса из параметров URL
2. **Проверка сервиса**: Проверка существования сервиса
3. **Валидация данных**: Проверка `CreateServiceDbLinkRequest`
4. **Проверка БД**: Проверка существования базы данных
5. **Проверка уникальности**: Проверка, что связь не существует
6. **Создание связи**: Создание новой записи связи
7. **Возврат результата**: Возврат `ServiceDbLinkResponse`

#### Параметры

- `req: Request` - HTTP запрос с данными `CreateServiceDbLinkRequest`

#### Возвращает

- `ServiceDbLinkResponse` - Данные созданной связи

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректные данные |
| 404 | Not Found | Сервис или БД не найдены |
| 409 | Conflict | Связь уже существует |

#### Пример использования

```http
POST /services/123e4567-e89b-12d3-a456-426614174000/databases
Content-Type: application/json

{
    "databaseId": "456e7890-e89b-12d3-a456-426614174001",
    "environmentCode": "prod",
    "schemaName": "users_prod",
    "connectionOverride": {
        "pool_size": "20",
        "timeout": "5000"
    }
}
```

```json
{
    "linkId": "789e1234-e89b-12d3-a456-426614174003",
    "serviceId": "123e4567-e89b-12d3-a456-426614174000",
    "databaseId": "456e7890-e89b-12d3-a456-426614174001",
    "environmentCode": "prod",
    "schemaName": "users_prod",
    "connectionOverride": {
        "pool_size": "20",
        "timeout": "5000"
    },
    "database": {
        "databaseId": "456e7890-e89b-12d3-a456-426614174001",
        "name": "users-postgres-prod",
        "databaseType": "POSTGRESQL"
    },
    "createdAt": "2024-01-15T12:00:00Z",
    "updatedAt": "2024-01-15T12:00:00Z"
}
```

### listServiceDbLinks(req: Request) -> [ServiceDbLinkResponse]

Получает все связи сервиса с базами данных.

#### Бизнес-логика

1. **Извлечение serviceId**: Получение ID сервиса из параметров URL
2. **Проверка сервиса**: Проверка существования сервиса
3. **Запрос связей**: Получение всех связей сервиса с БД
4. **Загрузка БД**: Загрузка информации о связанных БД
5. **Преобразование**: Конвертация в DTO
6. **Возврат списка**: Возврат массива `ServiceDbLinkResponse`

#### Параметры

- `req: Request` - HTTP запрос с параметром `serviceId`

#### Возвращает

- `[ServiceDbLinkResponse]` - Массив связей сервиса с БД

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректный UUID сервиса |
| 404 | Not Found | Сервис не найден |

#### Пример использования

```http
GET /services/123e4567-e89b-12d3-a456-426614174000/databases
```

```json
[
    {
        "linkId": "789e1234-e89b-12d3-a456-426614174003",
        "serviceId": "123e4567-e89b-12d3-a456-426614174000",
        "databaseId": "456e7890-e89b-12d3-a456-426614174001",
        "environmentCode": "prod",
        "schemaName": "users_prod",
        "connectionOverride": {
            "pool_size": "20"
        },
        "database": {
            "databaseId": "456e7890-e89b-12d3-a456-426614174001",
            "name": "users-postgres-prod",
            "databaseType": "POSTGRESQL"
        },
        "createdAt": "2024-01-15T12:00:00Z",
        "updatedAt": "2024-01-15T12:00:00Z"
    },
    {
        "linkId": "abc1234-e89b-12d3-a456-426614174004",
        "serviceId": "123e4567-e89b-12d3-a456-426614174000",
        "databaseId": "789e1234-e89b-12d3-a456-426614174002",
        "environmentCode": "prod",
        "schemaName": null,
        "connectionOverride": {},
        "database": {
            "databaseId": "789e1234-e89b-12d3-a456-426614174002",
            "name": "session-redis-prod",
            "databaseType": "REDIS"
        },
        "createdAt": "2024-01-15T12:30:00Z",
        "updatedAt": "2024-01-15T12:30:00Z"
    }
]
```

### deleteServiceDbLink(req: Request) -> HTTPStatus

Удаляет связь между сервисом и базой данных.

#### Бизнес-логика

1. **Извлечение параметров**: Получение `serviceId` и `databaseId` из URL
2. **Извлечение environmentCode**: Получение кода окружения из query параметров
3. **Поиск связи**: Поиск связи по всем параметрам
4. **Проверка существования**: Проверка, что связь найдена
5. **Удаление**: Удаление связи
6. **Возврат статуса**: Возврат HTTP 204 No Content

#### Параметры

- `req: Request` - HTTP запрос с параметрами:
  - `serviceId` (URL) - ID сервиса
  - `databaseId` (URL) - ID базы данных
  - `environmentCode` (query) - код окружения

#### Возвращает

- `HTTPStatus` - Статус 204 No Content

#### Ошибки

| HTTP код | Причина | Описание |
|----------|---------|----------|
| 400 | Bad Request | Некорректные параметры |
| 404 | Not Found | Связь не найдена |

#### Пример использования

```http
DELETE /services/123e4567-e89b-12d3-a456-426614174000/databases/456e7890-e89b-12d3-a456-426614174001?environmentCode=prod
```

## Валидация и безопасность

### Валидация строк подключения

```swift
func validateConnectionString(_ connectionString: String, for type: DatabaseType) throws {
    switch type {
    case .POSTGRESQL:
        guard connectionString.hasPrefix("postgresql://") else {
            throw DatabaseError.invalidConnectionString("PostgreSQL connection string must start with 'postgresql://'")
        }
    case .MYSQL:
        guard connectionString.hasPrefix("mysql://") else {
            throw DatabaseError.invalidConnectionString("MySQL connection string must start with 'mysql://'")
        }
    case .REDIS:
        guard connectionString.hasPrefix("redis://") else {
            throw DatabaseError.invalidConnectionString("Redis connection string must start with 'redis://'")
        }
    case .MONGODB:
        guard connectionString.hasPrefix("mongodb://") else {
            throw DatabaseError.invalidConnectionString("MongoDB connection string must start with 'mongodb://'")
        }
    // ... другие типы
    }
}
```

### Маскировка паролей

```swift
func maskPassword(in connectionString: String) -> String {
    // Регулярное выражение для поиска паролей в connection string
    let pattern = #"://([^:]+):([^@]+)@"#
    let regex = try! NSRegularExpression(pattern: pattern)
    
    return regex.stringByReplacingMatches(
        in: connectionString,
        range: NSRange(connectionString.startIndex..., in: connectionString),
        withTemplate: "://$1:***@"
    )
}
```

### Шифрование чувствительных данных

```swift
func encryptConnectionString(_ connectionString: String) throws -> String {
    let key = Environment.get("DB_ENCRYPTION_KEY")!
    return try AES.encrypt(connectionString, key: key)
}

func decryptConnectionString(_ encryptedString: String) throws -> String {
    let key = Environment.get("DB_ENCRYPTION_KEY")!
    return try AES.decrypt(encryptedString, key: key)
}
```

## Мониторинг и логирование

### Логирование операций с БД

```swift
func create(req: Request) async throws -> DatabaseResponse {
    req.logger.info("Creating new database", metadata: [
        "user_id": .string(req.auth.get(User.self)?.id?.uuidString ?? "anonymous"),
        "database_name": .string(createRequest.name),
        "database_type": .string(createRequest.databaseType.rawValue)
    ])
    
    // ... логика создания
    
    req.logger.info("Database created successfully", metadata: [
        "database_id": .string(database.id!.uuidString),
        "database_name": .string(database.name)
    ])
    
    return DatabaseResponse(from: database)
}
```

### Аудит изменений

```swift
func update(req: Request) async throws -> DatabaseResponse {
    let user = try req.auth.require(User.self)
    
    // Логирование изменений
    let changes = detectChanges(original: database, updated: updateRequest)
    
    req.logger.info("Database updated", metadata: [
        "user_id": .string(user.id!.uuidString),
        "database_id": .string(database.id!.uuidString),
        "changes": .array(changes.map { .string($0) })
    ])
    
    // ... логика обновления
}
```

## Связанные типы

- <doc:DatabaseInstance> - Модель базы данных
- <doc:ServiceDbLink> - Модель связи сервис-БД
- <doc:DatabaseDTOs> - DTO для работы с БД
- <doc:DatabaseType> - Перечисление типов СУБД

## Лучшие практики

### Управление подключениями

```swift
// Создание пула подключений для каждого типа БД
func createConnectionPool(for database: DatabaseInstance) -> ConnectionPool {
    switch database.databaseType {
    case .POSTGRESQL:
        return PostgreSQLConnectionPool(
            connectionString: database.connectionString,
            maxConnections: database.config["max_connections"]?.int ?? 10
        )
    case .REDIS:
        return RedisConnectionPool(
            connectionString: database.connectionString,
            maxConnections: database.config["max_connections"]?.int ?? 5
        )
    // ... другие типы
    }
}
```

### Тестирование подключений

```swift
func testConnection(req: Request) async throws -> ConnectionTestResponse {
    guard let databaseId = req.parameters.get("databaseId", as: UUID.self) else {
        throw Abort(.badRequest, reason: "Invalid database ID")
    }
    
    guard let database = try await DatabaseInstance.find(databaseId, on: req.db) else {
        throw Abort(.notFound, reason: "Database not found")
    }
    
    let connectionTester = DatabaseConnectionTester(database: database)
    let result = try await connectionTester.test()
    
    return ConnectionTestResponse(
        success: result.success,
        latency: result.latency,
        error: result.error
    )
}
```

### Миграции схем

```swift
func migrateSchema(req: Request) async throws -> MigrationResponse {
    guard let linkId = req.parameters.get("linkId", as: UUID.self) else {
        throw Abort(.badRequest, reason: "Invalid link ID")
    }
    
    guard let link = try await ServiceDbLink.find(linkId, on: req.db) else {
        throw Abort(.notFound, reason: "Database link not found")
    }
    
    let migrator = SchemaMigrator(link: link)
    let result = try await migrator.migrate()
    
    return MigrationResponse(
        success: result.success,
        migrationsApplied: result.migrations,
        errors: result.errors
    )
}
```