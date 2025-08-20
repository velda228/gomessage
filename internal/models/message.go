package models

import (
	"time"
)

// Message представляет сообщение в чате
type Message struct {
	ID        uint      `json:"id" db:"id"`
	Content   string    `json:"content" db:"content"`
	Type      string    `json:"type" db:"type"`
	SenderID  uint      `json:"sender_id" db:"sender_id"`
	ChatID    uint      `json:"chat_id" db:"chat_id"`
	ReplyToID *uint     `json:"reply_to_id,omitempty" db:"reply_to_id"`
	IsEdited  bool      `json:"is_edited" db:"is_edited"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// MessageRequest запрос на отправку сообщения
type MessageRequest struct {
	Content   string `json:"content" binding:"required,max=2000"`
	Type      string `json:"type" binding:"required"`
	ChatID    uint   `json:"chat_id" binding:"required"`
	ReplyToID *uint  `json:"reply_to_id,omitempty"`
}

// MessageResponse ответ с сообщением
type MessageResponse struct {
	ID        uint      `json:"id"`
	Content   string    `json:"content"`
	Type      string    `json:"type"`
	Sender    UserResponse `json:"sender"`
	ChatID    uint      `json:"chat_id"`
	ReplyToID *uint     `json:"reply_to_id,omitempty"`
	IsEdited  bool      `json:"is_edited"`
	CreatedAt time.Time `json:"created_at"`
}

// MessageType типы сообщений
const (
	MessageTypeText     = "text"
	MessageTypeImage    = "image"
	MessageTypeFile     = "file"
	MessageTypeVoice    = "voice"
	MessageTypeLocation = "location"
)

// WebSocketMessage сообщение для WebSocket
type WebSocketMessage struct {
	Type    string      `json:"type"`
	Payload interface{} `json:"payload"`
}

// WebSocketMessageType типы WebSocket сообщений
const (
	WSMessageTypeChat     = "chat"
	WSMessageTypeStatus   = "status"
	WSMessageTypeTyping   = "typing"
	WSMessageTypeRead     = "read"
	WSMessageTypeJoin     = "join"
	WSMessageTypeLeave    = "leave"
)
