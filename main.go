package main

import (
	"log"
	"gomessage/internal/server"
	"gomessage/internal/config"
)

func main() {
	// Загружаем конфигурацию
	cfg := config.Load()

	// Создаем и запускаем сервер
	srv := server.New(cfg)
	
	log.Printf("🚀 GoMessage сервер запускается на порту %s", cfg.Server.Port)
	
	if err := srv.Run(); err != nil {
		log.Fatalf("❌ Ошибка запуска сервера: %v", err)
	}
}
