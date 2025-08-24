import SwiftUI

// MARK: - App Constants

struct AppConstants {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let background = Color(red: 0.95, green: 0.97, blue: 1.0)
        static let cardBackground = Color.white
        static let accent = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Градиенты
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.6, blue: 1.0),
                Color(red: 0.4, green: 0.8, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondaryGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.3, blue: 0.6),
                Color(red: 0.3, green: 0.4, blue: 0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let avatarGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 25
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = AppShadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        static let medium = AppShadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        static let large = AppShadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Animations
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let normal = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }
    
    // MARK: - API
    struct API {
        static let baseURL = "http://YOUR_IP_FROM_CONSOLE:8080"
        static let apiVersion = "v1"
        static let timeout: TimeInterval = 30
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let authToken = "authToken"
        static let currentUser = "currentUser"
        static let lastSync = "lastSync"
        static let settings = "settings"
    }
    
    // MARK: - Message Types
    struct MessageTypes {
        static let text = "text"
        static let image = "image"
        static let file = "file"
        static let voice = "voice"
        static let location = "location"
    }
    
    // MARK: - User Status
    struct UserStatus {
        static let online = "online"
        static let away = "away"
        static let busy = "busy"
        static let offline = "offline"
    }
}

// MARK: - Shadow Helper

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func applyShadow(_ shadow: AppShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
