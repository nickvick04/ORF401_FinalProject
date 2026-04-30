import SwiftUI

// MARK: - Root onboarding container
struct OnboardingView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeScreen(path: $path)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .signUp:
                        SignUpScreen(path: $path)
                    case .payment(let firstName, let lastName, let email):
                        AddPaymentScreen(path: $path, firstName: firstName, lastName: lastName, email: email)
                    }
                }
        }
    }
}

enum OnboardingStep: Hashable {
    case signUp
    case payment(firstName: String, lastName: String, email: String)
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color.zqNavy.ignoresSafeArea()

            // Background glow
            RadialGradient(
                colors: [Color.zqTeal.opacity(0.12), Color.clear],
                center: .topTrailing, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.zqTeal.opacity(0.12))
                            .frame(width: 84, height: 84)
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.zqTeal)
                    }
                    Text("ZeroQueue")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Checkout reimagined.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.zqMuted)
                }

                Spacer()

                // Value props
                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(icon: "barcode.viewfinder", title: "Scan as you shop",    sub: "Build your cart in real time with your phone")
                    FeatureRow(icon: "bolt.fill",          title: "Skip the checkout line", sub: "Pay and walk out — no waiting, no cashier")
                    FeatureRow(icon: "checkmark.shield",   title: "Protected membership",   sub: "Your history keeps you trusted at every store")
                }
                .padding(.horizontal, 28)

                Spacer()

                // CTAs
                VStack(spacing: 12) {
                    Button("Get Started") { path.append(OnboardingStep.signUp) }
                        .zqPrimaryButton()

                    Button("I already have an account") { path.append(OnboardingStep.signUp) }
                        .zqGhostButton()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let sub: String
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.zqTeal.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.zqTeal)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(sub).font(.system(size: 13)).foregroundColor(.zqMuted)
            }
        }
    }
}

// MARK: - Sign Up Screen
struct SignUpScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var appState: AppState

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var email     = ""
    @State private var password  = ""
    @State private var showError = false

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && password.count >= 6
    }

    var body: some View {
        ZStack {
            Color.zqNavy.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Step 1 of 2").padding(.bottom, 10)
                    Text("Create your\naccount")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 36)

                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZQTextField(placeholder: "First name", text: $firstName)
                            ZQTextField(placeholder: "Last name",  text: $lastName)
                        }
                        ZQTextField(placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                        ZQTextField(placeholder: "Password (6+ chars)", text: $password, isSecure: true)
                    }

                    if showError {
                        Text("Please fill in all fields correctly.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.zqWarn)
                            .padding(.top, 10)
                    }

                    Button("Continue") {
                        if isValid {
                            path.append(OnboardingStep.payment(firstName: firstName, lastName: lastName, email: email))
                        } else {
                            showError = true
                        }
                    }
                    .zqPrimaryButton()
                    .padding(.top, 28)
                }
                .padding(28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Add Payment Screen
struct AddPaymentScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var appState: AppState

    let firstName: String
    let lastName: String
    let email: String

    @State private var cardNumber  = ""
    @State private var expiry      = ""
    @State private var cvv         = ""
    @State private var nameOnCard  = ""
    @State private var isLoading   = false

    var body: some View {
        ZStack {
            Color.zqNavy.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: "Step 2 of 2").padding(.bottom, 10)
                    Text("Add a payment\nmethod")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    Text("Stored securely. Charged only at checkout.")
                        .font(.system(size: 14))
                        .foregroundColor(.zqMuted)
                        .padding(.bottom, 32)

                    // Mock card preview
                    MockCardPreview(number: cardNumber, name: nameOnCard, expiry: expiry)
                        .padding(.bottom, 28)

                    VStack(spacing: 14) {
                        ZQTextField(placeholder: "Name on card", text: $nameOnCard)
                        ZQTextField(placeholder: "Card number", text: $cardNumber, keyboardType: .numberPad)
                            .onChange(of: cardNumber) { _, new in cardNumber = formatCardNumber(new) }
                        HStack(spacing: 14) {
                            ZQTextField(placeholder: "MM/YY", text: $expiry, keyboardType: .numberPad)
                                .onChange(of: expiry) { _, new in expiry = formatExpiry(new) }
                            ZQTextField(placeholder: "CVV", text: $cvv, keyboardType: .numberPad, isSecure: true)
                        }
                    }

                    Button {
                        finishOnboarding()
                    } label: {
                        if isLoading {
                            ProgressView().tint(.zqNavy)
                        } else {
                            Text("Finish Setup")
                        }
                    }
                    .zqPrimaryButton()
                    .padding(.top, 28)
                    .disabled(isLoading)

                    Button("Skip for now") { finishOnboarding(skipPayment: true) }
                        .font(.system(size: 15))
                        .foregroundColor(.zqMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
                .padding(28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func finishOnboarding(skipPayment: Bool = false) {
        isLoading = true
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let payment: PaymentMethod? = skipPayment ? nil : PaymentMethod(
                last4: String(cardNumber.replacingOccurrences(of: " ", with: "").suffix(4)).isEmpty ? "0000" : String(cardNumber.replacingOccurrences(of: " ", with: "").suffix(4)),
                brand: .visa,
                expiryMonth: 12,
                expiryYear: 28
            )
            var user = User(firstName: firstName, lastName: lastName, email: email)
            user.paymentMethod = payment
            appState.login(user: user)
        }
    }

    private func formatCardNumber(_ s: String) -> String {
        let digits = String(s.filter(\.isNumber).prefix(16))
        return stride(from: 0, to: digits.count, by: 4)
            .map { i -> String in
                let start = digits.index(digits.startIndex, offsetBy: i)
                let end   = digits.index(start, offsetBy: min(4, digits.count - i))
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }

    private func formatExpiry(_ s: String) -> String {
        let digits = s.filter(\.isNumber).prefix(4)
        if digits.count > 2 { return String(digits.prefix(2)) + "/" + String(digits.dropFirst(2)) }
        return String(digits)
    }
}

// MARK: - Mock Card Preview
private struct MockCardPreview: View {
    let number: String
    let name: String
    let expiry: String

    var displayNumber: String {
        let digits = number.replacingOccurrences(of: " ", with: "")
        if digits.count < 4 { return "•••• •••• •••• ••••" }
        let last4 = String(digits.suffix(4))
        return "•••• •••• •••• \(last4)"
    }

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color.zqTeal.opacity(0.7), Color.zqBlue.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(18)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text("ZERO")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text(displayNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARDHOLDER").font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
                        Text(name.isEmpty ? "YOUR NAME" : name.uppercased())
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("EXPIRES").font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
                        Text(expiry.isEmpty ? "MM/YY" : expiry)
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .padding(22)
        }
        .frame(height: 180)
        .shadow(color: Color.zqTeal.opacity(0.3), radius: 20, y: 6)
    }
}

// MARK: - Shared text field
struct ZQTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
            }
        }
        .font(.system(size: 16))
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.zqCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.zqBorder, lineWidth: 1))
    }
}
