import SwiftUI

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func customShadow(color: Color = .black, radius: CGFloat = 3, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    func animateOnAppear(delay: Double = 0, animation: Animation = .easeOut(duration: 0.5)) -> some View {
        self.modifier(AnimateOnAppearModifier(delay: delay, animation: animation))
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Custom Modifiers

struct AnimateOnAppearModifier: ViewModifier {
    let delay: Double
    let animation: Animation
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(animation) {
                        hasAppeared = true
                    }
                }
            }
    }
}

// MARK: - Color Extensions

extension Color {
    static let customBackground = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let customBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let customPurple = Color(red: 0.4, green: 0.2, blue: 0.8)
    static let customGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let springSmooth = Animation.spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0)
    static let easeOutQuart = Animation.easeOut(duration: 0.4)
    static let easeInOutQuart = Animation.easeInOut(duration: 0.4)
}

// MARK: - Date Extensions

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func isThisWeek() -> Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - String Extensions

extension String {
    var initials: String {
        let words = self.components(separatedBy: .whitespaces)
        let initials = words.compactMap { $0.first }
        return String(initials.prefix(2)).uppercased()
    }
    
    func truncate(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
}
