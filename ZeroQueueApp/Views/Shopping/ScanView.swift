import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCheckInPrompt = false
    @State private var lastScannedItem: CartItem? = nil
    @State private var showItemFlash = false
    @State private var isLookingUp = false
    @State private var torchOn = false

    var body: some View {
        ZStack {
            if appState.activeSession != nil {
                activeScanView
            } else {
                noSessionView
            }
        }
        .sheet(isPresented: $showCheckInPrompt) {
            CheckInView()
        }
    }

    // MARK: - Active Scan View
    private var activeScanView: some View {
        ZStack(alignment: .bottom) {
            // Camera
            BarcodeScannerView { barcode in
                guard !isLookingUp else { return }
                handleScan(barcode: barcode)
            }
            .ignoresSafeArea()

            // Scan overlay
            scanOverlay

            // Scan flash feedback
            if showItemFlash {
                Color.zqTeal.opacity(0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Bottom cart drawer
            VStack(spacing: 0) {
                Spacer()
                cartDrawer
            }
        }
    }

    // MARK: - Scan Overlay
    private var scanOverlay: some View {
        VStack {
            // Top bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.activeSession?.storeName ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Scan items to add to cart")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                Button {
                    torchOn.toggle()
                    toggleTorch(on: torchOn)
                } label: {
                    Image(systemName: torchOn ? "bolt.fill" : "bolt.slash")
                        .font(.system(size: 18))
                        .foregroundColor(torchOn ? .zqTeal : .white.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .background(
                LinearGradient(colors: [Color.black.opacity(0.6), .clear],
                               startPoint: .top, endPoint: .bottom)
            )

            Spacer()

            // Scan frame
            ScanFrame(isLoading: isLookingUp)

            Spacer()
        }
    }

    // MARK: - Cart Drawer
    private var cartDrawer: some View {
        VStack(spacing: 0) {
            // Last scanned item
            if let item = lastScannedItem {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.zqTeal.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.zqTeal)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("Added · \(item.displayPrice)")
                            .font(.system(size: 12))
                            .foregroundColor(.zqTeal)
                    }
                    Spacer()
                    Text("×\(item.quantity)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.zqMuted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.zqMid)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Summary bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appState.cartItemCount) item\(appState.cartItemCount == 1 ? "" : "s") in cart")
                        .font(.system(size: 12))
                        .foregroundColor(.zqMuted)
                    Text(appState.formattedCartTotal)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                NavigationLink(destination: CartView(selectedTab: .constant(2))) {
                    Text("View Cart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.zqNavy)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.zqTeal)
                        .cornerRadius(30)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.zqNavy.opacity(0.95))
            .padding(.bottom, 10) // tab bar clearance
        }
    }

    // MARK: - No Session View
    private var noSessionView: some View {
        ZStack {
            Color.zqNavy.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle().fill(Color.zqMuted.opacity(0.08)).frame(width: 100, height: 100)
                    Image(systemName: "storefront")
                        .font(.system(size: 40))
                        .foregroundColor(.zqMuted)
                }

                VStack(spacing: 10) {
                    Text("Not checked in")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Check in to a ZeroQueue store\nbefore scanning items.")
                        .font(.system(size: 15))
                        .foregroundColor(.zqMuted)
                        .multilineTextAlignment(.center)
                }

                Button("Check In to a Store") { showCheckInPrompt = true }
                    .zqPrimaryButton()
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Scan Handler
    private func handleScan(barcode: String) {
        isLookingUp = true
        Task {
            let product = await ProductLookupService.shared.lookup(barcode: barcode)
            await MainActor.run {
                let item: CartItem
                if let p = product {
                    item = p.toCartItem()
                } else {
                    item = CartItem(barcode: barcode, name: "Unknown Item", price: 0.99)
                }
                appState.addToCart(item)
                // Show the item in the drawer using current cart quantity
                let inCart = appState.cart.first { $0.barcode == barcode }
                lastScannedItem = inCart ?? item
                withAnimation(.easeOut(duration: 0.2)) { showItemFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { showItemFlash = false }
                }
                isLookingUp = false
            }
        }
    }

    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - Scan Frame
private struct ScanFrame: View {
    let isLoading: Bool

    var body: some View {
        ZStack {
            // Corner markers
            ForEach(0..<4, id: \.self) { i in
                CornerMark()
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            if isLoading {
                ProgressView()
                    .tint(.zqTeal)
                    .scaleEffect(1.4)
            } else {
                // Scan line
                ScanLine()
            }
        }
        .frame(width: 220, height: 220)
    }
}

private struct CornerMark: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Color.zqTeal).frame(width: 3, height: 28)
            Rectangle().fill(Color.zqTeal).frame(width: 28, height: 3)
        }
        .offset(x: -110, y: -110)
    }
}

private struct ScanLine: View {
    @State private var offset: CGFloat = -100

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.zqTeal.opacity(0), Color.zqTeal, Color.zqTeal.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: true)) {
                    offset = 100
                }
            }
    }
}

// MARK: - AVFoundation import for torch
import AVFoundation
