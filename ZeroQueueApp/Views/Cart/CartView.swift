import SwiftUI

struct CartView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    @State private var showCheckout = false
    @State private var showCheckIn  = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                if appState.activeSession == nil {
                    noSessionView
                } else if appState.cart.isEmpty {
                    emptyCartView
                } else {
                    cartListView
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zqMid, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !appState.cart.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            withAnimation { appState.cart.removeAll() }
                        }
                        .foregroundColor(.zqMuted)
                        .font(.system(size: 14))
                    }
                }
            }
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInView()
            }
        }
    }

    // MARK: - Cart List
    private var cartListView: some View {
        VStack(spacing: 0) {
            // Store header
            if let session = appState.activeSession {
                HStack(spacing: 10) {
                    Image(systemName: "storefront")
                        .font(.system(size: 14))
                        .foregroundColor(.zqTeal)
                    Text(session.storeName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.zqOffwhite)
                    Spacer()
                    Text(session.elapsedDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(.zqMuted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.zqMid)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(appState.cart) { item in
                        CartItemRow(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 180) // room for checkout bar
            }

            // Checkout bar
            checkoutBar
        }
    }

    // MARK: - Checkout Bar
    private var checkoutBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.zqBorder)

            VStack(spacing: 12) {
                // Totals
                VStack(spacing: 8) {
                    TotalRow(label: "Subtotal", value: appState.formattedCartTotal)
                    TotalRow(label: "Tax (est.)", value: String(format: "$%.2f", appState.cartTotal * 0.07))
                    Divider().background(Color.zqBorder)
                    TotalRow(
                        label: "Total",
                        value: String(format: "$%.2f", appState.cartTotal * 1.07),
                        isBold: true
                    )
                }

                Button("Checkout — \(String(format: "$%.2f", appState.cartTotal * 1.07))") {
                    showCheckout = true
                }
                .zqPrimaryButton()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.zqNavy)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Empty Cart
    private var emptyCartView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.zqMuted.opacity(0.08)).frame(width: 90, height: 90)
                Image(systemName: "cart")
                    .font(.system(size: 36))
                    .foregroundColor(.zqMuted)
            }
            VStack(spacing: 8) {
                Text("Your cart is empty")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Scan items in the store to add them here.")
                    .font(.system(size: 14))
                    .foregroundColor(.zqMuted)
            }
            Button("Go to Scanner") { selectedTab = 1 }
                .zqPrimaryButton()
                .padding(.horizontal, 50)
        }
    }

    // MARK: - No Session
    private var noSessionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.zqMuted.opacity(0.08)).frame(width: 90, height: 90)
                Image(systemName: "storefront")
                    .font(.system(size: 36))
                    .foregroundColor(.zqMuted)
            }
            VStack(spacing: 8) {
                Text("Not checked in")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Check in to a store to start shopping.")
                    .font(.system(size: 14))
                    .foregroundColor(.zqMuted)
            }
            Button("Check In") { showCheckIn = true }
                .zqPrimaryButton()
                .padding(.horizontal, 50)
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    @EnvironmentObject var appState: AppState
    let item: CartItem

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.zqMid)
                    .frame(width: 52, height: 52)
                Image(systemName: "barcode")
                    .font(.system(size: 20))
                    .foregroundColor(.zqMuted)
            }

            // Name + brand
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundColor(.zqMuted)
                }
                Text(item.displayPrice + " each")
                    .font(.system(size: 12))
                    .foregroundColor(.zqMuted)
            }

            Spacer()

            // Quantity stepper + subtotal
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.displaySubtotal)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 0) {
                    Button {
                        withAnimation { appState.updateQuantity(for: item, delta: -1) }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.zqOffwhite)
                            .frame(width: 30, height: 30)
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28)

                    Button {
                        withAnimation { appState.updateQuantity(for: item, delta: +1) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.zqOffwhite)
                            .frame(width: 30, height: 30)
                    }
                }
                .background(Color.zqMid)
                .cornerRadius(8)
            }
        }
        .padding(14)
        .zqCard()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { appState.removeFromCart(item) }
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .tint(.red.opacity(0.8))
        }
    }
}

// MARK: - Total Row
private struct TotalRow: View {
    let label: String
    let value: String
    var isBold: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? .white : .zqMuted)
            Spacer()
            Text(value)
                .font(.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? .zqTeal : .zqOffwhite)
        }
    }
}
