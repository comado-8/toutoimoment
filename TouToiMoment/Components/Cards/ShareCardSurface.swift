import SwiftUI

struct ShareCardSurface: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.40))

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#C4B5F0", opacity: 0.19),
                                    Color.white.opacity(0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(
                        cornerRadius: max(0, cornerRadius - 8),
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FBD3ED", opacity: 0.25),
                                Color(hex: "#B2B8FD", opacity: 0.25),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 12)
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white, lineWidth: 1)
            }
            .shadow(
                color: Color(hex: "#7C6FCD", opacity: 0.12),
                radius: 32,
                y: 12
            )
    }
}

extension View {
    func shareCardSurface(cornerRadius: CGFloat) -> some View {
        modifier(ShareCardSurface(cornerRadius: cornerRadius))
    }
}
