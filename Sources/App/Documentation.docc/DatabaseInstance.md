# DatabaseInstance

Модель для представления экземпляра базы данных в системе.

## Обзор

Модель `DatabaseInstance` представляет экземпляр базы данных, который может использоваться сервисами. Поддерживает различные типы СУБД и содержит конфигурационную информацию для подключения.

```swift
final class DatabaseInstance: Model, Content, @unchecked Sendable {
    static let schema = "databases"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Enum(key: "database_type")
    var databaseType: DatabaseType
    
    @Field(key: "connection_string")
    var connectionString: String
    
    @Field(key: "config")
    var config: [String: String]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // Relationships
    @Children(for: \.$database)
    var serviceDbLinks: [ServiceDbLink]
}
```

## Поля модели

### Основные поля

| Поле | Тип | Описание | Обязательное |
|------|-----|----------|--------------|
| `id` | `UUID?` | Уникальный идентификатор БД | Нет (автогенерация) |
| `name` | `String` | Уникальное имя экземпляра БД | Да |
| `description` | `String?` | Описание назначения БД | Нет |
| `databaseType` | `DatabaseType` | Тип СУБД | Да |
| `connectionString` | `String` | Строка подключения | Да |
| `config` | `[String: String]` | Дополнительная конфигурация | Да (может быть пустой) |

### Временные метки

| Поле | Тип | Описание |
|------|-----|----------|
| `createdAt` | `Date?` | Время создания записи |
| `updatedAt` | `Date?` | Время последнего обновления |

### Связи (Relationships)

| Связь | Тип | Описание |
|-------|-----|----------|
| `serviceDbLinks` | `[ServiceDbLink]` | Связи с сервисами |

## DatabaseType

Перечисление поддерживаемых типов СУБД:

```swift
enum DatabaseType: String, Codable, CaseIterable, @unchecked Sendable {
    case POSTGRESQL = "POSTGRESQL"
    case MYSQL = "MYSQL"
    case MONGODB = "MONGODB"
    case REDIS = "REDIS"
    case ELASTICSEARCH = "ELASTICSEARCH"
    case CASSANDRA = "CASSANDRA"
    case SQLITE = "SQLITE"
    case ORACLE = "ORACLE"
    case MSSQL = "MSSQL"
}
```

### Поддерживаемые СУБД

| Тип | Описание | Типичное использование |
|-----|----------|------------------------|
| `POSTGRESQL` | PostgreSQL | Основная реляционная БД |
| `MYSQL` | MySQL/MariaDB | Реляционная БД |
| `MONGODB` | MongoDB | Документо-ориентированная БД |
| `REDIS` | Redis | Кэш и очереди |
| `ELASTICSEARCH` | Elasticsearch | Поиск и аналитика |
| `CASSANDRA` | Apache Cassandra | Распределенная NoSQL |
| `SQLITE` | SQLite | Встроенная БД |
| `ORACLE` | Oracle Database | Корпоративная БД |
| `MSSQL` | Microsoft SQL Server | Корпоративная БД |

## Инициализация

### Конструктор по умолчанию

```swift
init() { }
```

### Полный конструктор

```swift
init(
    id: UUID? = nil,
    name: String,
    description: String? = nil,
    databaseType: DatabaseType,
    connectionString: String,
    config: [String: String] = [:]
)
```

#### Параметры

- `id`: Уникальный идентификатор (опционально)
- `name`: Имя экземпляра БД
- `description`: Описание назначения
- `databaseType`: Тип СУБД
- `connectionString`: Строка подключения
- `config`: Дополнительная конфигурация

## Примеры использования

### PostgreSQL база данных

```swift
let postgresDB = DatabaseInstance(
    name: "users-postgres-prod",
    description: "Основная PostgreSQL база для пользователей",
    databaseType: .POSTGRESQL,
    connectionString: "postgresql://app_user:password@db.example.com:5432/users_db",
    config: [
        "max_connections": "100",
        "ssl_mode": "require",
        "statement_timeout": "30000",
        "idle_in_transaction_session_timeout": "60000",
        "timezone": "UTC"
    ]
)
```

### Redis кэш

```swift
let redisCache = DatabaseInstance(
    name: "session-redis-prod",
    description: "Redis для хранения пользовательских сессий",
    databaseType: .REDIS,
    connectionString: "redis://cache.example.com:6379/0",
    config: [
        "max_memory": "2gb",
        "maxmemory_policy": "allkeys-lru",
        "timeout": "300",
        "tcp_keepalive": "60",
        "databases": "16"
    ]
)
```

### MongoDB документная БД

```swift
let mongoDB = DatabaseInstance(
    name: "analytics-mongo-prod",
    description: "MongoDB для аналитических данных",
    databaseType: .MONGODB,
    connectionString: "mongodb://analytics:password@mongo.example.com:27017/analytics",
    config: [
        "replica_set": "rs0",
        "read_preference": "secondaryPreferred",
        "write_concern": "majority",
        "read_concern": "majority",
        "max_pool_size": "50"
    ]
)
```

### Elasticsearch поисковая БД

```swift
let elasticDB = DatabaseInstance(
    name: "search-elasticsearch-prod",
    description: "Elasticsearch для полнотекстового поиска",
    databaseType: .ELASTICSEARCH,
    connectionString: "https://search.example.com:9200",
    config: [
        "cluster_name": "production",
        "number_of_shards": "3",
        "number_of_replicas": "1",
        "refresh_interval": "1s",
        "max_result_window": "10000"
    ]
)
```

### MySQL база данных

```swift
let mysqlDB = DatabaseInstance(
    name: "orders-mysql-prod",
    description: "MySQL база для заказов",
    databaseType: .MYSQL,
    connectionString: "mysql://orders_user:password@mysql.example.com:3306/orders",
    config: [
        "charset": "utf8mb4",
        "collation": "utf8mb4_unicode_ci",
        "max_connections": "200",
        "innodb_buffer_pool_size": "1G",
        "query_cache_size": "256M"
    ]
)
```

## Конфигурационные параметры

### PostgreSQL

| Параметр | Описание | Пример значения |
|----------|----------|-----------------|
| `max_connections` | Максимальное количество подключений | `100` |
| `ssl_mode` | Режим SSL | `require`, `prefer`, `disable` |
| `statement_timeout` | Таймаут выполнения запроса (мс) | `30000` |
| `timezone` | Часовой пояс | `UTC`, `Europe/Moscow` |
| `search_path` | Путь поиска схем | `public,app` |

### Redis

| Параметр | Описание | Пример значения |
|----------|----------|-----------------|
| `max_memory` | Максимальный объем памяти | `2gb`, `512mb` |
| `maxmemory_policy` | Политика вытеснения | `allkeys-lru`, `volatile-lru` |
| `timeout` | Таймаут подключения | `300` |
| `databases` | Количество баз данных | `16` |

### MongoDB

| Параметр | Описание | Пример значения |
|----------|----------|-----------------|
| `replica_set` | Имя replica set | `rs0` |
| `read_preference` | Предпочтение чтения | `primary`, `secondary` |
| `write_concern` | Гарантии записи | `majority`, `1` |
| `max_pool_size` | Размер пула подключений | `50` |

### Elasticsearch

| Параметр | Описание | Пример значения |
|----------|----------|-----------------|
| `cluster_name` | Имя кластера | `production` |
| `number_of_shards` | Количество шардов | `3` |
| `number_of_replicas` | Количество реплик | `1` |
| `refresh_interval` | Интервал обновления индекса | `1s` |

## Строки подключения

### Форматы строк подключения

#### PostgreSQL
```
postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
```

Примеры:
```
postgresql://localhost/mydb
postgresql://user:pass@localhost:5432/mydb
postgresql://user:pass@host:5432/mydb?sslmode=require
```

#### MySQL
```
mysql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
```

Примеры:
```
mysql://localhost:3306/mydb
mysql://user:pass@localhost:3306/mydb
mysql://user:pass@host:3306/mydb?charset=utf8mb4
```

#### MongoDB
```
mongodb://[user[:password]@][host][:port][/database][?options]
```

Примеры:
```
mongodb://localhost:27017/mydb
mongodb://user:pass@localhost:27017/mydb
mongodb://user:pass@host1:27017,host2:27017/mydb?replicaSet=rs0
```

#### Redis
```
redis://[user[:password]@][host][:port][/database]
```

Примеры:
```
redis://localhost:6379
redis://localhost:6379/0
redis://user:pass@host:6379/1
```

#### Elasticsearch
```
https://[user[:password]@][host][:port]
```

Примеры:
```
http://localhost:9200
https://elastic:pass@search.example.com:9200
```

## Валидация

### Бизнес-правила

1. **Уникальность имени**: Имя экземпляра БД должно быть уникальным
2. **Валидная строка подключения**: Должна соответствовать формату для типа БД
3. **Обязательные поля**: `name`, `databaseType`, `connectionString`
4. **Безопасность**: Пароли в строках подключения должны быть зашифрованы

### Примеры валидации

```swift
func validateDatabase(_ db: DatabaseInstance) throws {
    // Валидация имени
    guard !db.name.isEmpty else {
        throw ValidationError("Имя базы данных не может быть пустым")
    }
    
    // Валидация строки подключения
    guard !db.connectionString.isEmpty else {
        throw ValidationError("Строка подключения обязательна")
    }
    
    // Валидация формата строки подключения
    try validateConnectionString(db.connectionString, for: db.databaseType)
    
    // Валидация конфигурации
    try validateConfig(db.config, for: db.databaseType)
}

func validateConnectionString(_ connectionString: String, for type: DatabaseType) throws {
    switch type {
    case .POSTGRESQL:
        guard connectionString.hasPrefix("postgresql://") else {
            throw ValidationError("PostgreSQL строка подключения должна начинаться с 'postgresql://'")
        }
    case .MYSQL:
        guard connectionString.hasPrefix("mysql://") else {
            throw ValidationError("MySQL строка подключения должна начинаться с 'mysql://'")
        }
    case .REDIS:
        guard connectionString.hasPrefix("redis://") else {
            throw ValidationError("Redis строка подключения должна начинаться с 'redis://'")
        }
    // ... другие типы
    }
}
```

## Связанные типы

- <doc:ServiceDbLink> - Связи с сервисами
- <doc:DatabaseDTOs> - DTO для работы с базами данных

## База данных

### Схема таблицы

```sql
CREATE TABLE databases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    database_type VARCHAR(50) NOT NULL,
    connection_string VARCHAR(1000) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Индексы

```sql
-- Уникальный индекс на имя
CREATE UNIQUE INDEX idx_databases_name ON databases(name);

-- Индекс на тип БД
CREATE INDEX idx_databases_type ON databases(database_type);

-- GIN индекс для поиска по конфигурации
CREATE INDEX idx_databases_config ON databases USING GIN(config);
```

## Лучшие практики

### Именование баз данных

- Включайте назначение: `users-postgres-prod`, `cache-redis-dev`
- Включайте тип БД: `analytics-mongo`, `search-elastic`
- Включайте окружение: `prod`, `staging`, `dev`

### Безопасность

- Используйте отдельные учетные записи для каждого сервиса
- Ограничивайте права доступа по принципу минимальных привилегий
- Шифруйте пароли в строках подключения
- Используйте SSL/TLS для подключений

### Конфигурация

- Настраивайте пулы подключений в зависимости от нагрузки
- Используйте разумные таймауты
- Настраивайте мониторинг и алерты
- Документируйте специфичные настройки

```swift
// Пример хорошей практики
let databases = [
    // Production PostgreSQL
    DatabaseInstance(
        name: "users-postgres-prod",
        description: "Основная база пользователей для production",
        databaseType: .POSTGRESQL,
        connectionString: "postgresql://users_app:${ENCRYPTED_PASSWORD}@db-prod.example.com:5432/users",
        config: [
            "max_connections": "100",
            "ssl_mode": "require",
            "statement_timeout": "30000",
            "application_name": "users-service"
        ]
    ),
    
    // Redis cache
    DatabaseInstance(
        name: "session-redis-prod",
        description: "Redis для пользовательских сессий",
        databaseType: .REDIS,
        connectionString: "redis://session_app:${ENCRYPTED_PASSWORD}@cache-prod.example.com:6379/0",
        config: [
            "max_memory": "2gb",
            "maxmemory_policy": "allkeys-lru",
            "timeout": "300"
        ]
    )
]
```