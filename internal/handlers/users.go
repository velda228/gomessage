package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetProfile получает профиль пользователя
func GetProfile(c *gin.Context) {
	userID, _ := c.Get("userID")
	
	// TODO: Получить данные пользователя из базы данных
	profile := gin.H{
		"id":        userID,
		"username":  "testuser",
		"email":     "test@example.com",
		"avatar":    "",
		"status":    "online",
		"created_at": "2024-01-01T00:00:00Z",
	}
	
	c.JSON(http.StatusOK, profile)
}

// UpdateProfile обновляет профиль пользователя
func UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("userID")
	
	var req struct {
		Username string `json:"username"`
		Email    string `json:"email"`
		Avatar   string `json:"avatar"`
		Status   string `json:"status"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}
	
	// TODO: Обновить данные пользователя в базе данных
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Profile updated successfully",
		"user_id": userID,
	})
}

// SearchUsers ищет пользователей
func SearchUsers(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Search query required",
		})
		return
	}
	
	// TODO: Поиск пользователей в базе данных
	
	users := []gin.H{
		{
			"id":       1,
			"username": "user1",
			"email":    "user1@example.com",
			"avatar":   "",
			"status":   "online",
		},
		{
			"id":       2,
			"username": "user2",
			"email":    "user2@example.com",
			"avatar":   "",
			"status":   "offline",
		},
	}
	
	c.JSON(http.StatusOK, gin.H{
		"users": users,
		"query": query,
	})
}
