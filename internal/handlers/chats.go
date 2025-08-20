package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetUserChats получает список чатов пользователя
func GetUserChats(c *gin.Context) {
	userID, _ := c.Get("userID")
	
	// TODO: Получить чаты пользователя из базы данных
	
	chats := []gin.H{
		{
			"id":          1,
			"name":        "Общий чат",
			"type":        "group",
			"last_message": "Привет всем!",
			"last_sender":  "user1",
			"unread_count": 5,
			"created_at":   "2024-01-01T00:00:00Z",
		},
		{
			"id":          2,
			"name":        "Личный чат",
			"type":        "private",
			"last_message": "Как дела?",
			"last_sender":  "user2",
			"unread_count": 0,
			"created_at":   "2024-01-01T00:00:00Z",
		},
	}
	
	c.JSON(http.StatusOK, gin.H{
		"chats": chats,
		"user_id": userID,
	})
}

// CreateChat создает новый чат
func CreateChat(c *gin.Context) {
	var req struct {
		Name     string   `json:"name" binding:"required"`
		Type     string   `json:"type" binding:"required"`
		UserIDs  []uint   `json:"user_ids" binding:"required"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Создать чат в базе данных
	// TODO: Добавить пользователей в чат
	
	chat := gin.H{
		"id":         3,
		"name":       req.Name,
		"type":       req.Type,
		"creator_id": userID,
		"user_ids":   req.UserIDs,
		"created_at": "2024-01-01T00:00:00Z",
	}
	
	c.JSON(http.StatusCreated, gin.H{
		"message": "Chat created successfully",
		"chat":    chat,
	})
}

// GetChat получает информацию о чате
func GetChat(c *gin.Context) {
	chatIDStr := c.Param("id")
	chatID, err := strconv.ParseUint(chatIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid chat ID",
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Получить информацию о чате из базы данных
	// TODO: Проверить права доступа
	
	chat := gin.H{
		"id":          uint(chatID),
		"name":        "Тестовый чат",
		"type":        "group",
		"creator_id":  1,
		"user_ids":    []uint{1, 2, 3},
		"created_at":  "2024-01-01T00:00:00Z",
		"description": "Описание чата",
	}
	
	c.JSON(http.StatusOK, gin.H{
		"chat": chat,
		"user_id": userID,
	})
}

// JoinChat присоединяет пользователя к чату
func JoinChat(c *gin.Context) {
	chatIDStr := c.Param("id")
	chatID, err := strconv.ParseUint(chatIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid chat ID",
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Добавить пользователя в чат
	// TODO: Отправить уведомление через WebSocket
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Successfully joined chat",
		"chat_id": chatID,
		"user_id": userID,
	})
}

// LeaveChat выводит пользователя из чата
func LeaveChat(c *gin.Context) {
	chatIDStr := c.Param("id")
	chatID, err := strconv.ParseUint(chatIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid chat ID",
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Удалить пользователя из чата
	// TODO: Отправить уведомление через WebSocket
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Successfully left chat",
		"chat_id": chatID,
		"user_id": userID,
	})
}
