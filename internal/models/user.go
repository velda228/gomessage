package models

import (
	"time"
)

// User представляет пользователя системы
type User struct {
	ID        uint      `json:"id" db:"id"`
	Username  string    `json:"username" db:"username"`
	Email     string    `json:"email" db:"email"`
	Password  string    `json:"-" db:"password"` // Не отправляем в JSON
	Salt      string    `json:"-" db:"salt"`
	Avatar    string    `json:"avatar" db:"avatar"`
	Status    string    `json:"status" db:"status"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// UserRegisterRequest запрос на регистрацию
type UserRegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=20"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

// UserLoginRequest запрос на вход
type UserLoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// UserResponse ответ с данными пользователя
type UserResponse struct {
	ID        uint      `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	Avatar    string    `json:"avatar"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// UserStatus статус пользователя
const (
	UserStatusOnline  = "online"
	UserStatusOffline = "offline"
	UserStatusAway    = "away"
	UserStatusBusy    = "busy"
)
