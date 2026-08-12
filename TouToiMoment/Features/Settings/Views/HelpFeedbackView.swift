import StoreKit
import SwiftUI

struct HelpFeedbackView: View {
    let supportLinks: SupportLinks
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var showsMissingLink = false

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            VStack(spacing: 0) {
                ProfileScreenHeader(title: AppStrings.profileHelp, onBack: onBack)

                ScrollView {
                    VStack(spacing: 24) {
                        helpSection(AppStrings.helpSupport) {
                            helpRow(AppStrings.helpFAQ, systemImage: "questionmark.circle") { open(supportLinks.faq) }
                            SettingsDivider(leadingInset: 60)
                            helpRow(AppStrings.helpContact, systemImage: "envelope") { open(supportLinks.contact) }
                        }

                        helpSection(AppStrings.helpCommunity) {
                            helpRow(AppStrings.helpFeatureRequest, systemImage: "lightbulb") { open(supportLinks.featureRequest) }
                            SettingsDivider(leadingInset: 60)
                            helpRow(AppStrings.helpReportBug, systemImage: "ladybug") { open(supportLinks.reportBug) }
                        }

                        helpSection("Store") {
                            helpRow(AppStrings.helpRate, systemImage: "star", tint: Color(hex: "#F59E0B")) {
                                requestReview()
                            }
                        }

                        VStack(spacing: 4) {
                            Text("TouToi Moment v\(AppVersionInfo.versionAndBuild)")
                            Text("Made with love by the TouToi Team").opacity(0.6)
                        }
                        .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(hex: "#9CA3AF"))
                        .padding(.top, 38)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Link Not Configured", isPresented: $showsMissingLink) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Add the support URL or email address to enable this action.")
        }
        .accessibilityIdentifier("help_feedback.screen")
    }

    private func helpSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
                .foregroundStyle(Color.textSecondary.opacity(0.7))
                .padding(.leading, 20)
            SettingsGlassGroup { content() }
        }
    }

    private func helpRow(
        _ title: String,
        systemImage: String,
        tint: Color = .appPrimary,
        action: @escaping () -> Void
    ) -> some View {
        SettingsActionRow(
            title: title,
            systemImage: systemImage,
            tint: tint,
            action: action
        )
    }

    private func open(_ url: URL?) {
        guard let url else {
            showsMissingLink = true
            return
        }
        openURL(url)
    }
}
