import SwiftUI

struct NewMomentStepPlaceholderView: View {
    let draft: NewMomentDraft
    let title: String

    init(
        draft: NewMomentDraft,
        title: String = AppStrings.newMomentStepPlaceholderTitle
    ) {
        self.draft = draft
        self.title = title
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(AppTypography.heroTitle())
                    .foregroundStyle(Color.textPrimary)

                Text(
                    AppStrings.newMomentStepPlaceholderSelectedPair(
                        name: draft.selectedPairDisplayName ?? AppStrings.newMomentStepPlaceholderNoPair
                    )
                )
                .font(AppTypography.body())
                .foregroundStyle(Color.textSecondary)

                Text(
                    AppStrings.newMomentStepPlaceholderSelectedSource(
                        name: draft.selectedSourceDisplayName ?? AppStrings.newMomentStepPlaceholderNoSource
                    )
                )
                .font(AppTypography.body())
                .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 40)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NewMomentStepPlaceholderView(
        draft: NewMomentDraft(
            selectedPair: .init(
                id: "kirito-asuna",
                displayName: "Kirito ・ Asuna",
                nickname: "きりあす"
            ),
            selectedSource: .init(
                id: "aot-s3e17",
                displayName: "Attack on Titan",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 24,
                isFavorite: true
            )
        )
    )
}
