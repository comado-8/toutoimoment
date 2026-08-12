import SwiftUI

struct ProfileDrawerView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @ObservedObject var profileStore: ProfileStore
    let onDismiss: () -> Void
    let onEditProfile: () -> Void
    let onOpenPremium: () -> Void
    let onOpenSettings: () -> Void
    let onOpenHelp: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let drawerWidth = min(320, max(280, proxy.size.width - 70))

            HStack(spacing: 0) {
                drawerContent
                    .frame(width: drawerWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(.ultraThinMaterial)
                    .background(Color.white.opacity(0.44))
                    .shadow(color: Color(hex: "#7C6FCD", opacity: 0.08), radius: 20, x: 4)

                Button(action: onDismiss) {
                    Color.black.opacity(0.2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close profile menu")
            }
            .offset(x: min(0, dragOffset))
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        dragOffset = min(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width < -drawerWidth * 0.28 {
                            onDismiss()
                        }
                        withAnimation(
                            accessibilityReduceMotion
                                ? .none
                                : .spring(duration: 0.32, bounce: 0.12)
                        ) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .accessibilityIdentifier("profile.drawer")
    }

    private var drawerContent: some View {
        ZStack(alignment: .topLeading) {
            ProfileScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    profileSection
                    menuSection

                    Text("Version \(AppVersionInfo.versionAndBuild)")
                        .font(.custom("Geist-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(hex: "#9CA3AF"))
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 64)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileAvatarView(color: profileStore.profile.avatarColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(profileStore.profile.nickname)
                    .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                    .foregroundStyle(Color(hex: "#111827"))

                Button(action: onEditProfile) {
                    HStack(spacing: 4) {
                        Text(AppStrings.profileEdit)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.custom("Geist-Medium", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.drawer.edit")
            }
        }
        .padding(.horizontal, 24)
    }

    private var menuSection: some View {
        VStack(spacing: 4) {
            Button(action: onOpenPremium) {
                drawerRow(
                    title: AppStrings.profileUpgrade,
                    systemImage: "star",
                    foreground: .white,
                    iconColor: .white
                )
                .background(
                    LinearGradient(
                        colors: [Color.appPrimary, Color(hex: "#8B70F0"), Color.appAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .accessibilityIdentifier("profile.drawer.premium")

            Button(action: onOpenSettings) {
                drawerRow(title: AppStrings.profileSettings, systemImage: "gearshape", foreground: Color(hex: "#1F2937"), iconColor: .appPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.drawer.settings")

            Button(action: onOpenHelp) {
                drawerRow(title: AppStrings.profileHelp, systemImage: "questionmark.circle", foreground: Color(hex: "#1F2937"), iconColor: .appPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.drawer.help")
        }
    }

    private func drawerRow(
        title: String,
        systemImage: String,
        foreground: Color,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Text(title)
                .font(.custom("Geist-Medium", size: 16, relativeTo: .body))
                .foregroundStyle(foreground)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foreground.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}
