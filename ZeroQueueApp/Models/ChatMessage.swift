import Foundation

struct ChatMessage: Identifiable, Equatable {
    var id: String = UUID().uuidString
    var role: Role
    var content: String
    var timestamp: Date = Date()
    var isLoading: Bool = false

    enum Role { case user, assistant }

    var isUser: Bool { role == .user }
}

// Suggested prompts shown on empty state
extension ChatMessage {
    static let suggestedPrompts: [SuggestedPrompt] = [
        SuggestedPrompt(icon: "heart.text.square",  label: "Health check",       text: "Are there any unhealthy items in my cart? Suggest healthier swaps."),
        SuggestedPrompt(icon: "arrow.triangle.turn.up.right.diamond", label: "Store route", text: "What's the most efficient order to grab items in a grocery store?"),
        SuggestedPrompt(icon: "chart.bar.xaxis",    label: "Brand comparison",   text: "Compare the brands of items in my cart — which are best value?"),
        SuggestedPrompt(icon: "tag",                label: "Pricing insight",    text: "How do my cart prices compare to typical grocery store prices?"),
        SuggestedPrompt(icon: "fork.knife",         label: "Meal ideas",         text: "What meals can I make with the items in my cart?"),
        SuggestedPrompt(icon: "allergens",          label: "Allergen check",     text: "Flag any common allergens across my cart items."),
    ]
}

struct SuggestedPrompt: Identifiable {
    var id: String = UUID().uuidString
    var icon: String
    var label: String
    var text: String
}
