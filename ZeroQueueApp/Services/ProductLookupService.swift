import Foundation

actor ProductLookupService {
    static let shared = ProductLookupService()
    private var cache: [String: ScannedProduct] = [:]

    // Offline mock database (common grocery barcodes)
    private let mockDB: [String: ScannedProduct] = [
        "049000028928": ScannedProduct(barcode: "049000028928", name: "Coca-Cola Classic",       brand: "Coca-Cola",     imageURL: nil, estimatedPrice: 1.99),
        "049000006346": ScannedProduct(barcode: "049000006346", name: "Sprite",                  brand: "Coca-Cola",     imageURL: nil, estimatedPrice: 1.89),
        "012000001086": ScannedProduct(barcode: "012000001086", name: "Pepsi Cola",               brand: "Pepsi",         imageURL: nil, estimatedPrice: 1.99),
        "028400090100": ScannedProduct(barcode: "028400090100", name: "Classic Potato Chips",     brand: "Lay's",         imageURL: nil, estimatedPrice: 4.29),
        "028400589154": ScannedProduct(barcode: "028400589154", name: "Doritos Nacho Cheese",     brand: "Doritos",       imageURL: nil, estimatedPrice: 4.79),
        "038000845000": ScannedProduct(barcode: "038000845000", name: "Corn Flakes Cereal",       brand: "Kellogg's",     imageURL: nil, estimatedPrice: 3.79),
        "016000275270": ScannedProduct(barcode: "016000275270", name: "Honey Nut Cheerios",       brand: "General Mills", imageURL: nil, estimatedPrice: 4.99),
        "021130501502": ScannedProduct(barcode: "021130501502", name: "Granola Bars Oats & Honey",brand: "Nature Valley", imageURL: nil, estimatedPrice: 3.49),
        "044000032036": ScannedProduct(barcode: "044000032036", name: "Oreo Cookies",             brand: "Nabisco",       imageURL: nil, estimatedPrice: 4.19),
        "040000416227": ScannedProduct(barcode: "040000416227", name: "Snickers Bar",             brand: "Mars",          imageURL: nil, estimatedPrice: 1.49),
        "034000020324": ScannedProduct(barcode: "034000020324", name: "Tide Original Liquid",     brand: "Tide",          imageURL: nil, estimatedPrice: 11.99),
        "037000863724": ScannedProduct(barcode: "037000863724", name: "Crest Cavity Protection",  brand: "Crest",         imageURL: nil, estimatedPrice: 3.49),
        "085239021880": ScannedProduct(barcode: "085239021880", name: "Unsweetened Almond Milk",  brand: "Silk",          imageURL: nil, estimatedPrice: 4.29),
        "070038595018": ScannedProduct(barcode: "070038595018", name: "Thomas' English Muffins",  brand: "Thomas'",       imageURL: nil, estimatedPrice: 4.49),
        "076808001193": ScannedProduct(barcode: "076808001193", name: "Orange Juice",             brand: "Tropicana",     imageURL: nil, estimatedPrice: 5.99),
    ]

    func lookup(barcode: String) async -> ScannedProduct? {
        // 1. Cache hit
        if let cached = cache[barcode] { return cached }

        // 2. Mock database hit
        if let mock = mockDB[barcode] {
            cache[barcode] = mock
            return mock
        }

        // 3. Open Food Facts API
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,image_front_url") else {
            return unknownProduct(barcode: barcode)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return unknownProduct(barcode: barcode)
            }
            let off = try JSONDecoder().decode(OFFResponse.self, from: data)
            if off.status == 1, let p = off.product {
                let rawName = p.product_name ?? ""
                let name = rawName.isEmpty ? "Unknown Product" : rawName
                let rawBrand = p.brands ?? ""
                let brand = rawBrand.isEmpty ? nil : rawBrand.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
                let product = ScannedProduct(
                    barcode: barcode,
                    name: name,
                    brand: brand,
                    imageURL: p.image_front_url,
                    estimatedPrice: randomPrice()
                )
                cache[barcode] = product
                return product
            }
        } catch {
            // Fall through to unknown
        }

        return unknownProduct(barcode: barcode)
    }

    private func unknownProduct(barcode: String) -> ScannedProduct {
        ScannedProduct(barcode: barcode, name: "Unknown Item", brand: nil, imageURL: nil, estimatedPrice: randomPrice())
    }

    private func randomPrice() -> Double {
        // Random plausible grocery price
        let prices = [0.99, 1.49, 1.99, 2.49, 2.99, 3.49, 3.99, 4.29, 4.99, 5.49, 5.99, 7.99, 9.99, 11.99]
        return prices.randomElement()!
    }
}

// MARK: - Open Food Facts response types
private struct OFFResponse: Codable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Codable {
    let product_name: String?
    let brands: String?
    let image_front_url: String?
}
