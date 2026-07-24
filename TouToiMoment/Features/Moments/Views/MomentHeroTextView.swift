import SwiftUI

struct MomentHeroTextView: View {
    let text: String
    let usesHeartTypography: Bool

    @State private var isExpanded = false
    @State private var fullTextHeight: CGFloat = 0
    @State private var collapsedTextHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 5) {
            styledText
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            if isOverflowing {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(
                        isExpanded
                            ? AppStrings.momentDetailCollapseScene
                            : AppStrings.momentDetailExpandScene
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("moment.detail.scene-expansion")
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                measurementText
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: MomentHeroFullTextHeightKey.self,
                                value: proxy.size.height
                            )
                        }
                    }

                measurementText
                    .lineLimit(3)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: MomentHeroCollapsedTextHeightKey.self,
                                value: proxy.size.height
                            )
                        }
                    }
            }
            .hidden()
            .accessibilityHidden(true)
        }
        .onPreferenceChange(MomentHeroFullTextHeightKey.self) {
            fullTextHeight = $0
        }
        .onPreferenceChange(MomentHeroCollapsedTextHeightKey.self) {
            collapsedTextHeight = $0
        }
        .onChange(of: text) { _, _ in
            isExpanded = false
        }
    }

    private var isOverflowing: Bool {
        fullTextHeight > collapsedTextHeight + 1
    }

    private var styledText: some View {
        Text(text)
            .font(heroFont)
            .foregroundStyle(heroColor)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .shadow(color: Color.sceneDisplay.opacity(0.20), radius: 8, y: 2)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("moment.detail.hero.scene")
    }

    private var measurementText: some View {
        Text(text)
            .font(heroFont)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var heroFont: Font {
        usesHeartTypography
            ? .custom("ZenKakuGothicNew-Medium", size: 22, relativeTo: .title2)
            : .custom("ZenAntique-Regular", size: 24, relativeTo: .title2)
    }

    private var heroColor: Color {
        usesHeartTypography ? Color.sceneHeart : Color.sceneDisplay
    }
}

private struct MomentHeroFullTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct MomentHeroCollapsedTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
