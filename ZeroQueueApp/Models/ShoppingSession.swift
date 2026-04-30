import Foundation

struct ShoppingSession: Identifiable {
    var id: String = UUID().uuidString
    var storeId: String
    var storeName: String
    var storeAddress: String
    var startedAt: Date = Date()

    var elapsedMinutes: Int {
        Int(Date().timeIntervalSince(startedAt) / 60)
    }

    var elapsedDisplay: String {
        let mins = elapsedMinutes
        if mins < 1 { return "Just started" }
        if mins == 1 { return "1 min" }
        return "\(mins) min"
    }
}

// MARK: - Past Trip (purchase history)
struct PastTrip: Identifiable {
    var id: String = UUID().uuidString
    var storeName: String
    var date: Date
    var itemCount: Int
    var total: Double

    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    var formattedTotal: String { String(format: "$%.2f", total) }
}

extension PastTrip {
    static let mockHistory: [PastTrip] = [
        PastTrip(storeName: "Kornhauser's Club",    date: Calendar.current.date(byAdding: .day, value: -2,  to: Date())!, itemCount: 7,  total: 34.82),
        PastTrip(storeName: "McCaffrey's Market",   date: Calendar.current.date(byAdding: .day, value: -6,  to: Date())!, itemCount: 14, total: 67.19),
        PastTrip(storeName: "Whole Foods Market",   date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, itemCount: 5,  total: 28.44),
        PastTrip(storeName: "Kornhauser's Club",    date: Calendar.current.date(byAdding: .day, value: -18, to: Date())!, itemCount: 11, total: 51.07),
        PastTrip(storeName: "ShopRite of Princeton",date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!, itemCount: 22, total: 89.33),
    ]
}
