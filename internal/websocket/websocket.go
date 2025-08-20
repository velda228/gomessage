package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"gomessage/internal/models"
)

// Client представляет WebSocket клиента
type Client struct {
	ID       uint
	UserID   uint
	Username string
	Conn     *websocket.Conn
	Send     chan []byte
	Hub      *Hub
}

// Hub управляет всеми WebSocket соединениями
type Hub struct {
	clients    map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	userChats  map[uint]map[uint]bool // userID -> chatIDs
	chatHistory map[uint][]models.Message // chatID -> messages
	messageUsernames map[uint]string // ID сообщения -> имя пользователя
	nextMessageID uint // Следующий ID для сообщения
	mutex      sync.RWMutex
}

// NewHub создает новый Hub
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		userChats:  make(map[uint]map[uint]bool),
		chatHistory: make(map[uint][]models.Message),
		messageUsernames: make(map[uint]string),
		nextMessageID: 1,
	}
}

// Run запускает Hub
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = true
			h.mutex.Unlock()
			log.Printf("🔌 Клиент %s подключился (ID: %d)", client.Username, client.UserID)

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)
			}
			h.mutex.Unlock()
			log.Printf("🔌 Клиент %s отключился (ID: %d)", client.Username, client.UserID)

		case message := <-h.broadcast:
			h.mutex.RLock()
			for client := range h.clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.clients, client)
				}
			}
			h.mutex.RUnlock()
		}
	}
}

// AddUserToChat добавляет пользователя в чат
func (h *Hub) AddUserToChat(userID, chatID uint) {
	h.mutex.Lock()
	defer h.mutex.Unlock()
	
	if h.userChats[userID] == nil {
		h.userChats[userID] = make(map[uint]bool)
	}
	h.userChats[userID][chatID] = true
}

// RemoveUserFromChat удаляет пользователя из чата
func (h *Hub) RemoveUserFromChat(userID, chatID uint) {
	h.mutex.Lock()
	defer h.mutex.Unlock()
	
	if chats, exists := h.userChats[userID]; exists {
		delete(chats, chatID)
	}
}

// GetChatHistory возвращает историю сообщений для чата
func (h *Hub) GetChatHistory(chatID uint) []models.Message {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	
	if history, exists := h.chatHistory[chatID]; exists {
		return history
	}
	return []models.Message{}
}

// GetMessageUsername возвращает имя пользователя для сообщения
func (h *Hub) GetMessageUsername(messageID uint) string {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	
	if username, exists := h.messageUsernames[messageID]; exists {
		return username
	}
	return "Неизвестный"
}

// getNextMessageID возвращает следующий уникальный ID для сообщения
func (h *Hub) getNextMessageID() uint {
	h.mutex.Lock()
	defer h.mutex.Unlock()
	
	id := h.nextMessageID
	h.nextMessageID++
	return id
}

// AddMessageToHistory добавляет сообщение в историю чата
func (h *Hub) AddMessageToHistory(chatID uint, message models.Message, username string) {
	h.mutex.Lock()
	defer h.mutex.Unlock()
	
	if h.chatHistory[chatID] == nil {
		h.chatHistory[chatID] = make([]models.Message, 0)
	}
	
	// Создаем расширенную структуру для хранения имени пользователя
	type MessageWithUsername struct {
		models.Message
		Username string
	}
	
	// Ограничиваем историю последними 100 сообщениями
	if len(h.chatHistory[chatID]) >= 100 {
		h.chatHistory[chatID] = h.chatHistory[chatID][1:]
	}
	
	h.chatHistory[chatID] = append(h.chatHistory[chatID], message)
	
	// Сохраняем маппинг ID сообщения -> имя пользователя
	if h.messageUsernames == nil {
		h.messageUsernames = make(map[uint]string)
	}
	h.messageUsernames[message.ID] = username
}

// BroadcastToChat отправляет сообщение всем пользователям в чате
func (h *Hub) BroadcastToChat(chatID uint, message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	
	for client := range h.clients {
		if h.userChats[client.UserID][chatID] {
			select {
			case client.Send <- message:
			default:
				close(client.Send)
				delete(h.clients, client)
			}
		}
	}
}

// SendToUser отправляет сообщение конкретному пользователю
func (h *Hub) SendToUser(userID uint, message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	
	for client := range h.clients {
		if client.UserID == userID {
			select {
			case client.Send <- message:
			default:
				close(client.Send)
				delete(h.clients, client)
			}
		}
	}
}

// readPump читает сообщения от клиента
func (c *Client) readPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(2048) // Увеличиваем лимит для поддержки длинных сообщений
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("❌ Ошибка чтения WebSocket: %v", err)
			}
			break
		}

		// Обрабатываем сообщение
		var wsMessage models.WebSocketMessage
		if err := json.Unmarshal(message, &wsMessage); err != nil {
			log.Printf("❌ Ошибка парсинга WebSocket сообщения: %v", err)
			continue
		}

		// Логируем размер сообщения для отладки
		log.Printf("📨 Получено WebSocket сообщение размером %d байт от пользователя %s", len(message), c.Username)

		c.handleMessage(wsMessage)
	}
}

// writePump отправляет сообщения клиенту
func (c *Client) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// handleMessage обрабатывает входящие WebSocket сообщения
func (c *Client) handleMessage(message models.WebSocketMessage) {
	switch message.Type {
	case models.WSMessageTypeJoin:
		// Подписка пользователя на чат
		if joinData, ok := message.Payload.(map[string]interface{}); ok {
			if chatID, ok := joinData["chat_id"].(float64); ok {
				c.Hub.AddUserToChat(c.UserID, uint(chatID))
				
				// Отправляем историю чата новому пользователю
				history := c.Hub.GetChatHistory(uint(chatID))
				for _, msg := range history {
					username := c.Hub.GetMessageUsername(msg.ID)
					response := models.WebSocketMessage{
						Type: models.WSMessageTypeChat,
						Payload: map[string]interface{}{
							"id":        msg.ID,
							"content":   msg.Content,
							"sender_id": msg.SenderID,
							"username":  username,
							"chat_id":   msg.ChatID,
							"timestamp": msg.CreatedAt,
							"is_history": true,
						},
					}
					
					responseBytes, _ := json.Marshal(response)
					select {
					case c.Send <- responseBytes:
					default:
						// Если канал переполнен, пропускаем
					}
				}
			}
		}

	case models.WSMessageTypeLeave:
		// Отписка пользователя от чата
		if leaveData, ok := message.Payload.(map[string]interface{}); ok {
			if chatID, ok := leaveData["chat_id"].(float64); ok {
				c.Hub.RemoveUserFromChat(c.UserID, uint(chatID))
			}
		}
	case models.WSMessageTypeChat:
		// Обработка чат сообщения
		if chatMsg, ok := message.Payload.(map[string]interface{}); ok {
			if chatID, ok := chatMsg["chat_id"].(float64); ok {
				// Генерируем уникальный ID для сообщения
				messageID := c.Hub.getNextMessageID()
				
				// Создаем сообщение для истории
				msg := models.Message{
					ID:        messageID,
					Content:   chatMsg["content"].(string),
					Type:      models.MessageTypeText,
					SenderID:  c.UserID,
					ChatID:    uint(chatID),
					CreatedAt: time.Now(),
					UpdatedAt: time.Now(),
				}
				
				// Сохраняем в историю с именем пользователя
				c.Hub.AddMessageToHistory(uint(chatID), msg, c.Username)
				
				// Отправляем сообщение всем в чате
				response := models.WebSocketMessage{
					Type: models.WSMessageTypeChat,
					Payload: map[string]interface{}{
						"id":        messageID,
						"content":   chatMsg["content"],
						"sender_id": c.UserID,
						"username":  c.Username,
						"chat_id":   uint(chatID),
						"timestamp": time.Now(),
					},
				}
				
				responseBytes, _ := json.Marshal(response)
				c.Hub.BroadcastToChat(uint(chatID), responseBytes)
			}
		}
		
	case models.WSMessageTypeTyping:
		// Обработка статуса печати
		if typingData, ok := message.Payload.(map[string]interface{}); ok {
			if chatID, ok := typingData["chat_id"].(float64); ok {
				response := models.WebSocketMessage{
					Type: models.WSMessageTypeTyping,
					Payload: map[string]interface{}{
						"user_id":  c.UserID,
						"username": c.Username,
						"chat_id":  uint(chatID),
						"typing":   typingData["typing"],
					},
				}
				
				responseBytes, _ := json.Marshal(response)
				c.Hub.BroadcastToChat(uint(chatID), responseBytes)
			}
		}
		
	case models.WSMessageTypeStatus:
		// Обновление статуса пользователя
		if statusData, ok := message.Payload.(map[string]interface{}); ok {
			if status, ok := statusData["status"].(string); ok {
				response := models.WebSocketMessage{
					Type: models.WSMessageTypeStatus,
					Payload: map[string]interface{}{
						"user_id": c.UserID,
						"username": c.Username,
						"status":   status,
					},
				}
				
				responseBytes, _ := json.Marshal(response)
				c.Hub.broadcast <- responseBytes
			}
		}
	}
}

// ServeWebSocket обрабатывает WebSocket соединения
func ServeWebSocket(hub *Hub, w http.ResponseWriter, r *http.Request) {
	// Получаем userID из query параметров или заголовков
	userIDStr := r.URL.Query().Get("user_id")
	if userIDStr == "" {
		http.Error(w, "user_id required", http.StatusBadRequest)
		return
	}

	// Парсим user_id
	userIDUint64, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		http.Error(w, "invalid user_id", http.StatusBadRequest)
		return
	}

	// Необязательное имя пользователя
	username := r.URL.Query().Get("username")
	
	// В реальном приложении здесь должна быть проверка JWT токена
	// и получение userID из токена
	
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true // В продакшене проверяйте origin
		},
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("❌ Ошибка WebSocket upgrade: %v", err)
		return
	}

	client := &Client{
		ID:       0, // Генерируем уникальный ID
		UserID:   uint(userIDUint64),
		Username: username,
		Hub:      hub,
		Conn:     conn,
		Send:     make(chan []byte, 1024), // Увеличиваем размер канала для длинных сообщений
	}

	client.Hub.register <- client

	go client.writePump()
	go client.readPump()
}
