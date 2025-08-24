package models

import (
	"errors"
	"sync"
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

// UserStore in-memory хранилище пользователей
type UserStore struct {
	users map[string]*User // username -> User
	mu    sync.RWMutex
	nextID uint
}

// NewUserStore создает новое хранилище пользователей
func NewUserStore() *UserStore {
	return &UserStore{
		users: make(map[string]*User),
		nextID: 1,
	}
}

// CreateUser создает нового пользователя
func (s *UserStore) CreateUser(username, email, password, salt string) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	// Проверяем уникальность username
	if _, exists := s.users[username]; exists {
		return nil, errors.New("username already exists")
	}
	
	// Проверяем уникальность email
	for _, user := range s.users {
		if user.Email == email {
			return nil, errors.New("email already exists")
		}
	}
	
	user := &User{
		ID:        s.nextID,
		Username:  username,
		Email:     email,
		Password:  password,
		Salt:      salt,
		Avatar:    "",
		Status:    UserStatusOnline,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	
	s.users[username] = user
	s.nextID++
	
	return user, nil
}

// GetUserByUsername получает пользователя по username
func (s *UserStore) GetUserByUsername(username string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	user, exists := s.users[username]
	if !exists {
		return nil, errors.New("user not found")
	}
	
	return user, nil
}

// GetUserByEmail получает пользователя по email
func (s *UserStore) GetUserByEmail(email string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	for _, user := range s.users {
		if user.Email == email {
			return user, nil
		}
	}
	
	return nil, errors.New("user not found")
}

// IsUsernameTaken проверяет, занят ли username
func (s *UserStore) IsUsernameTaken(username string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	_, exists := s.users[username]
	return exists
}

// IsEmailTaken проверяет, занят ли email
func (s *UserStore) IsEmailTaken(email string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	for _, user := range s.users {
		if user.Email == email {
			return true
		}
	}
	return false
}

// GetAllUsers возвращает всех пользователей (для отладки)
func (s *UserStore) GetAllUsers() []*User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	users := make([]*User, 0, len(s.users))
	for _, user := range s.users {
		users = append(users, user)
	}
	return users
}

// GetUsersCount возвращает количество пользователей
func (s *UserStore) GetUsersCount() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	return len(s.users)
}

// GetUserByID получает пользователя по ID
func (s *UserStore) GetUserByID(id uint) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	for _, user := range s.users {
		if user.ID == id {
			return user, nil
		}
	}
	
	return nil, errors.New("user not found")
}

// UpdateUser обновляет данные пользователя
func (s *UserStore) UpdateUser(id uint, updates map[string]interface{}) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	
	var user *User
	for _, u := range s.users {
		if u.ID == id {
			user = u
			break
		}
	}
	
	if user == nil {
		return nil, errors.New("user not found")
	}
	
	// Обновляем поля
	if username, ok := updates["username"].(string); ok {
		user.Username = username
	}
	if email, ok := updates["email"].(string); ok {
		user.Email = email
	}
	if status, ok := updates["status"].(string); ok {
		user.Status = status
	}
	if avatar, ok := updates["avatar"].(string); ok {
		user.Avatar = avatar
	}
	
	user.UpdatedAt = time.Now()
	
	return user, nil
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

// Глобальное хранилище пользователей
var GlobalUserStore = NewUserStore()
