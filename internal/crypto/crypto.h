#ifndef CRYPTO_H
#define CRYPTO_H

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

// Хеширование пароля с солью
int hash_password(const char* password, const char* salt, char* hash, size_t hash_len);

// Проверка пароля
int verify_password(const char* password, const char* hash, const char* salt);

// Генерация случайной соли
int generate_salt(char* salt, size_t salt_len);

// Шифрование сообщения
int encrypt_message(const char* message, const char* key, char* encrypted, size_t* encrypted_len);

// Расшифровка сообщения
int decrypt_message(const char* encrypted, const char* key, char* decrypted, size_t* decrypted_len);

// Генерация JWT токена
int generate_jwt(const char* payload, const char* secret, char* token, size_t token_len);

// Проверка JWT токена
int verify_jwt(const char* token, const char* secret, char* payload, size_t* payload_len);

#ifdef __cplusplus
}
#endif

#endif // CRYPTO_H
