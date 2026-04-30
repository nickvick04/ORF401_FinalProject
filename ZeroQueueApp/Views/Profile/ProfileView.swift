import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignOutAlert = false
    @State private var showAddProfile   = false

    var user: User { appState.currentUser ?? User(firstName: "Member", lastName: "", email: "") }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zqNavy.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Avatar + name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.zqTeal.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Text(user.initials)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.zqTeal)
                            }
                            VStack(spacing: 4) {
                                Text(user.fullName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(user.email)
                                    .font(.system(size: 13))
                                    .foregroundColor(.zqMuted)
                            }
                            MemberBadge()
                        }
                        .padding(.top, 8)

                        // Stats
                        HStack(spacing: 12) {
                            ProfileStat(value: "\(user.totalTrips)", label: "Trips")
                            ProfileStat(value: user.timeSavedFormatted, label: "Saved")
                            ProfileStat(value: "Since \(memberYear)", label: "Member")
                        }

                        // Payment method
                        ProfileSection(title: "Payment Method") {
                            if let pm = user.paymentMethod {
                                ProfileRow(icon: "creditcard", title: pm.displayName, subtitle: "Expires \(pm.expiryDisplay)")
                            } else {
                                ProfileRow(icon: "plus", title: "Add Payment Method", subtitle: "Required for checkout", accentTitle: true)
                            }
                        }

                        // Household profiles
                        ProfileSection(title: "Household Profiles") {
                            if user.profiles.isEmpty {
                                ProfileRow(icon: "person.badge.plus", title: "Add a profile", subtitle: "Family members can share your membership", accentTitle: true) {
                                    showAddProfile = true
                                }
                            } else {
                                ForEach(user.profiles) { profile in
                                    ProfileRow(icon: "person.fill", title: profile.name, subtitle: profile.relationship)
                                }
                            }
                        }

                        // Purchase history
                        ProfileSection(title: "Purchase History") {
                            ForEach(PastTrip.mockHistory) { trip in
                                TripRow(trip: trip)
                                    .environmentObject(appState)
                            }
                        }

                        // Account settings
                        ProfileSection(title: "Account") {
                            ProfileRow(icon: "bell", title: "Notifications", subtitle: "Manage alerts")
                            ProfileRow(icon: "lock.shield", title: "Privacy", subtitle: "Data & permissions")
                            ProfileRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "zeroqueue.io/support")
                        }

                        // Sign out
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.zqCard)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zqBorder))
                        }

                        Text("ZeroQueue v1.0 Beta")
                            .font(.system(size: 11))
                            .foregroundColor(.zqMuted.opacity(0.5))
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.zqMid, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { appState.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    var memberYear: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        return fmt.string(from: user.memberSince)
    }
}

// MARK: - Member Badge
private struct MemberBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.zqTeal).frame(width: 6, height: 6)
            Text("Active Member")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(.zqTeal)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.zqTeal.opacity(0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.zqTeal.opacity(0.3)))
    }
}

// MARK: - Profile Stat
private struct ProfileStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.zqMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .zqCard()
    }
}

// MARK: - Profile Section + Row
struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.zqMuted)
                .padding(.leading, 4)
            VStack(spacing: 1) {
                content()
            }
            .background(Color.zqCard)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.zqBorder))
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var accentTitle: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.zqMuted)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(accentTitle ? .zqTeal : .white)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(.zqMuted)
                    }
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.zqMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .disabled(action == nil)
    }
}
