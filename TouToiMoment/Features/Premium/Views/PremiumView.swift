import SwiftUI

struct PremiumView: View {
    let purchaseService: any PurchaseServicing
    let onBack: () -> Void

    @State private var activeMessage: String?
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            VStack(spacing: 0) {
                ProfileScreenHeader(title: AppStrings.premiumTitle, onBack: onBack) {
                    Button(AppStrings.premiumRestore) { Task { await restore() } }
                        .font(.custom("Geist-SemiBold", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(Color.appPrimarySoft)
                        .buttonStyle(.plain)
                        .disabled(isProcessing)
                        .accessibilityIdentifier("premium.restore")
                }

                ScrollView {
                    VStack(spacing: 24) {
                        heroCard
                        featureSection
                        purchaseSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            activeMessage ?? "",
            isPresented: Binding(
                get: { activeMessage != nil },
                set: { if !$0 { activeMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { activeMessage = nil }
        }
        .accessibilityIdentifier("premium.screen")
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.premiumUpgrade)
                    .font(.custom("Geist-SemiBold", size: 28, relativeTo: .title))
                    .foregroundStyle(.white)
                Text(AppStrings.premiumSubtitle)
                    .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimarySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionLabel(title: AppStrings.premiumFeatures)

            SettingsGlassGroup {
                premiumFeature("Background Customization", systemImage: "paintpalette", trailing: .thumbnail)
                SettingsDivider(leadingInset: 52)
                premiumFeature("Unlimited Moments", systemImage: "sparkles", trailing: .check)
                SettingsDivider(leadingInset: 52)
                premiumFeature("High-Res Covers", systemImage: "cloud", trailing: .check)
                SettingsDivider(leadingInset: 52)
                premiumFeature("Sync Across All Devices", systemImage: "iphone", trailing: .check)
                SettingsDivider(leadingInset: 52)
                premiumFeature("Remove Ads", systemImage: "xmark.circle", trailing: .comingSoon)
                SettingsDivider(leadingInset: 52)
                premiumFeature("Future Premium Features", systemImage: "gift", trailing: .comingSoon)
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await purchase() }
            } label: {
                HStack(spacing: 8) {
                    if isProcessing { ProgressView().tint(.white) }
                    Text(purchaseTitle)
                        .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimarySoft],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .accessibilityIdentifier("premium.purchase")

            Button(AppStrings.premiumRestorePurchase) { Task { await restore() } }
                .font(.custom("Geist-SemiBold", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color.appPrimarySoft)
                .buttonStyle(.plain)
                .disabled(isProcessing)

            Text("Payment will be charged to your Apple ID account. Premium is a one-time purchase and can be restored from the App Store.")
                .font(.custom("Geist-Regular", size: 11, relativeTo: .caption2))
                .foregroundStyle(Color(hex: "#9CA3AF"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var purchaseTitle: String {
        if let price = purchaseService.localizedOneTimePrice {
            return "\(AppStrings.premiumUpgradeNow) — \(price)"
        }
        return AppStrings.premiumUpgradeNow
    }

    private func premiumFeature(
        _ title: String,
        systemImage: String,
        trailing: PremiumTrailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 20)
            Text(title)
                .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
            Spacer(minLength: 4)
            switch trailing {
            case .check:
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 20, height: 20)
                    .background(Color(hex: "#E8E7FF"), in: Circle())
            case .thumbnail:
                HStack(spacing: 8) {
                    Image("HomeBackgroundOfficial")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 20, height: 20)
                        .background(Color(hex: "#E8E7FF"), in: Circle())
                }
            case .comingSoon:
                Text("COMING SOON")
                    .font(.custom("Geist-SemiBold", size: 10, relativeTo: .caption2))
                    .foregroundStyle(Color(hex: "#9CA3AF"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#F3F4F6"), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E5E7EB")))
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 52)
    }

    private func purchase() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await purchaseService.purchase()
            activeMessage = "Premium Unlocked"
        } catch {
            activeMessage = "Purchases are not available yet."
        }
    }

    private func restore() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await purchaseService.restore()
            activeMessage = "Purchases Restored"
        } catch {
            activeMessage = "Restore is not available yet."
        }
    }
}

private enum PremiumTrailing {
    case check
    case thumbnail
    case comingSoon
}
