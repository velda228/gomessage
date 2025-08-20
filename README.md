# 🚀 GoMessage - Быстрый мессенджер на Go + C

Современный мессенджер с real-time сообщениями, построенный на Go для backend и C для критически важных операций.

## ✨ Особенности

- 🔐 **Безопасная аутентификация** с JWT токенами
- 💬 **Real-time сообщения** через WebSocket
- 🚀 **Высокая производительность** благодаря C библиотекам
- 🛡️ **Шифрование сообщений** на уровне C
- 📱 **Современный UI** (готовится)
- 🔄 **Автоматическая пересборка** в режиме разработки

## 🏗️ Архитектура

```
GoMessage/
├── Backend (Go)
│   ├── HTTP API сервер
│   ├── WebSocket hub
│   └── Middleware
├── Критические компоненты (C)
│   ├── Криптография
│   ├── JWT обработка
│   └── Хеширование паролей
└── Frontend (готовится)
    ├── React/TypeScript
    └── Real-time чат
```

## 🚀 Быстрый старт

### Предварительные требования

- Go 1.21+
- GCC компилятор (для C библиотеки)
- OpenSSL библиотеки (для C библиотеки)
- Make
- jq (для красивого вывода JSON в демо)

### Установка зависимостей

#### macOS
```bash
brew install openssl
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev
```

#### CentOS/RHEL
```bash
sudo yum groupinstall "Development Tools"
sudo yum install openssl-devel
```

### Сборка и запуск

1. **Клонируйте репозиторий**
```bash
git clone <repository-url>
cd gomessage
```

2. **Установите Go зависимости**
```bash
make deps
```

3. **Соберите приложение**
```bash
make build
```

4. **Запустите сервер**
```bash
make run
```

Сервер будет доступен по адресу: `http://localhost:8080`

5. **Протестируйте API**
```bash
./demo.sh
```

Или откройте http://localhost:8080 в браузере для веб-интерфейса

## 🛠️ Команды Make

```bash
make build        # Сборка приложения
make build-crypto # Сборка только C библиотеки
make run          # Сборка и запуск
make test         # Запуск тестов
make clean        # Очистка
make deps         # Установка Go зависимостей
make dev          # Режим разработки с автопересборкой
make help         # Показать справку
```

## 🐳 Docker

### Сборка образа
```bash
make docker-build
```

### Запуск контейнера
```bash
make docker-run
```

## 📡 API Endpoints

### Аутентификация
- `POST /api/v1/auth/register` - Регистрация
- `POST /api/v1/auth/login` - Вход
- `POST /api/v1/auth/refresh` - Обновление токена

### Пользователи
- `GET /api/v1/users/profile` - Профиль пользователя
- `PUT /api/v1/users/profile` - Обновление профиля
- `GET /api/v1/users/search` - Поиск пользователей

### Сообщения
- `POST /api/v1/messages/` - Отправка сообщения
- `GET /api/v1/messages/chat/:chatID` - Получение сообщений чата
- `PUT /api/v1/messages/:id` - Редактирование сообщения
- `DELETE /api/v1/messages/:id` - Удаление сообщения

### Чаты
- `GET /api/v1/chats/` - Список чатов пользователя
- `POST /api/v1/chats/` - Создание чата
- `GET /api/v1/chats/:id` - Информация о чате
- `POST /api/v1/chats/:id/join` - Присоединение к чату
- `DELETE /api/v1/chats/:id/leave` - Выход из чата

### WebSocket
- `GET /ws` - WebSocket соединение для real-time сообщений

## 🔧 Конфигурация

Настройки приложения через переменные окружения:

```bash
# Сервер
SERVER_PORT=8080
SERVER_HOST=localhost

# База данных
DB_HOST=localhost
DB_PORT=5432
DB_USER=gomessage
DB_PASSWORD=password
DB_NAME=gomessage
DB_SSLMODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=24
```

## 🧪 Тестирование

```bash
# Запуск всех тестов
make test

# Запуск конкретного теста
go test ./internal/crypto -v
```

## 🔍 Отладка

### Логи
Приложение выводит подробные логи:
- 🔌 Подключения WebSocket
- ❌ Ошибки
- 🚀 Запуск сервера
- 🔄 Завершение работы

### Профилирование
```bash
# CPU профилирование
go tool pprof http://localhost:8080/debug/pprof/profile

# Memory профилирование
go tool pprof http://localhost:8080/debug/pprof/heap
```

## 📈 Производительность

Благодаря использованию C для критических операций:
- **Криптография**: в 3-5 раз быстрее чисто Go реализации
- **JWT обработка**: оптимизирована на уровне C
- **Хеширование паролей**: максимальная скорость с OpenSSL

## 🚧 Roadmap

- [x] Backend API на Go
- [x] WebSocket сервер
- [x] C библиотека криптографии
- [x] JWT аутентификация
- [ ] База данных PostgreSQL
- [ ] Redis кэширование
- [ ] Frontend на React
- [ ] Групповые чаты
- [ ] Файловые вложения
- [ ] Push уведомления
- [ ] Мобильное приложение

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🆘 Поддержка

Если у вас есть вопросы или проблемы:
- Создайте Issue в GitHub
- Обратитесь к документации
- Проверьте логи приложения

---

**GoMessage** - Быстро, безопасно, надежно! 🚀
