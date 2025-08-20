package crypto

/*
#cgo CFLAGS: -I. -I/usr/local/opt/openssl@3/include
#cgo LDFLAGS: -L/usr/local/opt/openssl@3/lib -Wl,-rpath,/usr/local/opt/openssl@3/lib -lssl -lcrypto
#include "crypto.h"
*/
import "C"
import (
	"encoding/base64"
	"errors"
)

// CryptoService предоставляет методы для работы с криптографией
type CryptoService struct{}

// NewCryptoService создает новый экземпляр CryptoService
func NewCryptoService() *CryptoService {
	return &CryptoService{}
}

// HashPassword хеширует пароль с солью
func (c *CryptoService) HashPassword(password, salt string) (string, error) {
	// 64 байта -> 128 hex + NUL
	hash := make([]C.char, 129)
	
	result := C.hash_password(
		C.CString(password),
		C.CString(salt),
		&hash[0],
		129,
	)
	
	if result != 0 {
		return "", errors.New("ошибка хеширования пароля")
	}
	
	return C.GoString(&hash[0]), nil
}

// VerifyPassword проверяет пароль
func (c *CryptoService) VerifyPassword(password, hash, salt string) bool {
	result := C.verify_password(
		C.CString(password),
		C.CString(hash),
		C.CString(salt),
	)
	
	return result == 0
}

// GenerateSalt генерирует случайную соль
func (c *CryptoService) GenerateSalt() (string, error) {
	// 32 байта -> 64 hex + NUL
	salt := make([]C.char, 65)
	
	result := C.generate_salt(&salt[0], 65)
	
	if result != 0 {
		return "", errors.New("ошибка генерации соли")
	}
	
	return C.GoString(&salt[0]), nil
}

// EncryptMessage шифрует сообщение
func (c *CryptoService) EncryptMessage(message, key string) (string, error) {
	encrypted := make([]C.char, 1024)
	var encryptedLen C.size_t
	
	result := C.encrypt_message(
		C.CString(message),
		C.CString(key),
		&encrypted[0],
		&encryptedLen,
	)
	
	if result != 0 {
		return "", errors.New("ошибка шифрования сообщения")
	}
	
	encryptedStr := C.GoStringN(&encrypted[0], C.int(encryptedLen))
	return base64.StdEncoding.EncodeToString([]byte(encryptedStr)), nil
}

// DecryptMessage расшифровывает сообщение
func (c *CryptoService) DecryptMessage(encrypted, key string) (string, error) {
	decoded, err := base64.StdEncoding.DecodeString(encrypted)
	if err != nil {
		return "", err
	}
	
	decrypted := make([]C.char, 1025)
	var decryptedLen C.size_t
	
	result := C.decrypt_message(
		C.CString(string(decoded)),
		C.CString(key),
		&decrypted[0],
		&decryptedLen,
	)
	
	if result != 0 {
		return "", errors.New("ошибка расшифровки сообщения")
	}
	
	return C.GoStringN(&decrypted[0], C.int(decryptedLen)), nil
}

// GenerateJWT генерирует JWT токен
func (c *CryptoService) GenerateJWT(payload, secret string) (string, error) {
	token := make([]C.char, 512)
	
	result := C.generate_jwt(
		C.CString(payload),
		C.CString(secret),
		&token[0],
		512,
	)
	
	if result != 0 {
		return "", errors.New("ошибка генерации JWT")
	}
	
	return C.GoString(&token[0]), nil
}

// VerifyJWT проверяет JWT токен
func (c *CryptoService) VerifyJWT(token, secret string) (string, error) {
	payload := make([]C.char, 512)
	var payloadLen C.size_t
	
	result := C.verify_jwt(
		C.CString(token),
		C.CString(secret),
		&payload[0],
		&payloadLen,
	)
	
	if result != 0 {
		return "", errors.New("ошибка проверки JWT")
	}
	
	return C.GoStringN(&payload[0], C.int(payloadLen)), nil
}
