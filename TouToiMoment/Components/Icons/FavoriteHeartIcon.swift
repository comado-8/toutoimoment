import SwiftUI

struct FavoriteHeartIcon: View {
    let isFilled: Bool
    var size: CGFloat = 20

    var body: some View {
        Image(isFilled ? "PairHeartOn" : "PairHeart")
            .resizable()
            .interpolation(.high)
            .renderingMode(.original)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: .white.opacity(0.4), radius: 0.25, x: 0, y: 0)
    }
}

#Preview {
    HStack(spacing: 16) {
        FavoriteHeartIcon(isFilled: false)
        FavoriteHeartIcon(isFilled: true)
    }
    .padding()
    .background(Color.surfaceWhite)
}
