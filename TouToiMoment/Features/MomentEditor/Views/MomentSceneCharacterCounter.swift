import SwiftUI
import UIKit

struct MomentSceneCharacterCounter: View {
    let text: String

    @State private var didAnnounceLimit = false

    var body: some View {
        if MomentSceneTextPolicy.shouldShowCounter(for: text) {
            Text(MomentSceneTextPolicy.counterText(for: text))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(counterColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(
                    AppStrings.sceneCharacterCount(
                        current: text.count,
                        maximum: MomentSceneTextPolicy.maximumLength
                    )
                )
                .accessibilityIdentifier("moment.scene.character-count")
                .onAppear(perform: announceLimitIfNeeded)
                .onChange(of: text.count) { _, _ in
                    announceLimitIfNeeded()
                }
        }
    }

    private var counterColor: Color {
        if text.count >= MomentSceneTextPolicy.maximumLength {
            return .red
        }
        if text.count >= MomentSceneTextPolicy.warningThreshold {
            return .orange
        }
        return Color.textSecondary
    }

    private func announceLimitIfNeeded() {
        let isAtLimit = text.count >= MomentSceneTextPolicy.maximumLength
        guard isAtLimit, !didAnnounceLimit else {
            if !isAtLimit {
                didAnnounceLimit = false
            }
            return
        }
        didAnnounceLimit = true
        UIAccessibility.post(
            notification: .announcement,
            argument: AppStrings.sceneCharacterLimitReached
        )
    }
}
