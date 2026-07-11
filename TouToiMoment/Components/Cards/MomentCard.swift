import SwiftUI

struct MomentCard: View {
    enum Layout {
        case homeRail
    }

    let model: MomentCardModel
    let layout: Layout

    var body: some View {
        switch layout {
        case .homeRail:
            homeRailCard
        }
    }

    private var homeRailCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.4))

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#C4B5F0", opacity: 0.19), location: 0),
                            .init(color: .white.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: model.glowColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 131, height: 130)
                .blur(radius: 12.3)

            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    PairColorDot(color: model.leadingDotColor)

                    PairColorDot(color: model.trailingDotColor)
                }
                .padding(.top, 15)

                Spacer(minLength: 0)

                Text(model.sceneText)
                    .font(AppTypography.momentCardScene())
                    .tracking(0.7)
                    .foregroundStyle(Color.sceneDisplay)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 8) {
                    Text(model.caption)
                        .font(AppTypography.momentCardCaption())
                        .foregroundStyle(Color.appPrimary.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    Text(model.episodeLabel)
                        .font(AppTypography.momentCardEpisode())
                        .foregroundStyle(Color.appPrimary.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            VStack {
                HStack {
                    Spacer()

                    FavoriteMomentBadge(isActive: model.isFavorite)
                }
                .padding(.top, 11)
                .padding(.trailing, 10)

                Spacer()
            }
        }
        .frame(width: 175, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.white.opacity(0.67), lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7C6FCD", opacity: 0.08), radius: 20, x: 0, y: 4)
    }
}

private struct PairColorDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .inset(by: 0.5)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: Color.white.opacity(0.16), radius: 1.5, x: 0, y: 0)
    }
}

private struct FavoriteMomentBadge: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Image("FavoriteStarOn")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .opacity(isActive ? 1 : 0.18)

            Image(isActive ? "FavoriteStarOn" : "FavoriteStar")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: 20, height: 20)
    }
}

#Preview {
    ZStack {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        MomentCard(
            model: .preview[1],
            layout: .homeRail
        )
    }
}
