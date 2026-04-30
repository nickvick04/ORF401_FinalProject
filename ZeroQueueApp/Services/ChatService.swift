import Foundation

class ChatService: ObservableObject {
    static let shared = ChatService()

    private let apiKey = Secrets.groqAPIKey

    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model    = "llama3-8b-8192"

    // MARK: - Send message
    func send(
        messages: [ChatMessage],
        cart: [CartItem],
        session: ShoppingSession?,
        user: User?
    ) async throws -> String {

        let systemPrompt = buildSystemPrompt(cart: cart, session: session, user: user)

        // Build Groq-compatible message array
        var payload: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for msg in messages {
            payload.append([
                "role":    msg.role == .user ? "user" : "assistant",
                "content": msg.content
            ])
        }

        let body: [String: Any] = [
            "model":       model,
            "messages":    payload,
            "max_tokens":  512,
            "temperature": 0.7
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChatError.apiError("Status \(http.statusCode): \(msg)")
        }

        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content else {
            throw ChatError.emptyResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - System prompt
    private func buildSystemPrompt(cart: [CartItem], session: ShoppingSession?, user: User?) -> String {
        var prompt = """
        You are ZeroQueue's AI shopping assistant — friendly, concise, and helpful. \
        ZeroQueue is an app-based checkout system that lets shoppers scan items as they shop and skip the checkout line.

        You help shoppers with:
        - Health and nutrition insights about their cart items
        - Brand comparisons and value recommendations
        - Smart product suggestions and alternatives
        - Allergen and dietary flag warnings
        - Meal ideas based on cart contents
        - Store navigation tips and efficient shopping routes
        - General pricing context (note: prices shown are estimates)

        Keep responses short and scannable — the user is on their phone while shopping. \
        Use bullet points where helpful. Never make up specific in-store stock levels.
        """

        if let user = user {
            prompt += "\n\nShopper: \(user.fullName)"
        }

        if let session = session {
            prompt += "\nCurrently shopping at: \(session.storeName) (\(session.storeAddress))"
        }

        if cart.isEmpty {
            prompt += "\n\nThe shopper's cart is currently empty."
        } else {
            prompt += "\n\nCurrent cart:\n"
            for item in cart {
                let brand = item.brand.map { "\($0) – " } ?? ""
                prompt += "• \(brand)\(item.name) ×\(item.quantity) @ \(item.displayPrice) each (\(item.displaySubtotal))\n"
            }
            let total = cart.reduce(0.0) { $0 + $1.subtotal }
            prompt += "Cart total: \(String(format: "$%.2f", total))"
        }

        return prompt
    }
}

// MARK: - Errors
enum ChatError: LocalizedError {
    case invalidResponse
    case emptyResponse
    case apiError(String)
    case missingKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:  return "Invalid response from server."
        case .emptyResponse:    return "The assistant returned an empty response."
        case .apiError(let m):  return m
        case .missingKey:       return "No Groq API key set. Add your key in ChatService.swift."
        }
    }
}

// MARK: - Groq response models
private struct GroqResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let message: Message
    }
    struct Message: Codable {
        let content: String
    }
}
