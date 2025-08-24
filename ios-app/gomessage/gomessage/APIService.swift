import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "http://YOUR_IP_FROM_CONSOLE:8080/api/v1"
    var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private init() {
        // Загружаем сохраненный токен при инициализации
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = token
            self.isAuthenticated = true
            
            // Загружаем сохраненные данные пользователя
            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                print("🔑 Загружен пользователь: \(user.username) с токеном")
            } else {
                print("⚠️ Данные пользователя не найдены, очищаем токен")
                // Если данные пользователя не найдены, очищаем токен
                UserDefaults.standard.removeObject(forKey: "authToken")
                self.authToken = nil
                self.isAuthenticated = false
                return
            }
            
            // Автоматически загружаем актуальный профиль с сервера
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.refreshProfile()
            }
        }
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, Error> {
        let loginRequest = UserLoginRequest(username: username, password: password)
        
        return makeRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: loginRequest
        )
        .handleEvents(receiveOutput: { [weak self] response in
            // Очищаем старые данные перед сохранением новых
            UserDefaults.standard.removeObject(forKey: "currentUser")
            
            self?.authToken = response.token
            // Создаем полного пользователя из данных входа
            let fullUser = User(
                id: response.user.id,
                username: response.user.username,
                email: "", // Email не возвращается при входе
                avatar: nil,
                status: "online",
                createdAt: Date(),
                updatedAt: Date()
            )
            self?.currentUser = fullUser
            self?.isAuthenticated = true
            
            // Сохраняем токен и данные пользователя
            UserDefaults.standard.set(response.token, forKey: "authToken")
            if let userData = try? JSONEncoder().encode(fullUser) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            
            print("✅ Успешный вход: \(fullUser.username)")
        })
        .handleEvents(receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                print("❌ Ошибка входа: \(error)")
                // При ошибке входа очищаем все данные аутентификации
                self?.authToken = nil
                self?.currentUser = nil
                self?.isAuthenticated = false
                UserDefaults.standard.removeObject(forKey: "authToken")
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        })
        .eraseToAnyPublisher()
    }
    
    func register(username: String, email: String, password: String) -> AnyPublisher<RegisterResponse, Error> {
        let registerRequest = UserRegisterRequest(username: username, email: email, password: password)
        
        return makeRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: registerRequest
        )
        .handleEvents(receiveOutput: { [weak self] response in
            // При регистрации токен не возвращается, нужно войти отдельно
            // Создаем временного пользователя для отображения
            let tempUser = User(
                id: 0, // Временный ID
                username: response.user.username,
                email: response.user.email,
                avatar: nil,
                status: "online",
                createdAt: Date(),
                updatedAt: Date()
            )
            self?.currentUser = tempUser
            // Не устанавливаем isAuthenticated = true, так как нужен токен
        })
        .eraseToAnyPublisher()
    }
    
    func logout() {
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // Функция для полной очистки всех данных приложения
    func clearAllData() {
        logout()
        // Очищаем все возможные ключи UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("🧹 Все данные приложения очищены")
    }
    
    // MARK: - Users
    
    func getProfile() -> AnyPublisher<User, Error> {
        return makeRequest(endpoint: "/users/profile", method: "GET")
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                // Сохраняем обновленные данные пользователя
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Функция для обновления данных пользователя
    func updateCurrentUser(_ user: User) {
        self.currentUser = user
        // Сохраняем обновленные данные
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    // Функция для обновления профиля с сервера
    func refreshProfile() {
        guard isAuthenticated else { return }
        
        getProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Ошибка обновления профиля: \(error)")
                        // При ошибке загрузки профиля, возможно токен истек
                        // Очищаем данные и переводим в неавторизованное состояние
                        DispatchQueue.main.async {
                            self.logout()
                        }
                    }
                },
                receiveValue: { user in
                    print("✅ Профиль обновлен: \(user.username)")
                    
                    // Проверяем, что загруженный профиль соответствует текущему пользователю
                    if let currentUser = self.currentUser, currentUser.id != user.id {
                        print("⚠️ ID пользователя изменился, очищаем данные")
                        self.clearAllData()
                        return
                    }
                    
                    // Обновляем и сохраняем данные пользователя
                    self.updateCurrentUser(user)
                }
            )
            .store(in: &cancellables)
    }
    

    
    // MARK: - Chats
    
    func getUserChats() -> AnyPublisher<[Chat], Error> {
        return makeRequest(endpoint: "/chats", method: "GET")
            .map { (response: ChatsResponse) in
                return response.chats
            }
            .eraseToAnyPublisher()
    }
    
    func getChat(id: Int) -> AnyPublisher<Chat, Error> {
        return makeRequest(endpoint: "/chats/\(id)", method: "GET")
    }
    

    
    // MARK: - Messages
    
    func getChatMessages(chatID: Int) -> AnyPublisher<[Message], Error> {
        return makeRequest(endpoint: "/messages/chat/\(chatID)", method: "GET")
            .map { (response: ChatMessagesResponse) in
                // Возвращаем все сообщения без фильтрации
                return response.messages
            }
            .eraseToAnyPublisher()
    }
    
    func sendMessage(content: String, chatID: Int, type: String = "text", replyToID: Int? = nil) -> AnyPublisher<Message, Error> {
        let messageRequest = MessageRequest(
            content: content,
            type: type,
            chatID: chatID,
            replyToID: replyToID
        )
        
        return makeRequest(
            endpoint: "/messages",
            method: "POST",
            body: messageRequest
        )
        .map { (response: SendMessageResponse) in
            return response.data
        }
        .mapError { error in
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized:
                    print("🔴 Ошибка авторизации при отправке сообщения")
                default:
                    break
                }
            }
            return error
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) -> AnyPublisher<T, Error> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Отправляем токен: Bearer \(token)")
        } else {
            print("⚠️ Токен отсутствует для запроса: \(endpoint)")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: APIError.encodingError)
                    .eraseToAnyPublisher()
            }
        }
        
        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            if let urlWithQuery = components?.url {
                request.url = urlWithQuery
            }
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Проверяем HTTP статус код
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP статус: \(httpResponse.statusCode)")
                    
                    // Обрабатываем ошибки HTTP статусов
                    switch httpResponse.statusCode {
                    case 200...299:
                        // Успешный ответ
                        return data
                    case 401:
                        // Неавторизован - неверный логин/пароль
                        throw APIError.invalidCredentials
                    case 400:
                        // Неверный запрос
                        throw APIError.badRequest
                    case 409:
                        // Конфликт - попробуем извлечь сообщение об ошибке
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorMessage = errorData["error"] as? String {
                            throw APIError.conflict(errorMessage)
                        } else {
                            throw APIError.conflict("Конфликт данных")
                        }
                    case 500...599:
                        // Ошибка сервера
                        throw APIError.serverError
                    default:
                        // Другие ошибки
                        throw APIError.httpError(httpResponse.statusCode)
                    }
                }
                return data
            }
            .handleEvents(receiveOutput: { data in
                // Логируем полученные данные для отладки
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 Получен ответ от сервера: \(jsonString)")
                }
            })
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                if error is DecodingError {
                    print("❌ Ошибка декодирования: \(error)")
                    return APIError.decodingError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case networkError(Error)
    case unauthorized
    case serverError
    case invalidCredentials
    case badRequest
    case httpError(Int)
    case conflict(String) // Для ошибок 409 (конфликты)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .unauthorized:
            return "Не авторизован"
        case .serverError:
            return "Ошибка сервера"
        case .invalidCredentials:
            return "Неверный логин или пароль"
        case .badRequest:
            return "Неверный запрос"
        case .httpError(let statusCode):
            return "HTTP ошибка: \(statusCode)"
        case .conflict(let message):
            return message
        }
    }
}
