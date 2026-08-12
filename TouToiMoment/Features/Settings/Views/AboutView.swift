import SwiftUI

struct AboutView: View {
    let supportLinks: SupportLinks
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showsMissingLink = false

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            VStack(spacing: 0) {
                ProfileScreenHeader(title: AppStrings.settingsAbout, onBack: onBack)

                ScrollView {
                    VStack(spacing: 0) {
                        appIdentity
                            .padding(.top, 40)
                            .padding(.bottom, 40)

                        SettingsGlassGroup {
                            aboutRow(AppStrings.settingsPrivacy, detail: "Opens in Safari", external: true) { open(supportLinks.privacyPolicy) }
                            SettingsDivider(leadingInset: 20)
                            aboutRow(AppStrings.settingsTerms, detail: "Opens in Safari", external: true) { open(supportLinks.termsOfService) }
                            SettingsDivider(leadingInset: 20)
                            aboutRow(AppStrings.settingsLicenses, detail: "coming soon", external: false) { showsMissingLink = true }
                            SettingsDivider(leadingInset: 20)
                            aboutRow(AppStrings.settingsWebsite, detail: supportLinks.officialWebsite == nil ? "coming soon" : "Opens in Safari", external: true) { open(supportLinks.officialWebsite) }
                        }

                        Spacer(minLength: 220)

                        Text("© \(AppVersionInfo.copyrightYear) TouToi Moment")
                            .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                            .foregroundStyle(Color(hex: "#78716C"))
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Link Not Configured", isPresented: $showsMissingLink) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Add the destination URL to enable this action.")
        }
        .accessibilityIdentifier("about.screen")
    }

    private var appIdentity: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color(hex: "#8B70F0"), Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay {
                    MomentSparkleIcon(color: .white, width: 20, height: 31)
                }
                .shadow(color: Color.appPrimary.opacity(0.25), radius: 8, y: 8)

            VStack(spacing: 4) {
                Text("TouToi Moment")
                    .font(.custom("Geist-SemiBold", size: 24, relativeTo: .title2))
                    .foregroundStyle(Color.textPrimary)
                Text("Version \(AppVersionInfo.versionAndBuild)")
                    .font(.custom("Geist-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color(hex: "#78716C"))
            }
        }
    }

    private func aboutRow(
        _ title: String,
        detail: String,
        external: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom("Geist-Medium", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.textPrimary)
                if external {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "#78716C"))
                }
                Spacer(minLength: 8)
                Text(detail)
                    .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(hex: "#78716C"))
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "#A8A29E"))
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func open(_ url: URL?) {
        guard let url else {
            showsMissingLink = true
            return
        }
        openURL(url)
    }
}
