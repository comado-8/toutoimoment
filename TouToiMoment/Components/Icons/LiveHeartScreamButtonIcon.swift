import SwiftUI

/// Figma `651:938` artwork. The exported SVG includes the button's outer shadow.
struct LiveHeartScreamButtonIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width, proxy.size.height) / 98

            Image("LiveHeartScreamButton")
                .resizable()
                .frame(width: 138 * scale, height: 138 * scale)
                .offset(x: -20 * scale, y: -16 * scale)
        }
        .accessibilityHidden(true)
    }
}
