import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var phase: CheckoutPhase = .review
    @State private var isProcessing = false

    enum CheckoutPhase { case review, processing, success }

    var subtotal: Double { appState.cartTotal }
    var tax: Double { subtotal * 0.07 }
    var total: Double { subtotal + tax }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                switch phase {
                case .review:    reviewView
                case .processing: processingView
                case .success:   successView
                }
            }
            .navigationTitle(phase == .review ? "Checkout" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if phase == .review {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.zqMuted)
                    }
                }
            }
            .toolbarBackground(Color.zqMid, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Review
    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Store info
                if let session = appState.activeSession {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.zqTeal.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "storefront")
                                .font(.system(size: 16))
                                .foregroundColor(.zqTeal)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.storeName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text(session.storeAddress)
                                .font(.system(size: 12))
                                .foregroundColor(.zqMuted)
                        }
                    }
                    .padding(16)
                    .zqCard()
                }

                // Items summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(spacing: 0) {
                        ForEach(appState.cart) { item in
                            HStack {
                                Text(item.name).lineLimit(1)
                                    .font(.system(size: 14)).foregroundColor(.zqOffwhite)
                                Spacer()
                                Text("×\(item.quantity)")
                                    .font(.system(size: 13)).foregroundColor(.zqMuted)
                                    .padding(.trailing, 8)
                                Text(item.displaySubtotal)
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            }
                            .padding(.vertical, 10)
                            if item.id != appState.cart.last?.id {
                                Divider().background(Color.zqBorder)
                            }
                        }
                    }
                    .padding(16)
                    .zqCard()
                }

                // Totals
                VStack(spacing: 10) {
                    Text("Payment")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        CheckoutTotalRow(label: "Subtotal", value: String(format: "$%.2f", subtotal))
                        CheckoutTotalRow(label: "Tax (7%)",  value: String(format: "$%.2f", tax))
                        Divider().background(Color.zqBorder)
                        CheckoutTotalRow(label: "Total", value: String(format: "$%.2f", total), isBold: true, accent: true)

                        Divider().background(Color.zqBorder)

                        // Payment method
                        if let pm = appState.currentUser?.paymentMethod {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.zqMuted)
                                    .font(.system(size: 14))
                                Text(pm.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.zqOffwhite)
                                Spacer()
                                Text("On file")
                                    .font(.system(size: 12))
                                    .foregroundColor(.zqMuted)
                            }
                        } else {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.zqMuted)
                                    .font(.system(size: 14))
                                Text("Demo payment (no charge)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.zqMuted)
                            }
                        }
                    }
                    .padding(16)
                    .zqCard()
                }

                // Confirm button
                Button("Confirm & Pay \(String(format: "$%.2f", total))") {
                    processPayment()
                }
                .zqPrimaryButton()

                Text("This is a demo — no real payment will be processed.")
                    .font(.system(size: 11))
                    .foregroundColor(.zqMuted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 24)
            }
            .padding(20)
        }
    }

    // MARK: - Processing
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.6)
                .tint(.zqTeal)
            Text("Processing payment…")
                .font(.system(size: 16))
                .foregroundColor(.zqMuted)
            Spacer()
        }
    }

    // MARK: - Success
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Check animation
                ZStack {
                    Circle()
                        .fill(Color.zqTeal.opacity(0.10))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(Color.zqTeal.opacity(0.18))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.zqTeal)
                }

                VStack(spacing: 8) {
                    Text("You're good to go!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Payment complete")
                        .font(.system(size: 16))
                        .foregroundColor(.zqTeal)
                    Text("Thank you for shopping with ZeroQueue.\nNo waiting — just walk out.")
                        .font(.system(size: 14))
                        .foregroundColor(.zqMuted)
                        .multilineTextAlignment(.center)
                }

                // Receipt summary
                VStack(spacing: 8) {
                    ReceiptRow(label: "Items",   value: "\(appState.cart.reduce(0) { $0 + $1.quantity })")
                    ReceiptRow(label: "Total",   value: String(format: "$%.2f", total))
                    if let session = appState.activeSession {
                        ReceiptRow(label: "Store", value: session.storeName)
                    }
                }
                .padding(18)
                .zqCard()
                .padding(.horizontal, 24)
            }

            Spacer()

            Button("Done") {
                appState.endSession()
                dismiss()
            }
            .zqPrimaryButton()
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Payment Logic
    private func processPayment() {
        withAnimation { phase = .processing }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring()) { phase = .success }
        }
    }
}

// MARK: - Helpers
private struct CheckoutTotalRow: View {
    let label: String
    let value: String
    var isBold: Bool = false
    var accent: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? .white : .zqMuted)
            Spacer()
            Text(value)
                .font(.system(size: isBold ? 18 : 14, weight: isBold ? .bold : .regular))
                .foregroundColor(accent ? .zqTeal : .zqOffwhite)
        }
    }
}

private struct ReceiptRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.zqMuted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.zqOffwhite)
        }
    }
}
