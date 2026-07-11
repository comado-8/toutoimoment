import SwiftUI

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillOpacity: Double

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: "#C4B6F0", opacity: 0.19), location: 0),
                                    .init(color: .white.opacity(0), location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(fillOpacity))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .inset(by: 0.5)
                        .stroke(Color.white, lineWidth: 1)
                }
                .shadow(color: Color(hex: "#7D70CC", opacity: 0.08), radius: 10, x: 0, y: 4)
            }
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = 16,
        fillOpacity: Double = 0.60
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, fillOpacity: fillOpacity))
    }
}
