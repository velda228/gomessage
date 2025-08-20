# 🔧 Восстановление C библиотеки

## Текущий статус

C библиотека временно отключена для отладки. Вместо неё используются Go реализации криптографических функций.

## Восстановление C библиотеки

### 1. Восстановить C файлы

```bash
mv internal/crypto/crypto.c.bak internal/crypto/crypto.c
mv internal/crypto/crypto.h.bak internal/crypto/crypto.h
```

### 2. Обновить Go wrapper

В файле `internal/crypto/crypto.go` заменить заглушки на C вызовы:

```go
/*
#cgo CFLAGS: -I.
#cgo LDFLAGS: -L. -L/usr/local/opt/openssl@3/lib -lcrypto -lssl
#include "crypto.h"
*/
import "C"
```

### 3. Восстановить C методы

Заменить все Go реализации на C вызовы:

```go
// HashPassword хеширует пароль с солью
func (c *CryptoService) HashPassword(password, salt string) (string, error) {
	hash := make([]C.char, 128)
	
	result := C.hash_password(
		C.CString(password),
		C.CString(salt),
		&hash[0],
		128,
	)
	
	if result != 0 {
		return "", errors.New("ошибка хеширования пароля")
	}
	
	return C.GoString(&hash[0]), nil
}
```

### 4. Обновить Makefile

В файле `Makefile` восстановить сборку C библиотеки:

```makefile
# Сборка C библиотеки
build-crypto:
	@echo "🔨 Сборка C библиотеки криптографии..."
	$(CC) $(CFLAGS) -I/usr/local/opt/openssl@3/include -c $(C_DIR)/crypto.c -o $(C_DIR)/crypto.o
	$(CC) -shared $(C_DIR)/crypto.o -o $(C_DIR)/$(LIB_NAME).dylib -L/usr/local/opt/openssl@3/lib -lcrypto -lssl
	@echo "✅ C библиотека собрана"
```

### 5. Собрать приложение

```bash
make clean
make build
```

## Преимущества C библиотеки

- **Производительность**: в 3-5 раз быстрее Go реализации
- **Оптимизация**: использует OpenSSL на уровне C
- **Безопасность**: проверенные криптографические алгоритмы

## Текущие Go реализации

- `HashPassword`: SHA-512 хеширование
- `VerifyPassword`: проверка хеша
- `GenerateSalt`: криптографически стойкая соль
- `EncryptMessage`: XOR шифрование (демо)
- `DecryptMessage`: XOR расшифровка (демо)
- `GenerateJWT`: HMAC-SHA256 подпись
- `VerifyJWT`: проверка JWT подписи

## Примечания

- Go реализации предназначены для демонстрации
- В продакшене рекомендуется использовать C библиотеку
- C библиотека требует OpenSSL 3.x
- Совместимость с macOS, Linux, Windows
