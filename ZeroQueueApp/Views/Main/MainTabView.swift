import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            ScanView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .tag(1)

            CartView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Cart", systemImage: selectedTab == 2 ? "cart.fill" : "cart")
                }
                .badge(appState.cartItemCount > 0 ? appState.cartItemCount : 0)
                .tag(2)

            ChatView()
                .tabItem {
                    Label("Assistant", systemImage: selectedTab == 3 ? "sparkles" : "sparkles")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(.zqTeal)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.zqMid)
        appearance.shadowColor = .clear

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
