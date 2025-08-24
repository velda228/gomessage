import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let content: String
    let type: String
    let sender: User
    let chatID: Int
    let replyToID: Int?
    let isEdited: Bool
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, sender
        case chatID = "chat_id"
        case replyToID = "reply_to_id"
        case isEdited = "is_edited"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isText: Bool {
        return type == "text"
    }
    
    var isImage: Bool {
        return type == "image"
    }
    
    var isFile: Bool {
        return type == "file"
    }
    
    var isVoice: Bool {
        return type == "voice"
    }
    
    var isLocation: Bool {
        return type == "location"
    }
}

struct MessageRequest: Codable {
    let content: String
    let type: String
    let chatID: Int
    let replyToID: Int?
    
    enum CodingKeys: String, CodingKey {
        case content, type
        case chatID = "chat_id"
        case replyToID = "reply_to_id"
    }
}

struct ChatMessagesResponse: Codable {
    let chatID: Int
    let messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case messages
    }
}

struct SendMessageResponse: Codable {
    let message: String
    let data: Message
}

struct Chat: Identifiable, Codable {
    let id: Int
    let name: String?
    let type: String
    let participants: [User]
    let lastMessage: Message?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, participants
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isGroupChat: Bool {
        return type == "group"
    }
    
    var isPrivateChat: Bool {
        return type == "private"
    }
}
