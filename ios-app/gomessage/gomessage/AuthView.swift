import SwiftUI
import Combine

struct AuthView: View {
    @StateObject private var apiService = APIService.shared
    @State private var isLogin = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var logoOffset: CGFloat = -200
    @State private var formOffset: CGFloat = 400
    @State private var logoScale: CGFloat = 0.5
    @State private var formOpacity: Double = 0
    
    // Валидация для регистрации
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isUsernameValid: Bool {
        return username.count >= 3
    }
    
    private var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    private var canRegister: Bool {
        return isEmailValid && isUsernameValid && isPasswordValid && !email.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    private var canLogin: Bool {
        return !username.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.3, green: 0.4, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Логотип
                VStack(spacing: 16) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                        .offset(y: logoOffset)
                    
                    Text("GoMessage")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: logoOffset)
                }
                
                // Форма
                VStack(spacing: 20) {
                    // Переключатель входа/регистрации
                    HStack(spacing: 0) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isLogin = true } }) {
                            Text("Вход")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isLogin ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(isLogin ? Color.white.opacity(0.2) : Color.clear)
                                )
                        }
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isLogin = false } }) {
                            Text("Регистрация")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(!isLogin ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(!isLogin ? Color.white.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    
                    // Поля ввода
                    VStack(spacing: 16) {
                        if !isLogin {
                            CustomTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope.fill",
                                isValid: email.isEmpty || isEmailValid,
                                validationMessage: email.isEmpty ? nil : (isEmailValid ? nil : "Неверный формат email")
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        CustomTextField(
                            text: $username,
                            placeholder: "Имя пользователя",
                            icon: "person.fill",
                            isValid: username.isEmpty || isUsernameValid,
                            validationMessage: username.isEmpty ? nil : (isUsernameValid ? nil : "Минимум 3 символа")
                        )
                        
                        CustomTextField(
                            text: $password,
                            placeholder: "Пароль",
                            icon: "lock.fill",
                            isSecure: true,
                            isValid: password.isEmpty || isPasswordValid,
                            validationMessage: password.isEmpty ? nil : (isPasswordValid ? nil : "Минимум 6 символов")
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Кнопка действия
                    Button(action: handleAuth) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isLogin ? "Войти" : "Зарегистрироваться")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            (isLogin ? canLogin : canRegister) ? Color(red: 0.2, green: 0.6, blue: 1.0) : Color.gray,
                                            (isLogin ? canLogin : canRegister) ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color.gray.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: (isLogin ? canLogin : canRegister) ? Color.blue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading || (isLogin ? !canLogin : !canRegister))
                    .padding(.horizontal, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .offset(y: formOffset)
                .opacity(formOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 1.0)) {
            logoOffset = 0
            logoScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                formOffset = 0
                formOpacity = 1
            }
        }
    }
    
    private func handleAuth() {
        isLoading = true
        
        if isLogin {
            // Вход
            apiService.login(username: username, password: password)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        if case .failure(let error) = completion {
                            print("🔴 Ошибка входа: \(error)")
                            
                            // Обрабатываем различные типы ошибок
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .invalidCredentials:
                                    errorMessage = "Неверный логин или пароль"
                                case .badRequest:
                                    errorMessage = "Неверные данные для входа"
                                case .serverError:
                                    errorMessage = "Ошибка сервера, попробуйте позже"
                                default:
                                    errorMessage = apiError.errorDescription ?? "Неизвестная ошибка"
                                }
                            } else {
                                errorMessage = error.localizedDescription
                            }
                            
                            showError = true
                        }
                    },
                    receiveValue: { response in
                        print("✅ Успешный вход: \(response)")
                        // Успешный вход
                    }
                )
                .store(in: &apiService.cancellables)
        } else {
            // Регистрация
            apiService.register(username: username, email: email, password: password)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            isLoading = false
                            print("🔴 Ошибка регистрации: \(error)")
                            
                            // Обрабатываем различные типы ошибок
                            if let apiError = error as? APIError {
                                switch apiError {
                                case .conflict(let message):
                                    // Показываем конкретное сообщение о конфликте
                                    errorMessage = message
                                case .badRequest:
                                    errorMessage = "Неверные данные для регистрации"
                                case .serverError:
                                    errorMessage = "Ошибка сервера, попробуйте позже"
                                default:
                                    errorMessage = apiError.errorDescription ?? "Неизвестная ошибка"
                                }
                            } else {
                                errorMessage = error.localizedDescription
                            }
                            
                            showError = true
                        }
                    },
                    receiveValue: { response in
                        print("✅ Успешная регистрация: \(response)")
                        // После успешной регистрации автоматически входим
                        apiService.login(username: username, password: password)
                            .receive(on: DispatchQueue.main)
                            .sink(
                                receiveCompletion: { completion in
                                    isLoading = false
                                    if case .failure(let error) = completion {
                                        print("🔴 Ошибка автоматического входа после регистрации: \(error)")
                                        errorMessage = "Регистрация успешна, но не удалось войти. Попробуйте войти вручную."
                                        showError = true
                                    }
                                },
                                receiveValue: { loginResponse in
                                    print("✅ Автоматический вход после регистрации: \(loginResponse)")
                                    // Успешный вход после регистрации
                                }
                            )
                            .store(in: &apiService.cancellables)
                    }
                )
                .store(in: &apiService.cancellables)
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var isValid: Bool = true
    var validationMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isValid ? Color.white.opacity(0.2) : Color.red.opacity(0.6),
                                lineWidth: isValid ? 1 : 2
                            )
                    )
            )
            
            if let message = validationMessage, !isValid {
                Text(message)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            }
        }
    }
}
