#!/bin/bash

echo "🌐 Запуск GoMessage с внешним доступом..."
echo "📱 Теперь вы можете зайти с телефона по IP адресу вашего компьютера"
echo ""

# Получаем IP адрес компьютера
IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS="127.0.0.1"
fi

echo "🖥️  IP адрес вашего компьютера: $IP_ADDRESS"
echo "🔗 Ссылка для доступа: http://$IP_ADDRESS:8080"
echo ""

# Устанавливаем переменные окружения для внешнего доступа
export SERVER_HOST="0.0.0.0"
export SERVER_PORT="8080"

echo "🚀 Запуск сервера на $SERVER_HOST:$SERVER_PORT..."
echo ""

# Запускаем сервер
./gomessage

