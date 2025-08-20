package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// Auth middleware для проверки JWT токена
func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header required",
			})
			c.Abort()
			return
		}

		// Проверяем формат "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		token := parts[1]
		
		// В реальном приложении здесь должна быть проверка JWT токена
		// и извлечение userID из токена
		
		// Пока что просто проверяем, что токен не пустой
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid token",
			})
			c.Abort()
			return
		}

		// TODO: Добавить проверку JWT токена через C библиотеку
		// cryptoService := crypto.NewCryptoService()
		// payload, err := cryptoService.VerifyJWT(token, secretKey)
		// if err != nil {
		//     c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
		//     c.Abort()
		//     return
		// }

		// Добавляем userID в контекст
		// c.Set("userID", userID)
		c.Set("userID", uint(1)) // Временно хардкодим для тестирования
		
		c.Next()
	}
}

// CORS middleware для разрешения cross-origin запросов
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		c.Header("Access-Control-Expose-Headers", "Content-Length")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
