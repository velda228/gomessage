package main

import (
	"log"
	"gomessage/internal/server"
	"gomessage/internal/config"
	"gomessage/internal/models"
	"gomessage/internal/crypto"
)

func main() {
	// Загружаем конфигурацию
	cfg := config.Load()

	// Создаем тестового пользователя для демонстрации
	createTestUser()

	// Создаем и запускаем сервер
	srv := server.New(cfg)
	
	log.Printf("🚀 GoMessage сервер запускается на порту %s", cfg.Server.Port)
	
	if err := srv.Run(); err != nil {
		log.Fatalf("❌ Ошибка запуска сервера: %v", err)
	}
}

// createTestUser создает тестового пользователя для демонстрации
func createTestUser() {
	cryptoService := crypto.NewCryptoService()
	
	// Создаем тестового пользователя
	username := "testuser"
	email := "test@example.com"
	password := "password123"
	
	// Проверяем, существует ли уже пользователь
	_, err := models.GlobalUserStore.GetUserByUsername(username)
	if err == nil {
		log.Printf("✅ Тестовый пользователь %s уже существует", username)
		return
	}
	
	// Генерируем соль и хешируем пароль
	salt, err := cryptoService.GenerateSalt()
	if err != nil {
		log.Printf("❌ Ошибка генерации соли: %v", err)
		return
	}
	
	hash, err := cryptoService.HashPassword(password, salt)
	if err != nil {
		log.Printf("❌ Ошибка хеширования пароля: %v", err)
		return
	}
	
	// Создаем пользователя
	user, err := models.GlobalUserStore.CreateUser(username, email, hash, salt)
	if err != nil {
		log.Printf("❌ Ошибка создания тестового пользователя: %v", err)
		return
	}
	
	log.Printf("✅ Создан тестовый пользователь: %s (ID: %d)", user.Username, user.ID)
	log.Printf("🔑 Тестовые данные для входа:")
	log.Printf("   Username: %s", username)
	log.Printf("   Password: %s", password)
	
	// Показываем общее количество пользователей
	log.Printf("📊 Всего пользователей в системе: %d", models.GlobalUserStore.GetUsersCount())
}
