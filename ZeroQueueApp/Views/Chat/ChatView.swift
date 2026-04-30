import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ChatViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages or empty state
                    ScrollViewReader { proxy in
                        ScrollView {
                            if vm.messages.isEmpty {
                                emptyState
                            } else {
                                messagesView
                            }
                        }
                        .onChange(of: vm.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: vm.messages.last?.content) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }

                    inputBar
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !vm.messages.isEmpty {
                        Button("Clear") { vm.messages.removeAll() }
                            .font(.system(size: 14))
                            .foregroundColor(.zqMuted)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.zqTeal)
                            .frame(width: 7, height: 7)
                        Text("Llama 3 · Groq")
                            .font(.system(size: 11))
                            .foregroundColor(.zqMuted)
                    }
                }
            }
            .toolbarBackground(Color.zqMid, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onTapGesture { inputFocused = false }
        }
        .onAppear { vm.configure(appState: appState) }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 20)

            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.zqTeal.opacity(0.12)).frame(width: 72, height: 72)
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.zqTeal)
                }
                Text("Shopping Assistant")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Ask anything about your cart,\nhealth, pricing, or where to find items.")
                    .font(.system(size: 14))
                    .foregroundColor(.zqMuted)
                    .multilineTextAlignment(.center)
            }

            // Context pill
            if let session = appState.activeSession {
                HStack(spacing: 6) {
                    Image(systemName: "storefront").font(.system(size: 11))
                    Text("\(session.storeName) · \(appState.cartItemCount) item\(appState.cartItemCount == 1 ? "" : "s") in cart")
                        .font(.system(size: 12))
                }
                .foregroundColor(.zqTeal)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.zqTeal.opacity(0.1))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.zqTeal.opacity(0.25)))
            }

            // Suggested prompts grid
            VStack(alignment: .leading, spacing: 10) {
                Text("Try asking")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.zqMuted)
                    .padding(.leading, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ChatMessage.suggestedPrompts) { prompt in
                        SuggestedPromptCard(prompt: prompt) {
                            vm.send(text: prompt.text, appState: appState)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Messages
    private var messagesView: some View {
        LazyVStack(spacing: 14) {
            // Cart context pill at top of conversation
            if let session = appState.activeSession {
                HStack(spacing: 6) {
                    Image(systemName: "storefront").font(.system(size: 10))
                    Text("\(session.storeName) · \(appState.cartItemCount) item\(appState.cartItemCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                }
                .foregroundColor(.zqMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.zqMid)
                .cornerRadius(14)
                .padding(.top, 16)
            }

            ForEach(vm.messages) { message in
                MessageBubble(message: message)
                    .id(message.id)
            }

            Color.clear.frame(height: 8).id("bottom")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.zqBorder)
            HStack(spacing: 12) {
                TextField("Ask about your cart...", text: $vm.inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .onSubmit { sendIfPossible() }

                Button {
                    sendIfPossible()
                    inputFocused = false
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSend ? Color.zqTeal : Color.zqMuted.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: vm.isLoading ? "stop.fill" : "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(canSend ? .zqNavy : .zqMuted)
                    }
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.zqMid)
        }
    }

    private var canSend: Bool {
        !vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty && !vm.isLoading
    }

    private func sendIfPossible() {
        guard canSend else { return }
        vm.send(text: vm.inputText, appState: appState)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                // AI avatar
                ZStack {
                    Circle().fill(Color.zqTeal.opacity(0.15)).frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundColor(.zqTeal)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isLoading {
                    TypingIndicator()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.zqCard)
                        .cornerRadius(18)
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(message.isUser ? .zqNavy : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.zqTeal : Color.zqCard)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(message.isUser ? Color.clear : Color.zqBorder, lineWidth: 1)
                        )
                }
            }

            if !message.isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.zqMuted)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .onAppear { phase = 1 }
    }
}

// MARK: - Suggested Prompt Card
struct SuggestedPromptCard: View {
    let prompt: SuggestedPrompt
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: prompt.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.zqTeal)
                Text(prompt.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.zqCard)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.zqBorder))
        }
    }
}

// MARK: - ViewModel
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var appState: AppState?

    func configure(appState: AppState) {
        self.appState = appState
    }

    func send(text: String, appState: AppState) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }

        // Add user message
        let userMsg = ChatMessage(role: .user, content: trimmed)
        messages.append(userMsg)
        inputText = ""

        // Add loading placeholder
        let loadingId = UUID().uuidString
        let loadingMsg = ChatMessage(id: loadingId, role: .assistant, content: "", isLoading: true)
        messages.append(loadingMsg)
        isLoading = true

        Task {
            do {
                // Build history excluding the loading placeholder
                let history = messages.filter { !$0.isLoading }
                let reply = try await ChatService.shared.send(
                    messages: history,
                    cart: appState.cart,
                    session: appState.activeSession,
                    user: appState.currentUser
                )
                await MainActor.run {
                    replacePlaceholder(id: loadingId, with: reply)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    replacePlaceholder(id: loadingId, with: "Sorry, something went wrong: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }

    private func replacePlaceholder(id: String, with content: String) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx] = ChatMessage(id: id, role: .assistant, content: content, isLoading: false)
        }
    }
}
