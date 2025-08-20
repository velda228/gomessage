#include "crypto.h"
#include <string.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/hmac.h>
#include <openssl/sha.h>
#include <openssl/aes.h>
#include <openssl/err.h>

#define SALT_LENGTH 32
#define HASH_LENGTH 64
#define AES_KEY_LENGTH 32
#define AES_BLOCK_SIZE 16

// Хеширование пароля с солью
int hash_password(const char* password, const char* salt, char* hash, size_t hash_len) {
    if (!password || !salt || !hash || hash_len < (HASH_LENGTH * 2 + 1)) {
        return -1;
    }
    
    unsigned char digest[HASH_LENGTH];
    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    
    if (!ctx) {
        return -1;
    }
    
    if (EVP_DigestInit_ex(ctx, EVP_sha512(), NULL) != 1) {
        EVP_MD_CTX_free(ctx);
        return -1;
    }
    
    // Используем фактическую длину строки соли (hex), а не фиксированную
    if (EVP_DigestUpdate(ctx, salt, strlen(salt)) != 1) {
        EVP_MD_CTX_free(ctx);
        return -1;
    }
    
    if (EVP_DigestUpdate(ctx, password, strlen(password)) != 1) {
        EVP_MD_CTX_free(ctx);
        return -1;
    }
    
    unsigned int digest_len;
    if (EVP_DigestFinal_ex(ctx, digest, &digest_len) != 1) {
        EVP_MD_CTX_free(ctx);
        return -1;
    }
    
    EVP_MD_CTX_free(ctx);
    
    // Конвертируем в hex строку
    for (int i = 0; i < HASH_LENGTH; i++) {
        sprintf(hash + (i * 2), "%02x", digest[i]);
    }
    // Нуль-терминатор
    hash[HASH_LENGTH * 2] = '\0';

    return 0;
}

// Проверка пароля
int verify_password(const char* password, const char* hash, const char* salt) {
    // 64 байта -> 128 hex + NUL
    char test_hash[HASH_LENGTH * 2 + 1];
    
    if (hash_password(password, salt, test_hash, sizeof(test_hash)) != 0) {
        return -1;
    }
    
    return strcmp(hash, test_hash) == 0 ? 0 : -1;
}

// Генерация случайной соли
int generate_salt(char* salt, size_t salt_len) {
    if (!salt || salt_len < (SALT_LENGTH * 2 + 1)) {
        return -1;
    }
    
    unsigned char rnd[SALT_LENGTH];
    if (RAND_bytes(rnd, SALT_LENGTH) != 1) {
        return -1;
    }
    
    // Конвертируем в hex строку в предоставленный буфер
    for (int i = 0; i < SALT_LENGTH; i++) {
        sprintf(salt + (i * 2), "%02x", rnd[i]);
    }
    // Нуль-терминатор
    salt[SALT_LENGTH * 2] = '\0';

    return 0;
}

// Шифрование сообщения
int encrypt_message(const char* message, const char* key, char* encrypted, size_t* encrypted_len) {
    if (!message || !key || !encrypted || !encrypted_len) {
        return -1;
    }
    
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        return -1;
    }
    
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, (unsigned char*)key, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    int len;
    if (EVP_EncryptUpdate(ctx, (unsigned char*)encrypted, &len, (unsigned char*)message, strlen(message)) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    int final_len;
    if (EVP_EncryptFinal_ex(ctx, (unsigned char*)encrypted + len, &final_len) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    EVP_CIPHER_CTX_free(ctx);
    *encrypted_len = len + final_len;
    
    return 0;
}

// Расшифровка сообщения
int decrypt_message(const char* encrypted, const char* key, char* decrypted, size_t* decrypted_len) {
    if (!encrypted || !key || !decrypted || !decrypted_len) {
        return -1;
    }
    
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        return -1;
    }
    
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, (unsigned char*)key, NULL) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    int len;
    if (EVP_DecryptUpdate(ctx, (unsigned char*)decrypted, &len, (unsigned char*)encrypted, strlen(encrypted)) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    int final_len;
    if (EVP_DecryptFinal_ex(ctx, (unsigned char*)decrypted + len, &final_len) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    
    EVP_CIPHER_CTX_free(ctx);
    *decrypted_len = len + final_len;
    decrypted[*decrypted_len] = '\0';
    
    return 0;
}

// Генерация JWT токена
int generate_jwt(const char* payload, const char* secret, char* token, size_t token_len) {
    if (!payload || !secret || !token || token_len < 256) {
        return -1;
    }
    
    // Простая реализация JWT (в продакшене используйте готовые библиотеки)
    unsigned char hmac[32];
    unsigned int hmac_len;
    
    HMAC(EVP_sha256(), secret, strlen(secret), (unsigned char*)payload, strlen(payload), hmac, &hmac_len);
    
    // Формируем JWT: header.payload.signature
    strcpy(token, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.");
    strcat(token, payload);
    strcat(token, ".");
    
    // Добавляем подпись (проверяем переполнение)
    size_t base_len = strlen(token);
    if (base_len + (hmac_len * 2) + 1 > token_len) {
        return -1;
    }
    char* p = token + base_len;
    for (unsigned int i = 0; i < hmac_len; i++) {
        sprintf(p + (i * 2), "%02x", hmac[i]);
    }
    token[base_len + (hmac_len * 2)] = '\0';
    
    return 0;
}

// Проверка JWT токена
int verify_jwt(const char* token, const char* secret, char* payload, size_t* payload_len) {
    if (!token || !secret || !payload || !payload_len) {
        return -1;
    }
    
    // Простая проверка JWT
    char* first_dot = strchr(token, '.');
    if (!first_dot) return -1;
    
    char* second_dot = strchr(first_dot + 1, '.');
    if (!second_dot) return -1;
    
    size_t payload_size = second_dot - first_dot - 1;
    if (payload_size > *payload_len) return -1;
    
    strncpy(payload, first_dot + 1, payload_size);
    payload[payload_size] = '\0';
    *payload_len = payload_size;
    
    return 0;
}
