import SwiftUI

struct MomentSparkleIcon: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat

    init(
        color: Color,
        width: CGFloat = 16,
        height: CGFloat = 23
    ) {
        self.color = color
        self.width = width
        self.height = height
    }

    var body: some View {
        Image("MomentSparkle")
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 20) {
        MomentSparkleIcon(color: .appPrimary)
        MomentSparkleIcon(color: .white, width: 13, height: 21)
    }
    .padding()
    .background(Color.black.opacity(0.1))
}
