import SwiftUI

struct HomeView: View {
    @ObservedObject private var momentStore: MomentStore
    @ObservedObject private var profileStore: ProfileStore
    var onOpenProfile: () -> Void = {}
    var onCreateMoment: () -> Void = {}
    var onOpenMoment: (String) -> Void = { _ in }

    init(
        momentStore: MomentStore,
        profileStore: ProfileStore,
        onOpenProfile: @escaping () -> Void = {},
        onCreateMoment: @escaping () -> Void = {},
        onOpenMoment: @escaping (String) -> Void = { _ in }
    ) {
        self.momentStore = momentStore
        self.profileStore = profileStore
        self.onOpenProfile = onOpenProfile
        self.onCreateMoment = onCreateMoment
        self.onOpenMoment = onOpenMoment
    }

    var body: some View {
        GeometryReader { geometry in
            let profile = HomeLayoutProfile(size: geometry.size)

            fixedHeightContent(profile: profile)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .accessibilityIdentifier("home.screen")
    }

    private var topNavigation: some View {
        HStack {
            Button(action: onOpenProfile) {
                ProfileAvatarView(color: profileStore.profile.avatarColor, size: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.profileTitle)
            .accessibilityIdentifier("home.profile")

            Spacer()
        }
        .frame(height: 48)
    }

    private func greetingBlock(profile: HomeLayoutProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppStrings.homeGreetingTitle(name: profileStore.profile.nickname))
                .font(AppTypography.heroTitle())
                .foregroundStyle(Color.textPrimary)

            Text(AppStrings.homeGreetingSubtitle)
                .font(AppTypography.body())
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.top, 4)
        .padding(.bottom, profile.greetingBottom)
    }

    private func momentsSection(profile: HomeLayoutProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                FavoriteStarIcon()

                Text(AppStrings.homeFavMomentsTitle)
                    .font(AppTypography.titleMedium())
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.screen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(momentStore.favoriteMoments.prefix(3)) { moment in
                        MomentCard(
                            model: moment,
                            layout: .homeRail,
                            onOpen: { onOpenMoment(moment.id) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
        .padding(.top, profile.sectionTop)
    }

    private func fixedHeightContent(profile: HomeLayoutProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            topNavigation
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, profile.topPadding)

            greetingBlock(profile: profile)
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, profile.greetingTop)

            RecordRippleButton(
                momentCount: HomePreviewData.registeredMomentCount,
                onSequenceCompleted: onCreateMoment
            )
                .frame(maxWidth: .infinity)
                .padding(.top, profile.recordTop)

            Text(AppStrings.homeRecordMomentHint)
                .font(AppTypography.momentQuoteJapanese())
                .kerning(0.4)
                .foregroundStyle(Color(hex: "#7F7BE0", opacity: 0.84))
                .frame(maxWidth: .infinity)
                .padding(.top, profile.hintTop)

            Spacer(minLength: profile.flexSpacerMin)

            momentsSection(profile: profile)

            Spacer(minLength: profile.bottomClearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

}

private struct HomeLayoutProfile {
    let topPadding: CGFloat
    let greetingTop: CGFloat
    let greetingBottom: CGFloat
    let recordTop: CGFloat
    let hintTop: CGFloat
    let sectionTop: CGFloat
    let flexSpacerMin: CGFloat
    let bottomClearance: CGFloat

    init(size: CGSize) {
        if size.height < 760 {
            topPadding = 4
            greetingTop = 6
            greetingBottom = 10
            recordTop = 0
            hintTop = 8
            sectionTop = 12
            flexSpacerMin = 14
            bottomClearance = 122
        } else {
            topPadding = 8
            greetingTop = 8
            greetingBottom = 16
            recordTop = 2
            hintTop = 8
            sectionTop = 18
            flexSpacerMin = 24
            bottomClearance = 132
        }
    }
}

#Preview {
    let dataStore = AppDataStore(isStoredInMemoryOnly: true)

    ZStack(alignment: .bottom) {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        HomeView(
            momentStore: dataStore.momentStore,
            profileStore: dataStore.profileStore
        )

        BottomTabBar(selectedTab: .constant(.home))
            .padding(.bottom, 8)
    }
}
