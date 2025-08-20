# Многоэтапная сборка для Go + C приложения
FROM golang:1.21-alpine AS builder

# Устанавливаем необходимые пакеты для сборки
RUN apk add --no-cache \
    build-base \
    openssl-dev \
    git

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем go.mod и go.sum
COPY go.mod go.sum ./

# Скачиваем зависимости
RUN go mod download

# Копируем исходный код
COPY . .

# Собираем C библиотеку
RUN cd internal/crypto && \
    gcc -Wall -Wextra -O2 -fPIC -c crypto.c -o crypto.o && \
    gcc -shared crypto.o -o libcrypto.so -lcrypto -lssl

# Собираем Go приложение
RUN CGO_ENABLED=1 CGO_LDFLAGS="-L./internal/crypto -lcrypto" \
    go build -o gomessage .

# Финальный образ
FROM alpine:latest

# Устанавливаем необходимые пакеты для запуска
RUN apk add --no-cache \
    ca-certificates \
    openssl

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S gomessage && \
    adduser -u 1001 -S gomessage -G gomessage

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем собранное приложение и библиотеки
COPY --from=builder /app/gomessage .
COPY --from=builder /app/internal/crypto/libcrypto.so ./internal/crypto/

# Устанавливаем права доступа
RUN chown -R gomessage:gomessage /app

# Переключаемся на непривилегированного пользователя
USER gomessage

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["./gomessage"]
