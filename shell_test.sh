#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8080/api/v1"

echo -e "${GREEN}Начинаем наполнение БД тестовыми данными...${NC}\n"

# Функция для выполнения HTTP запросов с обработкой ошибок
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}${description}...${NC}"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ Успешно (код: $http_code)${NC}"
        echo "$body"
    else
        echo -e "${RED}✗ Ошибка (код: $http_code)${NC}"
        echo "$body"
        return 1
    fi
    
    return 0
}

# 1. Создание сервисов
echo -e "\n${GREEN}=== Создание сервисов ===${NC}"

# Сервис 1: Пользовательский сервис
USER_SERVICE=$(make_request "POST" "${BASE_URL}/services" '{
    "name": "User Service",
    "version": "1.0.0",
    "type": "internal",
    "owner": "Backend Team",
    "description": "Сервис для управления пользователями"
}')

USER_SERVICE_ID=$(echo $USER_SERVICE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан User Service с ID: $USER_SERVICE_ID"

# Сервис 2: Сервис заказов
ORDER_SERVICE=$(make_request "POST" "${BASE_URL}/services" '{
    "name": "Order Service",
    "version": "2.1.0",
    "type": "internal",
    "owner": "E-commerce Team",
    "description": "Сервис для обработки заказов"
}')

ORDER_SERVICE_ID=$(echo $ORDER_SERVICE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан Order Service с ID: $ORDER_SERVICE_ID"

# Сервис 3: Внешний платежный сервис
PAYMENT_SERVICE=$(make_request "POST" "${BASE_URL}/services" '{
    "name": "Payment Gateway",
    "version": "3.0.0",
    "type": "external",
    "owner": "Payment Provider Inc.",
    "description": "Внешний платежный шлюз"
}')

PAYMENT_SERVICE_ID=$(echo $PAYMENT_SERVICE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан Payment Gateway с ID: $PAYMENT_SERVICE_ID"

# 2. Создание окружений для сервисов
echo -e "\n${GREEN}=== Создание окружений сервисов ===${NC}"

# Окружения для User Service
make_request "POST" "${BASE_URL}/services/${USER_SERVICE_ID}/env" '{
    "type": "development",
    "host": "http://user-service-dev:8080"
}'

make_request "POST" "${BASE_URL}/services/${USER_SERVICE_ID}/env" '{
    "type": "production",
    "host": "https://api.users.com"
}'

# Окружения для Order Service
make_request "POST" "${BASE_URL}/services/${ORDER_SERVICE_ID}/env" '{
    "type": "development",
    "host": "http://order-service-dev:8081"
}'

make_request "POST" "${BASE_URL}/services/${ORDER_SERVICE_ID}/env" '{
    "type": "staging",
    "host": "https://staging.orders.com"
}'

# 3. Создание схем данных
echo -e "\n${GREEN}=== Создание схем данных ===${NC}"

# Схема для пользователя
USER_SCHEMA=$(make_request "POST" "${BASE_URL}/schemas" '{
    "name": "User",
    "attributes": [
        {
            "name": "id",
            "type": "UUID",
            "isNullable": false,
            "description": "Уникальный идентификатор пользователя",
            "defaultValue": null
        },
        {
            "name": "email",
            "type": "String",
            "isNullable": false,
            "description": "Email пользователя",
            "defaultValue": null
        },
        {
            "name": "firstName",
            "type": "String",
            "isNullable": true,
            "description": "Имя пользователя",
            "defaultValue": null
        },
        {
            "name": "lastName",
            "type": "String",
            "isNullable": true,
            "description": "Фамилия пользователя",
            "defaultValue": null
        },
        {
            "name": "createdAt",
            "type": "DateTime",
            "isNullable": false,
            "description": "Дата создания",
            "defaultValue": "now()"
        }
    ]
}')

USER_SCHEMA_ID=$(echo $USER_SCHEMA | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создана схема User с ID: $USER_SCHEMA_ID"

# Схема для заказа
ORDER_SCHEMA=$(make_request "POST" "${BASE_URL}/schemas" '{
    "name": "Order",
    "attributes": [
        {
            "name": "id",
            "type": "UUID",
            "isNullable": false,
            "description": "Уникальный идентификатор заказа",
            "defaultValue": null
        },
        {
            "name": "userId",
            "type": "UUID",
            "isNullable": false,
            "description": "ID пользователя",
            "defaultValue": null
        },
        {
            "name": "totalAmount",
            "type": "Decimal",
            "isNullable": false,
            "description": "Общая сумма заказа",
            "defaultValue": "0.00"
        },
        {
            "name": "status",
            "type": "String",
            "isNullable": false,
            "description": "Статус заказа",
            "defaultValue": "PENDING"
        },
        {
            "name": "items",
            "type": "Array<OrderItem>",
            "isNullable": true,
            "description": "Список товаров в заказе",
            "defaultValue": null
        }
    ]
}')

ORDER_SCHEMA_ID=$(echo $ORDER_SCHEMA | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создана схема Order с ID: $ORDER_SCHEMA_ID"

# Схема для ошибки
ERROR_SCHEMA=$(make_request "POST" "${BASE_URL}/schemas" '{
    "name": "ErrorResponse",
    "attributes": [
        {
            "name": "error",
            "type": "String",
            "isNullable": false,
            "description": "Текст ошибки",
            "defaultValue": null
        },
        {
            "name": "code",
            "type": "String",
            "isNullable": false,
            "description": "Код ошибки",
            "defaultValue": null
        },
        {
            "name": "timestamp",
            "type": "DateTime",
            "isNullable": false,
            "description": "Время возникновения ошибки",
            "defaultValue": "now()"
        }
    ]
}')

ERROR_SCHEMA_ID=$(echo $ERROR_SCHEMA | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создана схема ErrorResponse с ID: $ERROR_SCHEMA_ID"

# 4. Создание API вызовов
echo -e "\n${GREEN}=== Создание API вызовов ===${NC}"

# API вызовы для User Service
USER_API_CREATE=$(make_request "POST" "${BASE_URL}/services/${USER_SERVICE_ID}/calls" '{
    "path": "/api/users",
    "method": "POST",
    "description": "Создание нового пользователя",
    "tags": ["users", "registration"],
    "serviceID": "'${USER_SERVICE_ID}'"
}')

USER_API_CREATE_ID=$(echo $USER_API_CREATE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан API вызов для создания пользователя с ID: $USER_API_CREATE_ID"

USER_API_GET=$(make_request "POST" "${BASE_URL}/services/${USER_SERVICE_ID}/calls" '{
    "path": "/api/users/{id}",
    "method": "GET",
    "description": "Получение пользователя по ID",
    "tags": ["users", "retrieval"],
    "serviceID": "'${USER_SERVICE_ID}'"
}')

USER_API_GET_ID=$(echo $USER_API_GET | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан API вызов для получения пользователя с ID: $USER_API_GET_ID"

USER_API_LIST=$(make_request "POST" "${BASE_URL}/services/${USER_SERVICE_ID}/calls" '{
    "path": "/api/users",
    "method": "GET",
    "description": "Получение списка пользователей",
    "tags": ["users", "list"],
    "serviceID": "'${USER_SERVICE_ID}'"
}')

USER_API_LIST_ID=$(echo $USER_API_LIST | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан API вызов для списка пользователей с ID: $USER_API_LIST_ID"

# API вызовы для Order Service
ORDER_API_CREATE=$(make_request "POST" "${BASE_URL}/services/${ORDER_SERVICE_ID}/calls" '{
    "path": "/api/orders",
    "method": "POST",
    "description": "Создание нового заказа",
    "tags": ["orders", "create"],
    "serviceID": "'${ORDER_SERVICE_ID}'"
}')

ORDER_API_CREATE_ID=$(echo $ORDER_API_CREATE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан API вызов для создания заказа с ID: $ORDER_API_CREATE_ID"

ORDER_API_GET=$(make_request "POST" "${BASE_URL}/services/${ORDER_SERVICE_ID}/calls" '{
    "path": "/api/orders/{id}",
    "method": "GET",
    "description": "Получение заказа по ID",
    "tags": ["orders", "retrieval"],
    "serviceID": "'${ORDER_SERVICE_ID}'"
}')

ORDER_API_GET_ID=$(echo $ORDER_API_GET | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан API вызов для получения заказа с ID: $ORDER_API_GET_ID"

# 5. Создание параметров для API вызовов
echo -e "\n${GREEN}=== Создание параметров API ===${NC}"

# Параметры для создания пользователя
make_request "POST" "${BASE_URL}/calls/${USER_API_CREATE_ID}/parameter" '{
    "name": "email",
    "type": "String",
    "location": "body",
    "required": true,
    "description": "Email пользователя",
    "example": "user@example.com",
    "apiCallID": "'${USER_API_CREATE_ID}'"
}'

make_request "POST" "${BASE_URL}/calls/${USER_API_CREATE_ID}/parameter" '{
    "name": "firstName",
    "type": "String",
    "location": "body",
    "required": false,
    "description": "Имя пользователя",
    "example": "John",
    "apiCallID": "'${USER_API_CREATE_ID}'"
}'

# Параметры для получения пользователя
make_request "POST" "${BASE_URL}/calls/${USER_API_GET_ID}/parameter" '{
    "name": "id",
    "type": "UUID",
    "location": "path",
    "required": true,
    "description": "ID пользователя",
    "example": "123e4567-e89b-12d3-a456-426614174000",
    "apiCallID": "'${USER_API_GET_ID}'"
}'

# Параметры для создания заказа
make_request "POST" "${BASE_URL}/calls/${ORDER_API_CREATE_ID}/parameter" '{
    "name": "userId",
    "type": "UUID",
    "location": "body",
    "required": true,
    "description": "ID пользователя",
    "example": "123e4567-e89b-12d3-a456-426614174000",
    "apiCallID": "'${ORDER_API_CREATE_ID}'"
}'

# 6. Создание ответов для API вызовов
echo -e "\n${GREEN}=== Создание ответов API ===${NC}"

# Ответ для успешного создания пользователя
USER_CREATE_RESPONSE=$(make_request "POST" "${BASE_URL}/calls/${USER_API_CREATE_ID}/responses" '{
    "statusCode": 201,
    "description": "Пользователь успешно создан",
    "contentType": "application/json",
    "examples": {
        "success": "{\"id\": \"123e4567-e89b-12d3-a456-426614174000\", \"email\": \"user@example.com\", \"createdAt\": \"2023-12-09T10:30:00Z\"}"
    },
    "headers": {
        "Location": "/api/users/123e4567-e89b-12d3-a456-426614174000"
    }
}')

USER_CREATE_RESPONSE_ID=$(echo $USER_CREATE_RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан ответ 201 для создания пользователя с ID: $USER_CREATE_RESPONSE_ID"

# Ответ для получения пользователя
USER_GET_RESPONSE=$(make_request "POST" "${BASE_URL}/calls/${USER_API_GET_ID}/responses" '{
    "statusCode": 200,
    "description": "Данные пользователя",
    "contentType": "application/json",
    "examples": {
        "success": "{\"id\": \"123e4567-e89b-12d3-a456-426614174000\", \"email\": \"user@example.com\", \"firstName\": \"John\", \"lastName\": \"Doe\"}"
    }
}')

USER_GET_RESPONSE_ID=$(echo $USER_GET_RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан ответ 200 для получения пользователя с ID: $USER_GET_RESPONSE_ID"

# Ответ об ошибке
USER_ERROR_RESPONSE=$(make_request "POST" "${BASE_URL}/calls/${USER_API_GET_ID}/responses" '{
    "statusCode": 404,
    "description": "Пользователь не найден",
    "contentType": "application/json",
    "examples": {
        "error": "{\"error\": \"User not found\", \"code\": \"USER_NOT_FOUND\", \"timestamp\": \"2023-12-09T10:30:00Z\"}"
    }
}')

USER_ERROR_RESPONSE_ID=$(echo $USER_ERROR_RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "Создан ответ 404 для пользователя с ID: $USER_ERROR_RESPONSE_ID"

# 7. Связывание схем с ответами
echo -e "\n${GREEN}=== Связывание схем с ответами ===${NC}"

# Связывание схемы User с успешным ответом получения пользователя
make_request "POST" "${BASE_URL}/calls/link-schema-response" '{
    "responseID": "'${USER_GET_RESPONSE_ID}'",
    "schemaID": "'${USER_SCHEMA_ID}'"
}'

# Связывание схемы ErrorResponse с ответом об ошибке
make_request "POST" "${BASE_URL}/calls/link-schema-response" '{
    "responseID": "'${USER_ERROR_RESPONSE_ID}'",
    "schemaID": "'${ERROR_SCHEMA_ID}'"
}'

# Связывание схемы Order с запросом создания заказа
make_request "POST" "${BASE_URL}/calls/link-schema-request" '{
    "apiCallId": "'${ORDER_API_CREATE_ID}'",
    "schemaID": "'${ORDER_SCHEMA_ID}'"
}'

echo -e "\n${GREEN}✅ Наполнение БД тестовыми данными завершено!${NC}"
echo -e "\nСоздано:"
echo "- 3 сервиса"
echo "- 6 API вызовов"
echo "- 5 окружений"
echo "- 3 схемы с атрибутами"
echo "- 4 параметра API"
echo "- 3 ответа API"
echo "- 3 связи схем с ответами/запросами"