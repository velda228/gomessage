#!/bin/bash

echo "🚀 GoMessage API Демонстрация"
echo "================================"

# Базовый URL
BASE_URL="http://localhost:8080/api/v1"

echo ""
echo "1️⃣ Проверка здоровья сервера"
echo "----------------------------"
curl -s "$BASE_URL/../health" | jq '.'

echo ""
echo "2️⃣ Регистрация пользователя"
echo "---------------------------"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo_user","email":"demo@example.com","password":"demo123"}')
echo $REGISTER_RESPONSE | jq '.'

echo ""
echo "3️⃣ Вход пользователя"
echo "-------------------"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo_user","password":"demo123"}')
echo $LOGIN_RESPONSE | jq '.'

# Извлекаем токен
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

if [ "$TOKEN" != "null" ] && [ "$TOKEN" != "" ]; then
    echo ""
    echo "4️⃣ Получение профиля пользователя"
    echo "--------------------------------"
    curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/users/profile" | jq '.'

    echo ""
    echo "5️⃣ Поиск пользователей"
    echo "----------------------"
    curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/users/search?q=demo" | jq '.'

    echo ""
    echo "6️⃣ Создание чата"
    echo "----------------"
    CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/chats/" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"name":"Демо чат","type":"group","user_ids":[1]}')
    echo $CHAT_RESPONSE | jq '.'

    # Извлекаем ID чата
    CHAT_ID=$(echo $CHAT_RESPONSE | jq -r '.chat.id')

    if [ "$CHAT_ID" != "null" ] && [ "$CHAT_ID" != "" ]; then
        echo ""
        echo "7️⃣ Отправка сообщения"
        echo "---------------------"
        curl -s -X POST "$BASE_URL/messages/" \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"content\":\"Привет! Это демо сообщение\",\"type\":\"text\",\"chat_id\":$CHAT_ID}" | jq '.'

        echo ""
        echo "8️⃣ Получение сообщений чата"
        echo "----------------------------"
        curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/messages/chat/$CHAT_ID" | jq '.'

        echo ""
        echo "9️⃣ Получение списка чатов"
        echo "-------------------------"
        curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/chats/" | jq '.'
    fi
else
    echo "❌ Не удалось получить токен для дальнейших запросов"
fi

echo ""
echo "🎉 Демонстрация завершена!"
echo ""
echo "💡 Для тестирования WebSocket откройте http://localhost:8080 в браузере"
echo "🔌 WebSocket endpoint: ws://localhost:8080/ws"
