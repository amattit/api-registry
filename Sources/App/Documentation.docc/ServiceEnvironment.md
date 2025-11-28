# ServiceEnvironment

Модель для представления окружения развертывания сервиса.

## Обзор

Модель `ServiceEnvironment` представляет конкретное окружение развертывания сервиса (например, development, staging, production). Каждое окружение имеет свою конфигурацию, хост и статус.

```swift
final class ServiceEnvironment: Model, Content, @unchecked Sendable {
    static let schema = "service_environments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "service_id")
    var service: Service
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "display_name")
    var displayName: String
    
    @Field(key: "host")
    var host: String
    
    @Field(key: "config")
    var config: EnvironmentConfig?
    
    @Enum(key: "status")
    var status: EnvironmentStatus
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
}
```

## Поля модели

### Основные поля

| Поле | Тип | Описание | Обязательное |
|------|-----|----------|--------------|
| `id` | `UUID?` | Уникальный идентификатор окружения | Нет (автогенерация) |
| `service` | `Service` | Родительский сервис | Да |
| `code` | `String` | Код окружения (dev, staging, prod) | Да |
| `displayName` | `String` | Отображаемое имя окружения | Да |
| `host` | `String` | URL хоста окружения | Да |
| `config` | `EnvironmentConfig?` | Конфигурация окружения | Нет |
| `status` | `EnvironmentStatus` | Статус окружения | Да |

### Временные метки

| Поле | Тип | Описание |
|------|-----|----------|
| `createdAt` | `Date?` | Время создания записи |
| `updatedAt` | `Date?` | Время последнего обновления |

## EnvironmentConfig

Структура конфигурации окружения:

```swift
struct EnvironmentConfig: Codable {
    let timeoutMs: Int?
    let retries: Int?
    let downstreamOverrides: [String: String]?
}
```

### Поля конфигурации

| Поле | Тип | Описание |
|------|-----|----------|
| `timeoutMs` | `Int?` | Таймаут запросов в миллисекундах |
| `retries` | `Int?` | Количество повторных попыток |
| `downstreamOverrides` | `[String: String]?` | Переопределения URL downstream сервисов |

## EnvironmentStatus

Перечисление статусов окружения:

```swift
enum EnvironmentStatus: String, Codable, CaseIterable {
    case ACTIVE = "ACTIVE"
    case INACTIVE = "INACTIVE"
}
```

### Статусы

| Статус | Описание |
|--------|----------|
| `ACTIVE` | Окружение активно и доступно |
| `INACTIVE` | Окружение неактивно или на обслуживании |

## Инициализация

### Конструктор по умолчанию

```swift
init() { }
```

### Полный конструктор

```swift
init(
    id: UUID? = nil,
    serviceID: UUID,
    code: String,
    displayName: String,
    host: String,
    config: EnvironmentConfig? = nil,
    status: EnvironmentStatus = .ACTIVE
)
```

#### Параметры

- `id`: Уникальный идентификатор (опционально)
- `serviceID`: ID родительского сервиса
- `code`: Код окружения
- `displayName`: Отображаемое имя
- `host`: URL хоста
- `config`: Конфигурация окружения
- `status`: Статус (по умолчанию ACTIVE)

## Примеры использования

### Создание Production окружения

```swift
let prodConfig = EnvironmentConfig(
    timeoutMs: 10000,
    retries: 3,
    downstreamOverrides: [
        "payment-service": "https://payments.prod.example.com",
        "user-service": "https://users.prod.example.com"
    ]
)

let prodEnvironment = ServiceEnvironment(
    serviceID: serviceId,
    code: "prod",
    displayName: "Production",
    host: "https://api.example.com",
    config: prodConfig,
    status: .ACTIVE
)
```

### Создание Development окружения

```swift
let devConfig = EnvironmentConfig(
    timeoutMs: 5000,
    retries: 1,
    downstreamOverrides: [
        "payment-service": "http://localhost:3001",
        "user-service": "http://localhost:3002"
    ]
)

let devEnvironment = ServiceEnvironment(
    serviceID: serviceId,
    code: "dev",
    displayName: "Development",
    host: "http://localhost:8080",
    config: devConfig,
    status: .ACTIVE
)
```

### Создание Staging окружения

```swift
let stagingEnvironment = ServiceEnvironment(
    serviceID: serviceId,
    code: "staging",
    displayName: "Staging",
    host: "https://staging-api.example.com",
    config: nil, // Использует конфигурацию по умолчанию
    status: .ACTIVE
)
```

### Создание неактивного окружения

```swift
let maintenanceEnvironment = ServiceEnvironment(
    serviceID: serviceId,
    code: "maintenance",
    displayName: "Maintenance",
    host: "https://maintenance.example.com",
    status: .INACTIVE
)
```

## Стандартные коды окружений

### Рекомендуемые коды

| Код | Название | Описание |
|-----|----------|----------|
| `dev` | Development | Локальная разработка |
| `test` | Testing | Автоматизированное тестирование |
| `staging` | Staging | Предпродакшн тестирование |
| `prod` | Production | Продакшн окружение |
| `demo` | Demo | Демонстрационное окружение |

### Специальные окружения

| Код | Название | Описание |
|-----|----------|----------|
| `load-test` | Load Testing | Нагрузочное тестирование |
| `security-test` | Security Testing | Тестирование безопасности |
| `canary` | Canary | Канареечное развертывание |
| `blue` / `green` | Blue/Green | Blue-Green развертывание |

## Конфигурация окружений

### Типичные конфигурации

#### Production

```swift
let prodConfig = EnvironmentConfig(
    timeoutMs: 30000,      // Длинный таймаут для стабильности
    retries: 5,            // Больше попыток для надежности
    downstreamOverrides: [
        "database": "postgresql://prod-db.example.com:5432/app",
        "cache": "redis://prod-cache.example.com:6379",
        "queue": "amqp://prod-queue.example.com:5672"
    ]
)
```

#### Development

```swift
let devConfig = EnvironmentConfig(
    timeoutMs: 5000,       // Быстрый фидбек
    retries: 1,            // Быстрое падение для отладки
    downstreamOverrides: [
        "database": "postgresql://localhost:5432/app_dev",
        "cache": "redis://localhost:6379",
        "queue": "amqp://localhost:5672"
    ]
)
```

#### Testing

```swift
let testConfig = EnvironmentConfig(
    timeoutMs: 1000,       // Быстрые тесты
    retries: 0,            // Без повторов для предсказуемости
    downstreamOverrides: [
        "database": "postgresql://test-db:5432/app_test",
        "external-api": "http://mock-server:8080"
    ]
)
```

## Валидация

### Бизнес-правила

1. **Уникальность**: Комбинация `serviceId` + `code` должна быть уникальной
2. **Формат кода**: Код должен содержать только буквы, цифры и дефисы
3. **Валидный URL**: Поле `host` должно содержать валидный URL
4. **Конфигурация**: Значения в конфигурации должны быть положительными

### Примеры валидации

```swift
func validateEnvironment(_ env: ServiceEnvironment) throws {
    // Валидация кода
    guard env.code.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else {
        throw ValidationError("Код окружения содержит недопустимые символы")
    }
    
    // Валидация URL
    guard URL(string: env.host) != nil else {
        throw ValidationError("Некорректный URL хоста")
    }
    
    // Валидация конфигурации
    if let config = env.config {
        if let timeout = config.timeoutMs, timeout <= 0 {
            throw ValidationError("Таймаут должен быть положительным")
        }
        
        if let retries = config.retries, retries < 0 {
            throw ValidationError("Количество повторов не может быть отрицательным")
        }
    }
}
```

## API операции

### Создание/обновление окружения

```http
PUT /services/{serviceId}/environments/{code}
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

### Удаление окружения

```http
DELETE /services/{serviceId}/environments/{code}
```

## Связанные типы

- <doc:Service> - Родительский сервис
- <doc:ServiceEnvironmentDTOs> - DTO для работы с окружениями

## База данных

### Схема таблицы

```sql
CREATE TABLE service_environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    host VARCHAR(500) NOT NULL,
    config JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(service_id, code)
);
```

### Индексы

```sql
-- Уникальный индекс на комбинацию сервис + код
CREATE UNIQUE INDEX idx_service_environments_service_code 
ON service_environments(service_id, code);

-- Индекс на статус для фильтрации
CREATE INDEX idx_service_environments_status 
ON service_environments(status);

-- GIN индекс для поиска по конфигурации
CREATE INDEX idx_service_environments_config 
ON service_environments USING GIN(config);
```

## Лучшие практики

### Именование окружений

- Используйте короткие, понятные коды: `dev`, `staging`, `prod`
- Используйте описательные display names: "Development", "Staging", "Production"
- Будьте консистентны в именовании между сервисами

### Конфигурация

- Используйте разумные таймауты для каждого окружения
- Настраивайте количество повторов в зависимости от критичности
- Используйте переопределения для изоляции окружений

### Управление статусами

- Переводите окружения в INACTIVE во время обслуживания
- Используйте мониторинг для автоматического обнаружения проблем
- Документируйте причины деактивации окружений

```swift
// Пример хорошей практики
let environments = [
    ServiceEnvironment(
        serviceID: serviceId,
        code: "dev",
        displayName: "Development",
        host: "http://localhost:8080",
        config: EnvironmentConfig(
            timeoutMs: 5000,
            retries: 1,
            downstreamOverrides: ["db": "localhost:5432"]
        ),
        status: .ACTIVE
    ),
    ServiceEnvironment(
        serviceID: serviceId,
        code: "prod",
        displayName: "Production",
        host: "https://api.example.com",
        config: EnvironmentConfig(
            timeoutMs: 30000,
            retries: 5,
            downstreamOverrides: ["db": "prod-db.example.com:5432"]
        ),
        status: .ACTIVE
    )
]
```