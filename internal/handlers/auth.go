package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gomessage/internal/crypto"
	"gomessage/internal/models"
)

// Register обрабатывает регистрацию пользователя
func Register(c *gin.Context) {
	var req models.UserRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}

	// TODO: Проверить уникальность username и email
	// TODO: Сохранить пользователя в базе данных

	cryptoService := crypto.NewCryptoService()
	
	// Генерируем соль и хешируем пароль
	salt, err := cryptoService.GenerateSalt()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to generate salt",
		})
		return
	}

	hash, err := cryptoService.HashPassword(req.Password, salt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to hash password",
		})
		return
	}

	// TODO: Сохранить пользователя с хешем и солью
	_ = hash // Временно игнорируем для компиляции

	c.JSON(http.StatusCreated, gin.H{
		"message": "User registered successfully",
		"user": gin.H{
			"username": req.Username,
			"email":    req.Email,
		},
	})
}

// Login обрабатывает вход пользователя
func Login(c *gin.Context) {
	var req models.UserLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}

	// TODO: Найти пользователя в базе данных
	// TODO: Проверить пароль

	cryptoService := crypto.NewCryptoService()
	
	// Временно для тестирования - создаем хеш на лету
	// В реальном приложении это должно быть в базе данных
	salt := "test_salt_123"
	expectedHash, err := cryptoService.HashPassword(req.Password, salt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to hash password",
		})
		return
	}
	
	// Проверяем пароль
	if !cryptoService.VerifyPassword(req.Password, expectedHash, salt) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Invalid credentials",
		})
		return
	}

	// Генерируем JWT токен
	payloadObj := map[string]interface{}{
		"user_id":  1,
		"username": req.Username,
		"exp":      time.Now().Add(24 * time.Hour).Unix(),
	}
	payloadBytes, _ := json.Marshal(payloadObj)
	token, err := cryptoService.GenerateJWT(string(payloadBytes), "your-secret-key")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to generate token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
		"user": gin.H{
			"id":       1,
			"username": req.Username,
		},
	})
}

// RefreshToken обновляет JWT токен
func RefreshToken(c *gin.Context) {
	// TODO: Реализовать обновление токена
	c.JSON(http.StatusOK, gin.H{
		"message": "Token refreshed",
		"token":   "new_token_here",
	})
}
