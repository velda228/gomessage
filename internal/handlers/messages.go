package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gomessage/internal/models"
)

// SendMessage отправляет сообщение
func SendMessage(c *gin.Context) {
	var req models.MessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Сохранить сообщение в базе данных
	// TODO: Отправить через WebSocket
	
	message := models.MessageResponse{
		ID:        1,
		Content:   req.Content,
		Type:      req.Type,
		Sender:    models.UserResponse{ID: userID.(uint), Username: "testuser"},
		ChatID:    req.ChatID,
		ReplyToID: req.ReplyToID,
		IsEdited:  false,
	}
	
	c.JSON(http.StatusCreated, gin.H{
		"message": "Message sent successfully",
		"data":    message,
	})
}

// GetChatMessages получает сообщения чата
func GetChatMessages(c *gin.Context) {
	chatIDStr := c.Param("chatID")
	chatID, err := strconv.ParseUint(chatIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid chat ID",
		})
		return
	}
	
	// TODO: Получить сообщения из базы данных
	
	messages := []models.MessageResponse{
		{
			ID:       1,
			Content:  "Привет!",
			Type:     models.MessageTypeText,
			Sender:   models.UserResponse{ID: 1, Username: "user1"},
			ChatID:   uint(chatID),
			IsEdited: false,
		},
		{
			ID:       2,
			Content:  "Привет! Как дела?",
			Type:     models.MessageTypeText,
			Sender:   models.UserResponse{ID: 2, Username: "user2"},
			ChatID:   uint(chatID),
			IsEdited: false,
		},
	}
	
	c.JSON(http.StatusOK, gin.H{
		"messages": messages,
		"chat_id":  chatID,
	})
}

// EditMessage редактирует сообщение
func EditMessage(c *gin.Context) {
	messageIDStr := c.Param("id")
	messageID, err := strconv.ParseUint(messageIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid message ID",
		})
		return
	}
	
	var req struct {
		Content string `json:"content" binding:"required,max=2000"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request data: " + err.Error(),
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Проверить права на редактирование
	// TODO: Обновить сообщение в базе данных
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Message edited successfully",
		"message_id": messageID,
		"user_id": userID,
		"content": req.Content,
	})
}

// DeleteMessage удаляет сообщение
func DeleteMessage(c *gin.Context) {
	messageIDStr := c.Param("id")
	messageID, err := strconv.ParseUint(messageIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid message ID",
		})
		return
	}
	
	userID, _ := c.Get("userID")
	
	// TODO: Проверить права на удаление
	// TODO: Удалить сообщение из базы данных
	
	c.JSON(http.StatusOK, gin.H{
		"message": "Message deleted successfully",
		"message_id": messageID,
		"user_id": userID,
	})
}
