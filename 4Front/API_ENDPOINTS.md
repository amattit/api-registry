# API Endpoints Reference

## Базовый URL
```
http://localhost:8080/api/v1
```

## Новые endpoints для зависимостей между сервисами

### 1. Создание зависимости между сервисами
```http
POST /services/{consumerServiceId}/service-dependencies
```

**Пример запроса:**
```json
{
  "providerServiceId": "123e4567-e89b-12d3-a456-426614174000",
  "environmentCode": "production",
  "description": "API calls for user authentication",
  "dependencyType": "API_CALL",
  "config": {
    "endpoint": "https://auth-service.example.com/api/v1",
    "timeout": "30s",
    "retries": "3"
  }
}
```

### 2. Получение зависимостей сервиса
```http
GET /services/{serviceId}/service-dependencies?environmentCode=production
```

### 3. Обновление зависимости
```http
PATCH /services/{serviceId}/service-dependencies/{dependencyId}
```

### 4. Удаление зависимости
```http
DELETE /services/{serviceId}/service-dependencies/{dependencyId}
```

### 5. Граф зависимостей сервиса
```http
GET /services/{serviceId}/dependency-graph?environmentCode=production
```

### 6. Глобальный граф зависимостей
```http
GET /dependency-graph?environmentCode=production
```

## Типы зависимостей между сервисами

- `API_CALL` - Вызовы API
- `EVENT_SUBSCRIPTION` - Подписка на события
- `DATA_SHARING` - Совместное использование данных
- `AUTHENTICATION` - Аутентификация
- `PROXY` - Проксирование запросов
- `LIBRARY_USAGE` - Использование библиотек

## Существующие endpoints

### Сервисы
- `GET /services` - Список сервисов
- `POST /services` - Создание сервиса
- `GET /services/{id}` - Получение сервиса
- `PATCH /services/{id}` - Обновление сервиса
- `DELETE /services/{id}` - Удаление сервиса

### Внешние зависимости
- `GET /dependencies` - Список зависимостей
- `POST /dependencies` - Создание зависимости
- `GET /dependencies/{id}` - Получение зависимости
- `PATCH /dependencies/{id}` - Обновление зависимости
- `DELETE /dependencies/{id}` - Удаление зависимости

### Базы данных
- `GET /databases` - Список баз данных
- `POST /databases` - Создание базы данных

### Endpoints
- `GET /services/{serviceId}/endpoints` - Endpoints сервиса
- `POST /services/{serviceId}/endpoints` - Создание endpoint

## Обработка ошибок

### Коды ответов
- `200` - Успешно
- `201` - Создано
- `204` - Нет содержимого (для DELETE)
- `400` - Неверный запрос
- `404` - Не найдено
- `409` - Конфликт (например, циклическая зависимость)
- `500` - Внутренняя ошибка сервера

### Формат ошибок
```json
{
  "error": true,
  "reason": "Service dependency already exists",
  "status": 409
}
```