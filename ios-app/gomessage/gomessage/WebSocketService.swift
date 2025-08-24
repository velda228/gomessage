import Foundation
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    @Published var isConnected = false
    @Published var lastMessage: Message?
    @Published var typingUsers: [String] = []
    
    private var webSocket: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "ws://YOUR_IP_FROM_CONSOLE:8080/ws"
    private var processedMessageIds: Set<Int> = [] // Для предотвращения дублирования
    
    private init() {}
    
    func connect() {
        guard let url = URL(string: baseURL) else { return }
        
        // Добавляем параметры для подключения к WebSocket - ТОЧНО КАК НА САЙТЕ
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems: [URLQueryItem] = []
        
        // Добавляем user_id и username как на сайте - БЕЗ ТОКЕНА!
        if let currentUser = APIService.shared.currentUser {
            queryItems.append(URLQueryItem(name: "user_id", value: "\(currentUser.id)"))
            queryItems.append(URLQueryItem(name: "username", value: currentUser.username))
        }
        
        // НЕ добавляем токен - как на сайте!
        
        components?.queryItems = queryItems
        guard let finalURL = components?.url else { return }
        
        print("🔌 Подключаемся к WebSocket: \(finalURL)")
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: finalURL)
        webSocket?.resume()
        
        isConnected = true
        processedMessageIds.removeAll() // Очищаем обработанные ID при новом подключении
        receiveMessage()
        
        // Подписываемся на чат после подключения - ТОЧНО КАК НА САЙТЕ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.joinChat(chatID: 1)
        }
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        isConnected = false
    }
    
    func sendMessage(_ message: WebSocketMessage) {
        // Отправляем как JSON строку - ТОЧНО КАК НА САЙТЕ
        do {
            let jsonData = try JSONEncoder().encode(message)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            print("📤 Отправляем WebSocket сообщение: \(jsonString)")
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocket?.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Ошибка отправки WebSocket сообщения: \(error)")
                } else {
                    print("✅ Сообщение отправлено через WebSocket")
                }
            }
        } catch {
            print("❌ Ошибка кодирования WebSocket сообщения: \(error)")
        }
    }
    
    func sendMessageAsDict(_ messageDict: [String: Any]) {
        // Отправляем как JSON строку - ТОЧНО КАК НА САЙТЕ
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageDict)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            print("📤 Отправляем WebSocket сообщение как словарь: \(jsonString)")
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocket?.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Ошибка отправки WebSocket сообщения: \(error)")
                } else {
                    print("✅ Сообщение отправлено через WebSocket")
                }
            }
        } catch {
            print("❌ Ошибка создания JSON из словаря: \(error)")
        }
    }
    
    func sendChatMessage(content: String, chatID: Int) {
        // Создаем сообщение как словарь - ТОЧНО КАК НА САЙТЕ
        let messageDict: [String: Any] = [
            "type": "chat",
            "payload": [
                "content": content,
                "chat_id": chatID
            ]
        ]
        
        print("📤 Отправляем WebSocket сообщение: \(messageDict)")
        sendMessageAsDict(messageDict)
    }
    
    func joinChat(chatID: Int) {
        // Создаем сообщение как словарь - ТОЧНО КАК НА САЙТЕ
        let messageDict: [String: Any] = [
            "type": "join",
            "payload": [
                "chat_id": chatID
            ]
        ]
        
        sendMessageAsDict(messageDict)
        print("🔌 Подписываемся на чат: \(chatID)")
    }
    
    func sendTyping(chatID: Int, isTyping: Bool) {
        // Создаем сообщение как словарь - ТОЧНО КАК НА САЙТЕ
        let messageDict: [String: Any] = [
            "type": "typing",
            "payload": [
                "chat_id": chatID,
                "typing": isTyping
            ]
        ]
        
        sendMessageAsDict(messageDict)
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.receiveMessage() // Продолжаем слушать
                case .failure(let error):
                    print("WebSocket receive error: \(error)")
                    self?.isConnected = false
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                let wsMessage = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                handleWebSocketMessage(wsMessage)
            } catch {
                print("Failed to decode WebSocket message: \(error)")
            }
        case .string(let string):
            print("📨 Получено строковое сообщение: \(string)")
            // Парсим JSON строку
            if let data = string.data(using: .utf8) {
                handleStringMessage(data)
            }
        @unknown default:
            break
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "chat":
            if let messageData = message.payload as? [String: Any],
               let messageJSON = try? JSONSerialization.data(withJSONObject: messageData),
               let newMessage = try? JSONDecoder().decode(Message.self, from: messageJSON) {
                DispatchQueue.main.async {
                    self.lastMessage = newMessage
                    // Отправляем уведомление о новом сообщении
                    NotificationCenter.default.post(
                        name: .newMessageReceived,
                        object: newMessage
                    )
                }
            }
        case "typing":
            if let typingData = message.payload as? [String: Any],
               let username = typingData["username"] as? String,
               let isTyping = typingData["typing"] as? Bool {
                DispatchQueue.main.async {
                    if isTyping {
                        if !self.typingUsers.contains(username) {
                            self.typingUsers.append(username)
                        }
                    } else {
                        self.typingUsers.removeAll { $0 == username }
                    }
                }
            }
        case "status":
            // Обработка изменения статуса пользователя
            break
        default:
            print("📨 Неизвестный тип WebSocket сообщения: \(message.type)")
            break
        }
    }
    
    private func handleStringMessage(_ data: Data) {
        do {
            // Парсим JSON как словарь - ТОЧНО КАК НА САЙТЕ
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                switch type {
                case "chat":
                    if let payload = json["payload"] as? [String: Any],
                       let content = payload["content"] as? String,
                       let username = payload["username"] as? String {
                        
                        // Получаем правильный sender_id из payload
                        let senderID = payload["sender_id"] as? Int ?? 1
                        let messageId = payload["id"] as? Int
                        let isHistory = payload["is_history"] as? Bool ?? false
                        
                        // Проверяем, не наше ли это сообщение - ТОЧНО КАК НА САЙТЕ
                        let isOwnMessage = username == APIService.shared.currentUser?.username
                        
                        // Проверяем, не обрабатывали ли мы уже это сообщение
                        if let id = messageId, processedMessageIds.contains(id) {
                            print("📨 Сообщение с ID \(id) уже обработано, пропускаем")
                            return
                        }
                        
                        // Добавляем ID в обработанные
                        if let id = messageId {
                            processedMessageIds.insert(id)
                        }
                        
                        // Если это наше сообщение, добавляем его в список сообщений
                        if isOwnMessage {
                            print("📨 Получено наше собственное сообщение: \(content)")
                        }
                        
                        // Создаем временное сообщение
                        let tempMessage = Message(
                            id: messageId ?? Int.random(in: 1000...9999),
                            content: content,
                            type: "text",
                            sender: User(
                                id: senderID,
                                username: username,
                                email: "",
                                avatar: nil,
                                status: "online",
                                createdAt: Date(),
                                updatedAt: nil
                            ),
                            chatID: payload["chat_id"] as? Int ?? 1,
                            replyToID: nil,
                            isEdited: false,
                            createdAt: Date(),
                            updatedAt: nil
                        )
                        
                        DispatchQueue.main.async {
                            self.lastMessage = tempMessage
                            // Отправляем уведомление о новом сообщении
                            NotificationCenter.default.post(
                                name: .newMessageReceived,
                                object: tempMessage
                            )
                        }
                        
                        print("📨 Получено сообщение от \(username) (ID: \(senderID)), наше: \(isOwnMessage), история: \(isHistory)")
                    }
                    
                case "typing":
                    if let payload = json["payload"] as? [String: Any],
                       let username = payload["username"] as? String,
                       let isTyping = payload["typing"] as? Bool {
                        DispatchQueue.main.async {
                            if isTyping {
                                if !self.typingUsers.contains(username) {
                                    self.typingUsers.append(username)
                                }
                            } else {
                                self.typingUsers.removeAll { $0 == username }
                            }
                        }
                    }
                    
                default:
                    print("📨 Неизвестный тип сообщения: \(type)")
                }
            }
        } catch {
            print("❌ Ошибка парсинга строкового сообщения: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newMessageReceived = Notification.Name("newMessageReceived")
}

// MARK: - WebSocket Message Models

struct WebSocketMessage: Codable {
    let type: String
    let payload: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(type: String, payload: [String: Any]) {
        self.type = type
        self.payload = payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        // Декодируем payload как Any
        if let payloadData = try? container.decode(Data.self, forKey: .payload) {
            if let dict = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                payload = dict
            } else {
                payload = [:]
            }
        } else {
            payload = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        // Кодируем payload как Data
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        try container.encode(payloadData, forKey: .payload)
    }
}
