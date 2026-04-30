import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let zqNavy    = Color(hex: "09111F")
    static let zqMid     = Color(hex: "101E35")
    static let zqCard    = Color(hex: "131F38")
    static let zqTeal    = Color(hex: "00C2A8")
    static let zqBlue    = Color(hex: "1B7FD4")
    static let zqWarn    = Color(hex: "F5A623")
    static let zqWhite   = Color.white
    static let zqOffwhite = Color(hex: "C8DCF0")
    static let zqMuted   = Color(hex: "5E7A99")
    static let zqBorder  = Color.white.opacity(0.08)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,255,255,255)
        }
        self.init(.sRGB,
                  red:   Double(r)/255,
                  green: Double(g)/255,
                  blue:  Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - Reusable Modifiers
struct ZQCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.zqCard)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zqBorder, lineWidth: 1))
    }
}

struct ZQPrimaryButton: ViewModifier {
    var isLoading: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.zqNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.zqTeal)
            .cornerRadius(50)
            .shadow(color: Color.zqTeal.opacity(0.35), radius: 18, y: 4)
    }
}

struct ZQGhostButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.zqWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.white.opacity(0.22), lineWidth: 1.5))
            .cornerRadius(50)
    }
}

extension View {
    func zqCard() -> some View { modifier(ZQCard()) }
    func zqPrimaryButton() -> some View { modifier(ZQPrimaryButton()) }
    func zqGhostButton() -> some View { modifier(ZQGhostButton()) }
}

// MARK: - Eyebrow Label
struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(3)
            .foregroundColor(.zqTeal)
    }
}
