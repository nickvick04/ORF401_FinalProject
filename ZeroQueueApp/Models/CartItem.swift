import Foundation

struct CartItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var barcode: String
    var name: String
    var brand: String?
    var price: Double
    var quantity: Int = 1
    var imageURL: String?
    var addedAt: Date = Date()

    var subtotal: Double    { price * Double(quantity) }
    var displayPrice: String    { String(format: "$%.2f", price) }
    var displaySubtotal: String { String(format: "$%.2f", subtotal) }
    var displayName: String {
        if let b = brand, !b.isEmpty { return "\(b) – \(name)" }
        return name
    }
}

// MARK: - Scanned Product (from API)
struct ScannedProduct {
    var barcode: String
    var name: String
    var brand: String?
    var imageURL: String?
    var estimatedPrice: Double

    func toCartItem() -> CartItem {
        CartItem(
            barcode: barcode,
            name: name,
            brand: brand,
            price: estimatedPrice,
            imageURL: imageURL
        )
    }
}
