import SwiftUI

struct FavoriteStarIcon: View {
    enum Variant {
        case `default`
        case on
    }

    var variant: Variant = .default
    var width: CGFloat = 20
    var height: CGFloat = 21

    var body: some View {
        ZStack {
            Image("FavoriteStarOn")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .opacity(variant == .on ? 1 : 0.18)

            Image(variant == .on ? "FavoriteStarOn" : "FavoriteStar")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}
