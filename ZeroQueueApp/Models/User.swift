import Foundation

struct User: Codable, Identifiable {
    var id: String = UUID().uuidString
    var firstName: String
    var lastName: String
    var email: String
    var memberSince: Date = Date()
    var paymentMethod: PaymentMethod?
    var profiles: [MemberProfile] = []
    var totalTrips: Int = 0
    var totalSaved: Double = 0.0

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return "\(f)\(l)".uppercased()
    }

    var memberSinceFormatted: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: memberSince)
    }

    var timeSavedFormatted: String {
        String(format: "%.1f min", totalSaved)
    }
}

// MARK: - Payment Method
struct PaymentMethod: Codable, Identifiable {
    var id: String = UUID().uuidString
    var last4: String
    var brand: CardBrand
    var expiryMonth: Int
    var expiryYear: Int

    enum CardBrand: String, Codable, CaseIterable {
        case visa       = "Visa"
        case mastercard = "Mastercard"
        case amex       = "Amex"
        case discover   = "Discover"
    }

    var displayName: String { "\(brand.rawValue) •••• \(last4)" }
    var expiryDisplay: String { String(format: "%02d/%02d", expiryMonth, expiryYear % 100) }

    var brandIcon: String {
        switch brand {
        case .visa:       return "creditcard"
        case .mastercard: return "creditcard.fill"
        case .amex:       return "creditcard"
        case .discover:   return "creditcard.fill"
        }
    }
}

// MARK: - Member Profile (household)
struct MemberProfile: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var relationship: String
}

// MARK: - Mock Stores
struct MockStore: Identifiable {
    var id: String
    var name: String
    var address: String
    var distance: String
}

extension MockStore {
    static let all: [MockStore] = [
        MockStore(id: "store_001", name: "Kornhauser's Club",    address: "Nassau St, Princeton, NJ",         distance: "0.3 mi"),
        MockStore(id: "store_002", name: "McCaffrey's Market",   address: "301 N Harrison St, Princeton, NJ", distance: "0.8 mi"),
        MockStore(id: "store_003", name: "Whole Foods Market",   address: "1 Hulfish St, Princeton, NJ",      distance: "1.2 mi"),
        MockStore(id: "store_004", name: "ShopRite of Princeton", address: "3470 US-1, Princeton, NJ",        distance: "2.1 mi"),
    ]
}
