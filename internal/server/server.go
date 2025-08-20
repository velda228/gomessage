package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gomessage/internal/config"
	"gomessage/internal/handlers"
	"gomessage/internal/middleware"
	"gomessage/internal/websocket"
)

// Server представляет HTTP сервер
type Server struct {
	config *config.Config
	router *gin.Engine
	hub    *websocket.Hub
	server *http.Server
}

// New создает новый сервер
func New(cfg *config.Config) *Server {
	gin.SetMode(gin.ReleaseMode)
	
	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())
	
	hub := websocket.NewHub()
	
	server := &Server{
		config: cfg,
		router: router,
		hub:    hub,
	}
	
	server.setupRoutes()
	
	return server
}

// setupRoutes настраивает маршруты
func (s *Server) setupRoutes() {
	// CORS middleware
	s.router.Use(middleware.CORS())
	
	// API v1
	api := s.router.Group("/api/v1")
	{
		// Аутентификация
		auth := api.Group("/auth")
		{
			auth.POST("/register", handlers.Register)
			auth.POST("/login", handlers.Login)
			auth.POST("/refresh", handlers.RefreshToken)
		}
		
		// Пользователи
		users := api.Group("/users")
		users.Use(middleware.Auth())
		{
			users.GET("/profile", handlers.GetProfile)
			users.PUT("/profile", handlers.UpdateProfile)
			users.GET("/search", handlers.SearchUsers)
		}
		
		// Сообщения
		messages := api.Group("/messages")
		messages.Use(middleware.Auth())
		{
			messages.POST("/", handlers.SendMessage)
			messages.GET("/chat/:chatID", handlers.GetChatMessages)
			messages.PUT("/:id", handlers.EditMessage)
			messages.DELETE("/:id", handlers.DeleteMessage)
		}
		
		// Чаты
		chats := api.Group("/chats")
		chats.Use(middleware.Auth())
		{
			chats.GET("/", handlers.GetUserChats)
			chats.POST("/", handlers.CreateChat)
			chats.GET("/:id", handlers.GetChat)
			chats.POST("/:id/join", handlers.JoinChat)
			chats.DELETE("/:id/leave", handlers.LeaveChat)
		}
	}
	
	// WebSocket endpoint
	s.router.GET("/ws", func(c *gin.Context) {
		websocket.ServeWebSocket(s.hub, c.Writer, c.Request)
	})
	
	// Статические файлы для frontend
	s.router.Static("/static", "./static")
	s.router.StaticFile("/", "./static/index.html")
	
	// Health check
	s.router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "ok",
			"timestamp": time.Now(),
			"service":   "gomessage",
		})
	})
}

// Run запускает сервер
func (s *Server) Run() error {
	// Запускаем WebSocket hub в горутине
	go s.hub.Run()
	
	// Создаем HTTP сервер
	s.server = &http.Server{
		Addr:    fmt.Sprintf("%s:%s", s.config.Server.Host, s.config.Server.Port),
		Handler: s.router,
	}
	
	log.Printf("🚀 Сервер запущен на %s:%s", s.config.Server.Host, s.config.Server.Port)
	
	// Запускаем сервер
	return s.server.ListenAndServe()
}

// Shutdown gracefully завершает работу сервера
func (s *Server) Shutdown(ctx context.Context) error {
	log.Println("🔄 Завершение работы сервера...")
	return s.server.Shutdown(ctx)
}
