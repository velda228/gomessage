package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gomessage/internal/models"
)

// GetProfile получает профиль пользователя
func GetProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}
	
	// Получаем данные пользователя из хранилища
	user, err := models.GlobalUserStore.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "User not found",
		})
		return
	}
	
	// Возвращаем профиль пользователя
	profile := gin.H{
		"id":         user.ID,
		"username":   user.Username,
		"email":      user.Email,
		"avatar":     user.Avatar,
		"status":     user.Status,
		"created_at": user.CreatedAt.Format("2006-01-02T15:04:05Z"),
		"updated_at": user.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
	
	c.JSON(http.StatusOK, profile)
}

// UpdateProfile обновляет профиль пользователя
func UpdateProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "User not authenticated",
		})
		return
	}
	
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
	
	// Обновляем данные пользователя в хранилище
	updates := make(map[string]interface{})
	if req.Username != "" {
		updates["username"] = req.Username
	}
	if req.Email != "" {
		updates["email"] = req.Email
	}
	if req.Avatar != "" {
		updates["avatar"] = req.Avatar
	}
	if req.Status != "" {
		updates["status"] = req.Status
	}
	
	user, err := models.GlobalUserStore.UpdateUser(userID.(uint), updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to update profile: " + err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Profile updated successfully",
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
			"avatar":   user.Avatar,
			"status":   user.Status,
		},
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
	
	// Поиск пользователей в хранилище
	// TODO: Реализовать более эффективный поиск
	// Пока возвращаем всех пользователей для демонстрации
	users := []gin.H{}
	
	// В реальном приложении здесь должен быть поиск по username или email
	// Пока возвращаем пустой список
	// models.GlobalUserStore.SearchUsers(query)
	
	c.JSON(http.StatusOK, gin.H{
		"users": users,
		"query": query,
	})
}
