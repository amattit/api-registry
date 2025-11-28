# Service

Основная модель для представления микросервиса в системе.

## Обзор

Модель `Service` представляет микросервис в реестре API. Каждый сервис содержит метаданные о своем назначении, владельце, типе и конфигурации.

```swift
final class Service: Model, Content, @unchecked Sendable {
    static let schema = "services"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "owner")
    var owner: String
    
    @Field(key: "tags")
    var tags: [String]
    
    @Enum(key: "service_type")
    var serviceType: ServiceType
    
    @Field(key: "supports_database")
    var supportsDatabase: Bool
    
    @Field(key: "proxy")
    var proxy: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Relationships
    @Children(for: \.$service)
    var environments: [ServiceEnvironment]
    
    @Children(for: \.$service)
    var serviceDbLinks: [ServiceDbLink]
    
    @Children(for: \.$service)
    var endpoints: [Endpoint]
}
```

## Поля модели

### Основные поля

| Поле | Тип | Описание | Обязательное |
|------|-----|----------|--------------|
| `id` | `UUID?` | Уникальный идентификатор сервиса | Нет (автогенерация) |
| `name` | `String` | Уникальное имя сервиса | Да |
| `description` | `String?` | Описание назначения сервиса | Нет |
| `owner` | `String` | Команда или владелец сервиса | Да |
| `tags` | `[String]` | Теги для категоризации | Да (может быть пустым) |
| `serviceType` | `ServiceType` | Тип сервиса | Да |
| `supportsDatabase` | `Bool` | Поддерживает ли сервис базы данных | Да |
| `proxy` | `Bool` | Является ли сервис прокси | Да |

### Временные метки

| Поле | Тип | Описание |
|------|-----|----------|
| `createdAt` | `Date?` | Время создания записи |
| `updatedAt` | `Date?` | Время последнего обновления |

### Связи (Relationships)

| Связь | Тип | Описание |
|-------|-----|----------|
| `environments` | `[ServiceEnvironment]` | Окружения развертывания сервиса |
| `serviceDbLinks` | `[ServiceDbLink]` | Связи с базами данных |
| `endpoints` | `[Endpoint]` | API эндпоинты сервиса |

## ServiceType

Перечисление типов сервисов в системе:

```swift
enum ServiceType: String, Codable, CaseIterable, @unchecked Sendable {
    case APPLICATION = "APPLICATION"
    case LIBRARY = "LIBRARY"
    case JOB = "JOB"
    case PROXY = "PROXY"
}
```

### Типы сервисов

| Тип | Описание | Использование |
|-----|----------|---------------|
| `APPLICATION` | Веб-приложение или API сервис | Основные бизнес-сервисы с HTTP API |
| `LIBRARY` | Библиотека или SDK | Переиспользуемые компоненты |
| `JOB` | Фоновая задача или cron job | Периодические или асинхронные задачи |
| `PROXY` | Прокси или gateway сервис | Маршрутизация и агрегация запросов |

## Инициализация

### Конструктор по умолчанию

```swift
init() { }
```

Используется Fluent ORM для создания пустого экземпляра.

### Полный конструктор

```swift
init(
    id: UUID? = nil,
    name: String,
    description: String? = nil,
    owner: String,
    tags: [String] = [],
    serviceType: ServiceType,
    supportsDatabase: Bool = false,
    proxy: Bool = false
)
```

#### Параметры

- `id`: Уникальный идентификатор (опционально, автогенерируется)
- `name`: Имя сервиса (должно быть уникальным)
- `description`: Описание сервиса
- `owner`: Владелец или команда
- `tags`: Массив тегов для категоризации
- `serviceType`: Тип сервиса из перечисления `ServiceType`
- `supportsDatabase`: Флаг поддержки баз данных
- `proxy`: Флаг прокси-сервиса

## Примеры использования

### Создание APPLICATION сервиса

```swift
let userService = Service(
    name: "user-service",
    description: "Сервис управления пользователями",
    owner: "backend-team",
    tags: ["users", "authentication", "core"],
    serviceType: .APPLICATION,
    supportsDatabase: true,
    proxy: false
)
```

### Создание PROXY сервиса

```swift
let apiGateway = Service(
    name: "api-gateway",
    description: "Основной API Gateway",
    owner: "platform-team",
    tags: ["gateway", "routing", "infrastructure"],
    serviceType: .PROXY,
    supportsDatabase: false,
    proxy: true
)
```

### Создание JOB сервиса

```swift
let emailJob = Service(
    name: "email-notification-job",
    description: "Фоновая отправка email уведомлений",
    owner: "notifications-team",
    tags: ["email", "notifications", "background"],
    serviceType: .JOB,
    supportsDatabase: true,
    proxy: false
)
```

### Создание LIBRARY

```swift
let authLib = Service(
    name: "auth-library",
    description: "Библиотека аутентификации",
    owner: "security-team",
    tags: ["auth", "security", "library"],
    serviceType: .LIBRARY,
    supportsDatabase: false,
    proxy: false
)
```

## Валидация

### Бизнес-правила

1. **Уникальность имени**: Имя сервиса должно быть уникальным в системе
2. **Обязательные поля**: `name`, `owner`, `serviceType` обязательны
3. **Формат тегов**: Теги должны содержать только буквы, цифры и дефисы
4. **Логическая согласованность**: 
   - PROXY сервисы обычно имеют `proxy = true`
   - LIBRARY сервисы обычно имеют `supportsDatabase = false`

### Примеры валидации

```swift
// Валидация при создании
func validateService(_ service: Service) throws {
    guard !service.name.isEmpty else {
        throw ValidationError("Имя сервиса не может быть пустым")
    }
    
    guard !service.owner.isEmpty else {
        throw ValidationError("Владелец сервиса обязателен")
    }
    
    // Проверка формата тегов
    for tag in service.tags {
        guard tag.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
            throw ValidationError("Тег '\(tag)' содержит недопустимые символы")
        }
    }
}
```

## Связанные типы

- <doc:ServiceEnvironment> - Окружения развертывания
- <doc:ServiceDbLink> - Связи с базами данных  
- <doc:Endpoint> - API эндпоинты
- <doc:ServiceDTOs> - DTO для работы с сервисами

## База данных

### Схема таблицы

```sql
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    owner VARCHAR(255) NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    service_type VARCHAR(50) NOT NULL,
    supports_database BOOLEAN NOT NULL DEFAULT FALSE,
    proxy BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Индексы

```sql
-- Уникальный индекс на имя
CREATE UNIQUE INDEX idx_services_name ON services(name);

-- Индекс на владельца для быстрого поиска
CREATE INDEX idx_services_owner ON services(owner);

-- Индекс на тип сервиса
CREATE INDEX idx_services_type ON services(service_type);

-- GIN индекс для поиска по тегам
CREATE INDEX idx_services_tags ON services USING GIN(tags);
```

## Лучшие практики

### Именование сервисов

- Используйте kebab-case: `user-service`, `payment-gateway`
- Включайте назначение: `user-auth-service`, `order-processing-job`
- Избегайте сокращений: `authentication-service` вместо `auth-svc`

### Теги

- Используйте консистентную схему тегирования
- Включайте функциональные теги: `users`, `payments`, `notifications`
- Включайте технические теги: `database`, `cache`, `queue`
- Включайте команду: `backend-team`, `platform-team`

### Описания

- Четко описывайте назначение сервиса
- Указывайте основные функции
- Упоминайте ключевые зависимости

```swift
// Хороший пример
let service = Service(
    name: "user-authentication-service",
    description: "Сервис аутентификации и авторизации пользователей. Обрабатывает логин, регистрацию, управление сессиями и JWT токенами.",
    owner: "identity-team",
    tags: ["authentication", "users", "security", "jwt", "sessions"],
    serviceType: .APPLICATION,
    supportsDatabase: true,
    proxy: false
)
```