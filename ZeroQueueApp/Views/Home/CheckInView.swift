import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var onStartShopping: (() -> Void)? = nil

    @State private var selectedStore: MockStore? = nil
    @State private var isCheckingIn = false
    @State private var didCheckIn   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                if didCheckIn, let store = selectedStore {
                    CheckInSuccessView(store: store) {
                        dismiss()
                        onStartShopping?()
                    }
                } else {
                    storeListView
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.zqMuted)
                }
            }
            .toolbarBackground(Color.zqMid, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var storeListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nearby Stores")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Select a ZeroQueue-enabled location to start your session.")
                        .font(.system(size: 14))
                        .foregroundColor(.zqMuted)
                }

                VStack(spacing: 12) {
                    ForEach(MockStore.all) { store in
                        StoreRow(
                            store: store,
                            isSelected: selectedStore?.id == store.id,
                            isLoading: isCheckingIn && selectedStore?.id == store.id
                        ) {
                            checkIn(to: store)
                        }
                    }
                }

                // QR code section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or scan a store QR code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.zqMuted)

                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 52))
                                .foregroundColor(.zqTeal.opacity(0.5))
                            Text("Point your camera at a store entrance QR code")
                                .font(.system(size: 13))
                                .foregroundColor(.zqMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .zqCard()
                        Spacer()
                    }
                }
            }
            .padding(20)
        }
    }

    private func checkIn(to store: MockStore) {
        selectedStore = store
        isCheckingIn = true
        // Simulate check-in API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            appState.startSession(store: store)
            isCheckingIn = false
            withAnimation { didCheckIn = true }
        }
    }
}

// MARK: - Store Row
private struct StoreRow: View {
    let store: MockStore
    let isSelected: Bool
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.zqTeal.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: "storefront")
                        .font(.system(size: 20))
                        .foregroundColor(.zqTeal)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(store.address)
                        .font(.system(size: 12))
                        .foregroundColor(.zqMuted)
                }

                Spacer()

                if isLoading {
                    ProgressView().tint(.zqTeal)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.zqMuted)
                        Text(store.distance)
                            .font(.system(size: 12))
                            .foregroundColor(.zqMuted)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.zqTeal.opacity(0.06) : Color.zqCard)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.zqTeal.opacity(0.5) : Color.zqBorder, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Success View
private struct CheckInSuccessView: View {
    let store: MockStore
    let onContinue: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.zqTeal.opacity(0.12))
                        .frame(width: 110, height: 110)
                    Circle()
                        .fill(Color.zqTeal.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.zqTeal)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 8) {
                    Text("You're checked in!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(store.name)
                        .font(.system(size: 16))
                        .foregroundColor(.zqTeal)
                    Text("Start scanning items as you shop.\nTap 'Cart' when you're ready to check out.")
                        .font(.system(size: 14))
                        .foregroundColor(.zqMuted)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button("Start Shopping", action: onContinue)
                .zqPrimaryButton()
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }
        }
    }
}
