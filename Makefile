.PHONY: build clean test run build-crypto

# Переменные
C_DIR = internal/crypto
GO_DIR = .
BINARY_NAME = gomessage
LIB_NAME = libcrypto

# Компиляторы
CC = gcc
GO = go

# Флаги компиляции
CFLAGS = -Wall -Wextra -O2 -fPIC
LDFLAGS = -shared -lcrypto -lssl

# Цели по умолчанию
all: build-crypto build

# Сборка C библиотеки
build-crypto:
	@echo "🔨 Сборка C библиотеки криптографии..."
	$(CC) $(CFLAGS) -I/usr/local/opt/openssl@3/include -c $(C_DIR)/crypto.c -o $(C_DIR)/crypto.o
	ar rcs $(C_DIR)/$(LIB_NAME).a $(C_DIR)/crypto.o
	@echo "✅ C библиотека собрана (статическая)"

# Сборка Go приложения
build: build-crypto
	@echo "🔨 Сборка Go приложения..."
	CGO_CFLAGS="-I/usr/local/opt/openssl@3/include" CGO_LDFLAGS="-L/usr/local/opt/openssl@3/lib -lcrypto -lssl" $(GO) build -o $(BINARY_NAME) $(GO_DIR)
	@echo "✅ Go приложение собрано"

# Запуск приложения
run: build
	@echo "🚀 Запуск приложения..."
	./$(BINARY_NAME)

# Запуск с внешним доступом
run-external: build
	@echo "🌐 Запуск с внешним доступом..."
	@echo "📱 Теперь вы можете зайти с телефона по IP адресу вашего компьютера"
	@echo ""
	@IP_ADDRESS=$$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $$2}' | head -1); \
	if [ -z "$$IP_ADDRESS" ]; then \
		IP_ADDRESS="127.0.0.1"; \
	fi; \
	echo "🖥️  IP адрес вашего компьютера: $$IP_ADDRESS"; \
	echo "🔗 Ссылка для доступа: http://$$IP_ADDRESS:8080"; \
	echo ""; \
	echo "🚀 Запуск сервера на 0.0.0.0:8080..."; \
	SERVER_HOST="0.0.0.0" SERVER_PORT="8080" ./$(BINARY_NAME)

# Тестирование
test:
	@echo "🧪 Запуск тестов..."
	$(GO) test ./...

# Очистка
clean:
	@echo "🧹 Очистка..."
	rm -f $(C_DIR)/*.o $(C_DIR)/*.so $(BINARY_NAME)
	@echo "✅ Очистка завершена"

# Установка зависимостей Go
deps:
	@echo "📦 Установка зависимостей Go..."
	$(GO) mod tidy
	$(GO) mod download

# Установка системных зависимостей (Ubuntu/Debian)
install-deps-ubuntu:
	@echo "📦 Установка системных зависимостей..."
	sudo apt-get update
	sudo apt-get install -y build-essential libssl-dev

# Установка системных зависимостей (macOS)
install-deps-macos:
	@echo "📦 Установка системных зависимостей..."
	brew install openssl

# Разработка (автоматическая пересборка при изменениях)
dev: build
	@echo "🔄 Режим разработки - отслеживание изменений..."
	@while true; do \
		inotifywait -r -e modify,create,delete .; \
		echo "🔄 Изменения обнаружены, пересборка..."; \
		make build; \
	done

# Docker сборка
docker-build:
	@echo "🐳 Сборка Docker образа..."
	docker build -t gomessage .

# Docker запуск
docker-run:
	@echo "🐳 Запуск Docker контейнера..."
	docker run -p 8080:8080 gomessage

# Помощь
help:
	@echo "Доступные команды:"
	@echo "  build        - Сборка приложения"
	@echo "  build-crypto - Сборка только C библиотеки"
	@echo "  run          - Сборка и запуск"
	@echo "  run-external - Сборка и запуск с внешним доступом (для телефона)"
	@echo "  test         - Запуск тестов"
	@echo "  clean        - Очистка"
	@echo "  deps         - Установка Go зависимостей"
	@echo "  install-deps-ubuntu - Установка системных зависимостей (Ubuntu)"
	@echo "  install-deps-macos   - Установка системных зависимостей (macOS)"
	@echo "  dev          - Режим разработки с автопересборкой"
	@echo "  docker-build - Сборка Docker образа"
	@echo "  docker-run   - Запуск Docker контейнера"
	@echo "  help         - Показать эту справку"
