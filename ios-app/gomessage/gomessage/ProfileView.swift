import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var apiService = APIService.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Заголовок профиля
                        VStack(spacing: 20) {
                            // Аватар
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.8),
                                                Color.purple.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                                
                                if let avatar = apiService.currentUser?.avatar, !avatar.isEmpty {
                                    AsyncImage(url: URL(string: avatar)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Text(String(apiService.currentUser?.username.prefix(1) ?? "?").uppercased())
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Text(String(apiService.currentUser?.username.prefix(1) ?? "?").uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                // Индикатор статуса
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .offset(x: 40, y: 40)
                            }
                            
                            // Имя пользователя и статус
                            VStack(spacing: 8) {
                                Text(apiService.currentUser?.username ?? "Пользователь")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(apiService.currentUser?.status ?? "online")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.top, 20)
                        
                        // Информация о пользователе
                        VStack(spacing: 16) {
                            ProfileInfoRow(
                                icon: "calendar",
                                title: "Дата регистрации",
                                value: formatDate(apiService.currentUser?.createdAt ?? Date())
                            )
                            
                            ProfileInfoRow(
                                icon: "clock.fill",
                                title: "Последнее обновление",
                                value: formatDate(apiService.currentUser?.updatedAt ?? Date())
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Действия
                        VStack(spacing: 16) {
                            Button(action: { showLogoutAlert = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                    
                                    Text("Выйти из аккаунта")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Выйти из аккаунта", isPresented: $showLogoutAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Выйти", role: .destructive) {
                logout()
            }
        } message: {
            Text("Вы уверены, что хотите выйти из аккаунта?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    private func logout() {
        apiService.logout()
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
