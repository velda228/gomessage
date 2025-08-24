import SwiftUI
import Combine
import Foundation

struct ChatView: View {
    let chat: Chat
    @StateObject private var apiService = APIService.shared
    @StateObject private var webSocketService = WebSocketService.shared
    
    @State private var messages: [Message] = []
    @State private var newMessageText = ""
    @State private var isLoading = false
    
    @Environment(\.presentationMode) var presentationMode
    
    // Вычисляемое свойство для проверки возможности отправки
    private var canSendMessage: Bool {
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let charCount = trimmedText.count
        let byteCount = trimmedText.data(using: .utf8)?.count ?? 0
        
        return !trimmedText.isEmpty && charCount <= 2000 && byteCount <= 1500
    }
    
    var body: some View {
        ZStack {
            // Фон
            Color(red: 0.95, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Заголовок чата
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Общий чат GoMessage")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Мессенджер Преподобного Гу")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { /* Действия с чатом */ }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(SwiftUI.Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                
                // Сообщения
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Системное сообщение всегда в самом верху
                                MessageBubbleView(
                                    message: Message(
                                        id: 0, // Системный ID
                                        content: "Добро пожаловать в GoMessage, мессенджер Преподобного Гу! Как говорил Фан Юань: \"Связь между людьми - это величайшая магия из всех.\" Приятного чаттинга, культивируем.",
                                        type: "text",
                                        sender: User(
                                            id: 0, // Системный ID
                                            username: "🏮 Система",
                                            email: "",
                                            avatar: nil,
                                            status: "system",
                                            createdAt: Date(),
                                            updatedAt: nil
                                        ),
                                        chatID: chat.id,
                                        replyToID: nil,
                                        isEdited: false,
                                        createdAt: Date(),
                                        updatedAt: nil
                                    ),
                                    isFromCurrentUser: false
                                )
                                .id("system_message")
                                
                                // История сообщений
                                ForEach(messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        isFromCurrentUser: message.sender.username == apiService.currentUser?.username
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            // Прокручиваем к последнему сообщению при появлении
                            if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Поле ввода
                VStack(spacing: 0) {
                    // Счетчик символов и байт
                    HStack {
                        Spacer()
                        let charCount = newMessageText.count
                        let byteCount = newMessageText.data(using: .utf8)?.count ?? 0
                        let maxChars = 2000
                        let maxBytes = 1500
                        
                        Text("\(charCount)/\(maxChars) символов (\(byteCount)/\(maxBytes) байт)")
                            .font(.system(size: 10))
                            .foregroundColor(
                                charCount > maxChars || byteCount > maxBytes ? .red :
                                charCount > maxChars * 8/10 || byteCount > maxBytes * 8/10 ? .orange : .secondary
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                    }
                    
                    // Поле ввода
                    HStack(spacing: 12) {
                        // Поле ввода
                        HStack {
                            TextField("Сообщение...", text: $newMessageText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onChange(of: newMessageText) { newValue in
                                    // Отправляем статус печати
                                    let isTyping = !newValue.isEmpty
                                    webSocketService.sendTyping(chatID: chat.id, isTyping: isTyping)
                                }
                            
                            if !newMessageText.isEmpty {
                                Button(action: { newMessageText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(SwiftUI.Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Кнопка отправки
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(canSendMessage ? .blue : .secondary)
                        }
                        .disabled(!canSendMessage)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(SwiftUI.Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            webSocketService.connect()
            loadMessages()
            
            // Подписываемся на уведомления о новых сообщениях
            NotificationCenter.default.addObserver(
                forName: .newMessageReceived,
                object: nil,
                queue: .main
            ) { notification in
                if let newMessage = notification.object as? Message {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.messages.append(newMessage)
                    }
                }
            }
        }
        .onDisappear {
            webSocketService.sendTyping(chatID: chat.id, isTyping: false)
        }
    }
    
    private func loadMessages() {
        isLoading = true
        
        apiService.getChatMessages(chatID: chat.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("Failed to load messages: \(error)")
                        // Если не удалось загрузить, показываем пустой список
                        self.messages = []
                    }
                },
                receiveValue: { loadedMessages in
                    print("✅ Загружено сообщений: \(loadedMessages.count)")
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.messages = loadedMessages
                    }
                }
            )
            .store(in: &apiService.cancellables)
    }
    
        private func sendMessage() {
        guard canSendMessage else { return }
        
        let messageText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let charCount = messageText.count
        let byteCount = messageText.data(using: .utf8)?.count ?? 0
        
        // Дополнительная проверка лимитов
        guard charCount <= 2000 else {
            // Можно добавить показ алерта об ошибке
            print("Превышен лимит символов: \(charCount)/2000")
            return
        }
        
        guard byteCount <= 1500 else {
            // Можно добавить показ алерта об ошибке
            print("Превышен лимит байт: \(byteCount)/1500")
            return
        }
        
        newMessageText = ""
        
        // Отправляем сообщение через WebSocket, как на сайте
        webSocketService.sendChatMessage(content: messageText, chatID: chat.id)
        
        // НЕ создаем временное сообщение - будем ждать подтверждения от WebSocket
        // Это предотвратит дублирование
    }
    

}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.65, green: 0.38, blue: 0.18), // #a7612f
                                            Color(red: 0.83, green: 0.54, blue: 0.24), // #d58a3d
                                            Color(red: 1.0, green: 0.82, blue: 0.35)   // #ffd15a
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    
                    HStack(spacing: 4) {
                        Text(formatTime(message.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8)) // ТОЧНО КАК НА САЙТЕ
                        
                        if message.isEdited {
                            Text("ред.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // Проверяем, системное ли это сообщение
                    let isSystemMessage = message.sender.username == "🏮 Система"
                    
                    HStack(spacing: 8) {
                        // Аватар отправителя
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isSystemMessage ? Color.orange.opacity(0.8) : Color.green.opacity(0.8),
                                        isSystemMessage ? Color.red.opacity(0.8) : Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(isSystemMessage ? "🏮" : String(message.sender.username.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.sender.username)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSystemMessage ? .orange : .secondary)
                    }
                    
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isSystemMessage ? Color.orange.opacity(0.1) : SwiftUI.Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isSystemMessage ? Color.orange.opacity(0.3) : Color(red: 0.91, green: 0.79, blue: 0.65).opacity(0.7), lineWidth: 1)
                                )
                        )
                    
                    HStack(spacing: 4) {
                        Text(formatTime(message.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(isSystemMessage ? .orange : .gray)
                        
                        if message.isEdited {
                            Text("ред.")
                                .font(.system(size: 11))
                                .foregroundColor(isSystemMessage ? .orange : .gray)
                        }
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
