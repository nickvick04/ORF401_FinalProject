import SwiftUI
import Combine

class AppState: ObservableObject {

    // MARK: - Auth
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    // MARK: - Shopping
    @Published var activeSession: ShoppingSession?
    @Published var cart: [CartItem] = []

    // MARK: - Computed
    var cartTotal: Double {
        cart.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    var cartItemCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }

    var formattedCartTotal: String {
        String(format: "$%.2f", cartTotal)
    }

    // MARK: - Auth Actions
    func login(user: User) {
        currentUser = user
        isLoggedIn = true
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "zq_user")
        }
        UserDefaults.standard.set(true, forKey: "zq_loggedIn")
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        activeSession = nil
        cart = []
        UserDefaults.standard.removeObject(forKey: "zq_user")
        UserDefaults.standard.set(false, forKey: "zq_loggedIn")
    }

    // MARK: - Session Actions
    func startSession(store: MockStore) {
        activeSession = ShoppingSession(storeId: store.id, storeName: store.name, storeAddress: store.address)
        cart = []
    }

    func endSession() {
        if var user = currentUser {
            user.totalTrips += 1
            user.totalSaved += Double.random(in: 2.5...6.0)
            currentUser = user
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "zq_user")
            }
        }
        activeSession = nil
        cart = []
    }

    // MARK: - Cart Actions
    func addToCart(_ item: CartItem) {
        if let index = cart.firstIndex(where: { $0.barcode == item.barcode }) {
            cart[index].quantity += 1
        } else {
            var newItem = item
            newItem.quantity = 1
            cart.append(newItem)
        }
    }

    func removeFromCart(_ item: CartItem) {
        cart.removeAll { $0.id == item.id }
    }

    func updateQuantity(for item: CartItem, delta: Int) {
        guard let index = cart.firstIndex(where: { $0.id == item.id }) else { return }
        let newQty = cart[index].quantity + delta
        if newQty <= 0 {
            cart.remove(at: index)
        } else {
            cart[index].quantity = newQty
        }
    }

    // MARK: - Init (restore session)
    init() {
        if UserDefaults.standard.bool(forKey: "zq_loggedIn"),
           let data = UserDefaults.standard.data(forKey: "zq_user"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isLoggedIn = true
        }
    }
}
