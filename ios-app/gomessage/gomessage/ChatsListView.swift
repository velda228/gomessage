import SwiftUI
import Combine

struct ChatsListView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var webSocketService = WebSocketService.shared
    @State private var showChat = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Text("Общий чат")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Добро пожаловать в GoMessage!")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Кнопка входа в чат
                    Button(action: { showChat = true }) {
                        HStack {
                            Image(systemName: "message.circle.fill")
                                .font(.system(size: 18))
                            Text("Войти в чат")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                    Spacer()
                    
                    // Информация о чате
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Общий чат GoMessage")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Общайтесь в реальном времени со всеми пользователями")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showChat) {
                ChatView(chat: Chat(
                    id: 1,
                    name: "Общий чат",
                    type: "group",
                    participants: [],
                    lastMessage: nil,
                    unreadCount: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                ))
            }
        }
    }
}

#Preview {
    ChatsListView()
}
