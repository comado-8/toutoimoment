import SwiftUI

struct ProfileAvatarView: View {
    let color: AvatarColorSelection
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle().fill(color.color)
            Image(systemName: "person")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: color.color.opacity(0.28), radius: 5, x: 0, y: 4)
        .accessibilityHidden(true)
    }
}

struct ProfileScreenBackground: View {
    var body: some View {
        AppBackgroundView(theme: .home, motionEnabled: false)
            .ignoresSafeArea()
            .opacity(0.78)
    }
}

struct ProfileScreenHeader<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    let trailing: Trailing

    init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5E6088"))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel(AppStrings.profileBack)

            Spacer(minLength: 0)

            Text(title)
                .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)

            trailing
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(minHeight: 64)
    }
}

extension ProfileScreenHeader where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

struct SettingsSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.custom("Geist-SemiBold", size: 11, relativeTo: .caption2))
            .foregroundStyle(Color(hex: "#9B9EC4"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsGlassGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 20, fillOpacity: 0.48)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct SettingsDivider: View {
    var leadingInset: CGFloat = 52

    var body: some View {
        Divider()
            .overlay(Color(hex: "#D9D7E5", opacity: 0.7))
            .padding(.leading, leadingInset)
    }
}

struct SettingsActionRow: View {
    let title: String
    var systemImage: String?
    var tint: Color = .appPrimary
    var trailingText: String? = nil
    var isEnabled: Bool = true
    var showsChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isEnabled ? tint : Color.textMuted)
                        .frame(width: 24)
                }

                Text(title)
                    .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                    .foregroundStyle(isEnabled ? Color.textPrimary : Color.textMuted)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                if let trailingText {
                    Text(trailingText)
                        .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    var isEnabled: Bool = true
    var showsPremiumBadge: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isEnabled ? Color.appPrimary : Color.textMuted)
                    .frame(width: 24)

                Text(title)
                    .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                    .foregroundStyle(isEnabled ? Color.textPrimary : Color.textMuted)

                if showsPremiumBadge {
                    SettingsPremiumBadge()
                }
            }
        }
        .tint(Color.appPrimary)
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .disabled(!isEnabled)
    }
}

struct SettingsPremiumBadge: View {
    var body: some View {
        Text(AppStrings.premiumTitle)
            .font(.custom("Geist-SemiBold", size: 10, relativeTo: .caption2))
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.appPrimary.opacity(0.1), in: Capsule())
            .accessibilityLabel(AppStrings.premiumTitle)
    }
}

enum AppVersionInfo {
    static var versionAndBuild: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (version, build) {
        case let (.some(version), .some(build)):
            return "\(version) (\(build))"
        case let (.some(version), .none):
            return version
        default:
            return "—"
        }
    }

    static var copyrightYear: String {
        String(Calendar.current.component(.year, from: .now))
    }
}
