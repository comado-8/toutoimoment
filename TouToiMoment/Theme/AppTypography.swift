import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppTypography {
    static func heroTitle() -> Font {
        customFont(
            names: ["InstrumentSerif-Regular"],
            size: 35,
            relativeTo: .largeTitle,
            fallback: .system(size: 35, weight: .regular, design: .serif)
        )
    }

    static func titleMedium() -> Font {
        customFont(
            names: ["Geist-SemiBold", "Geist-Regular"],
            size: 18,
            relativeTo: .headline,
            fallback: .system(size: 18, weight: .semibold)
        )
    }

    static func titleSmall() -> Font {
        customFont(
            names: ["Geist-Medium", "Geist-Regular"],
            size: 14,
            relativeTo: .subheadline,
            fallback: .system(size: 14, weight: .medium)
        )
    }

    static func body() -> Font {
        customFont(
            names: ["NotoSansJP-Thin_Regular"],
            size: 16,
            relativeTo: .body,
            fallback: .system(size: 16, weight: .regular)
        )
    }

    static func bodyStrong() -> Font {
        customFont(
            names: ["NotoSansJP-Thin_Medium", "NotoSansJP-Thin_Regular"],
            size: 16,
            relativeTo: .body,
            fallback: .system(size: 16, weight: .medium)
        )
    }

    static func meta() -> Font {
        customFont(
            names: ["Geist-Regular"],
            size: 12,
            relativeTo: .caption,
            fallback: .system(size: 12, weight: .medium)
        )
    }

    static func cta() -> Font {
        customFont(
            names: ["Geist-SemiBold", "Geist-Regular"],
            size: 16,
            relativeTo: .headline,
            fallback: .system(size: 16, weight: .semibold)
        )
    }

    static func sceneDisplay() -> Font {
        customFont(
            names: ["ZenAntique-Regular", "EBGaramond-SemiBold", "EBGaramond-Regular"],
            size: 17,
            relativeTo: .body,
            fallback: .system(size: 17, weight: .semibold, design: .serif)
        )
    }

    static func momentQuoteJapanese() -> Font {
        customFont(
            names: ["NotoSansJP-Thin_Medium", "NotoSansJP-Thin_Regular"],
            size: 14,
            relativeTo: .body,
            fallback: .system(size: 14, weight: .medium)
        )
    }

    static func jpAccent() -> Font {
        customFont(
            names: ["ZenKakuGothicNew-Medium", "ZenKakuGothicNew-Regular"],
            size: 16,
            relativeTo: .body,
            fallback: .system(size: 16, weight: .medium)
        )
    }

    static func momentCardScene() -> Font {
        customFont(
            names: ["ZenAntique-Regular", "EBGaramond-Regular"],
            size: 14,
            relativeTo: .body,
            fallback: .system(size: 14, weight: .regular, design: .serif)
        )
    }

    static func momentCardCaption() -> Font {
        customFont(
            names: ["ZenKakuGothicNew-Medium", "ZenKakuGothicNew-Regular"],
            size: 8,
            relativeTo: .caption2,
            fallback: .system(size: 8, weight: .medium)
        )
    }

    static func momentCardEpisode() -> Font {
        customFont(
            names: ["Geist-SemiBold", "Geist-Regular"],
            size: 10,
            relativeTo: .caption,
            fallback: .system(size: 10, weight: .semibold)
        )
    }

    private static func customFont(
        names: [String],
        size: CGFloat,
        relativeTo: Font.TextStyle,
        fallback: Font
    ) -> Font {
        #if canImport(UIKit)
        for name in names where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: relativeTo)
        }
        #endif
        return fallback
    }
}
