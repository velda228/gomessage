package handlers

import (
	"encoding/json"
	"log"
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
			"error": "Неверные данные запроса: " + err.Error(),
		})
		return
	}

	cryptoService := crypto.NewCryptoService()
	
	// Генерируем соль и хешируем пароль
	salt, err := cryptoService.GenerateSalt()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Ошибка генерации соли",
		})
		return
	}

	hash, err := cryptoService.HashPassword(req.Password, salt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Ошибка хеширования пароля",
		})
		return
	}

	// Создаем пользователя в хранилище
	log.Printf("🔍 Проверяем уникальность: username='%s', email='%s'", req.Username, req.Email)
	
	// Проверяем уникальность перед созданием
	if models.GlobalUserStore.IsUsernameTaken(req.Username) {
		log.Printf("❌ Username '%s' уже занят", req.Username)
		c.JSON(http.StatusConflict, gin.H{
			"error": "Имя пользователя уже занято",
		})
		return
	}
	
	if models.GlobalUserStore.IsEmailTaken(req.Email) {
		log.Printf("❌ Email '%s' уже занят", req.Email)
		c.JSON(http.StatusConflict, gin.H{
			"error": "Почта уже занята",
		})
		return
	}
	
	user, err := models.GlobalUserStore.CreateUser(req.Username, req.Email, hash, salt)
	if err != nil {
		log.Printf("❌ Ошибка создания пользователя: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Ошибка создания пользователя: " + err.Error(),
		})
		return
	}
	
	log.Printf("✅ Пользователь успешно создан: %s (ID: %d)", user.Username, user.ID)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Пользователь успешно зарегистрирован",
		"user": gin.H{
			"username": user.Username,
			"email":    user.Email,
		},
	})
}

// Login обрабатывает вход пользователя
func Login(c *gin.Context) {
	var req models.UserLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Неверные данные запроса: " + err.Error(),
		})
		return
	}

	// Ищем пользователя в хранилище
	log.Printf("🔍 Попытка входа: username='%s'", req.Username)
	
	user, err := models.GlobalUserStore.GetUserByUsername(req.Username)
	if err != nil {
		log.Printf("❌ Пользователь '%s' не найден", req.Username)
		// Не показываем, что пользователь не существует (безопасность)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Неверный логин или пароль",
		})
		return
	}
	
	log.Printf("✅ Пользователь найден: %s (ID: %d)", user.Username, user.ID)
	
	cryptoService := crypto.NewCryptoService()
	
	// Проверяем пароль против сохраненного хеша
	if !cryptoService.VerifyPassword(req.Password, user.Password, user.Salt) {
		log.Printf("❌ Неверный пароль для пользователя '%s'", req.Username)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Неверный логин или пароль",
		})
		return
	}
	
	log.Printf("✅ Пароль верный для пользователя '%s'", req.Username)

	// Генерируем JWT токен
	payloadObj := map[string]interface{}{
		"user_id":  user.ID,
		"username": user.Username,
		"exp":      time.Now().Add(24 * time.Hour).Unix(),
	}
	payloadBytes, _ := json.Marshal(payloadObj)
	token, err := cryptoService.GenerateJWT(string(payloadBytes), "your-secret-key")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Ошибка генерации токена",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Вход выполнен успешно",
		"token":   token,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
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
