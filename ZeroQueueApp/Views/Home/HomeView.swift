import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    @State private var showCheckIn = false

    var user: User { appState.currentUser ?? User(firstName: "Member", lastName: "", email: "") }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greeting)
                                    .font(.system(size: 14))
                                    .foregroundColor(.zqMuted)
                                Text(user.firstName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            AvatarCircle(initials: user.initials, size: 46)
                        }
                        .padding(.top, 8)

                        // Membership card
                        MembershipCard(user: user)

                        // Active session banner
                        if let session = appState.activeSession {
                            ActiveSessionBanner(session: session, selectedTab: $selectedTab)
                        }

                        // Quick actions
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Quick Actions")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.zqMuted)
                                .padding(.top, 4)

                            HStack(spacing: 14) {
                                if appState.activeSession == nil {
                                    QuickActionCard(icon: "qrcode.viewfinder", label: "Check In") {
                                        showCheckIn = true
                                    }
                                }
                                QuickActionCard(icon: "barcode.viewfinder", label: "Scan Item") {
                                    selectedTab = 1
                                }
                                QuickActionCard(icon: "cart", label: "View Cart") {
                                    selectedTab = 2
                                }
                            }
                        }

                        // Stats row
                        StatsRow(user: user)

                        // Recent trips
                        RecentTripsSection()

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCheckIn) {
                CheckInView(onStartShopping: { selectedTab = 1 })
            }
        }
    }
}

// MARK: - Membership Card
struct MembershipCard: View {
    let user: User

    var body: some View {
        ZStack(alignment: .leading) {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0D2640"), Color(hex: "0A1E35")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            // Teal glow
            Circle()
                .fill(Color.zqTeal.opacity(0.15))
                .frame(width: 160, height: 160)
                .offset(x: -30, y: -30)
                .blur(radius: 40)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ZeroQueue Member")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.zqTeal)
                        Text(user.fullName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(Color.zqTeal.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(.zqTeal)
                    }
                }
                .padding(.bottom, 22)

                HStack(spacing: 0) {
                    CardStat(label: "Member Since", value: user.memberSinceFormatted)
                    Divider().background(Color.zqBorder).frame(height: 30).padding(.horizontal, 16)
                    CardStat(label: "Trips", value: "\(user.totalTrips)")
                    Divider().background(Color.zqBorder).frame(height: 30).padding(.horizontal, 16)
                    CardStat(label: "Time Saved", value: user.timeSavedFormatted)
                }
            }
            .padding(22)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.zqBorder, lineWidth: 1))
        .shadow(color: Color.zqTeal.opacity(0.08), radius: 20, y: 6)
    }
}

private struct CardStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(.zqMuted)
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
        }
    }
}

// MARK: - Active Session Banner
struct ActiveSessionBanner: View {
    let session: ShoppingSession
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState
    @State private var elapsed = ""
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.zqTeal.opacity(0.15)).frame(width: 42, height: 42)
                Image(systemName: "storefront")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.zqTeal)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Active Session")
                    .font(.system(size: 11, weight: .semibold)).tracking(1.5)
                    .foregroundColor(.zqTeal)
                Text(session.storeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(session.elapsedDisplay + " · " + "\(appState.cartItemCount) item\(appState.cartItemCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.zqMuted)
            }
            Spacer()
            Button("Cart") { selectedTab = 2 }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.zqNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.zqTeal)
                .cornerRadius(20)
        }
        .padding(16)
        .zqCard()
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.zqTeal.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.zqTeal)
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.zqOffwhite)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .zqCard()
        }
    }
}

// MARK: - Stats Row
struct StatsRow: View {
    let user: User
    var body: some View {
        HStack(spacing: 14) {
            StatCard(value: "\(user.totalTrips)", label: "Total Trips",    icon: "bag")
            StatCard(value: user.timeSavedFormatted, label: "Time Saved", icon: "clock")
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.zqTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: 11)).foregroundColor(.zqMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .zqCard()
    }
}

// MARK: - Recent Trips Section
struct RecentTripsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Trips")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            ForEach(PastTrip.mockHistory.prefix(3)) { trip in
                TripRow(trip: trip)
            }
        }
    }
}

struct TripRow: View {
    let trip: PastTrip
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.zqBlue.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "storefront")
                    .font(.system(size: 16))
                    .foregroundColor(.zqBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.storeName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(trip.itemCount) items · \(trip.formattedDate)")
                    .font(.system(size: 12))
                    .foregroundColor(.zqMuted)
            }
            Spacer()
            Text(trip.formattedTotal)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.zqOffwhite)
        }
        .padding(14)
        .zqCard()
    }
}

// MARK: - Avatar
struct AvatarCircle: View {
    let initials: String
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            Circle().fill(Color.zqTeal.opacity(0.18)).frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(.zqTeal)
        }
    }
}
