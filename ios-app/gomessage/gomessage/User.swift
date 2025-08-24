import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String
    let avatar: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, avatar, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isOnline: Bool {
        return status == "online"
    }
    
    var statusColor: String {
        switch status {
        case "online": return "green"
        case "away": return "orange"
        case "busy": return "red"
        default: return "gray"
        }
    }
}

struct UserRegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct UserLoginRequest: Codable {
    let username: String
    let password: String
}

struct AuthResponse: Codable {
    let message: String
    let token: String
    let user: User
}

struct RegisterResponse: Codable {
    let message: String
    let user: RegisterUser
}

struct RegisterUser: Codable {
    let username: String
    let email: String
}

struct LoginResponse: Codable {
    let message: String
    let token: String
    let user: LoginUser
}

struct LoginUser: Codable {
    let id: Int
    let username: String
}

struct ChatsResponse: Codable {
    let chats: [Chat]
    let userID: Int
    
    enum CodingKeys: String, CodingKey {
        case chats
        case userID = "user_id"
    }
}
