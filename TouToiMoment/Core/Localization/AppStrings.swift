import Foundation

enum AppStrings {
    static func pairsFavoriteToggleLabel(name: String) -> String {
        String(
            format: String(
                localized: "pairs.favorite_toggle.label_format",
                defaultValue: "%@ のお気に入り状態を切り替える",
                comment: "Accessibility label for the pair favorite toggle button."
            ),
            locale: .current,
            name
        )
    }

    static func homeGreetingTitle(name: String) -> String {
        String(
            format: String(
                localized: "home.greeting.title_format",
                defaultValue: "Hi, %@.",
                comment: "Home greeting title format with the user's display name."
            ),
            locale: .current,
            name
        )
    }

    static let homeGreetingSubtitle = String(
        localized: "home.greeting.subtitle",
        defaultValue: "今日も尊い瞬間を残そう。",
        comment: "Home greeting subtitle under the main title."
    )

    static let homeRecordMomentHint = String(
        localized: "home.record_moment.hint",
        defaultValue: "タップして新しい瞬間を残す＋",
        comment: "Hint below the central home record button."
    )

    static let homeNewMomentCTA = String(
        localized: "home.cta.new_moment",
        defaultValue: "New Toutoi Moment",
        comment: "Primary call-to-action on the home screen."
    )

    static let homeFavMomentsTitle = String(
        localized: "home.section.fav_moments",
        defaultValue: "Fav Moments",
        comment: "Section title for favorite moments on the home screen."
    )

    static let homeTopPairsTitle = String(
        localized: "home.section.top_pairs",
        defaultValue: "Your Top Pairs",
        comment: "Section title for top pairs on the home screen."
    )

    static let pairsNewPair = String(
        localized: "pairs.cta.new_pair",
        defaultValue: "New Pair",
        comment: "Call-to-action card label on the pairs screen."
    )

    static let pairsFilterAll = String(
        localized: "pairs.filter.all",
        defaultValue: "All",
        comment: "Filter chip for showing all pairs."
    )

    static let pairsFilterFavorite = String(
        localized: "pairs.filter.favorite",
        defaultValue: "Favorite",
        comment: "Filter chip for showing favorite pairs."
    )

    static let pairDetailTitle = String(
        localized: "pair_detail.title",
        defaultValue: "Pair",
        comment: "Navigation title for the pair detail screen."
    )

    static let pairDetailRecentMomentsTitle = String(
        localized: "pair_detail.section.recent_moments",
        defaultValue: "Recent Moments",
        comment: "Section title for recent moments on the pair detail screen."
    )

    static let pairDetailNewMomentButton = String(
        localized: "pair_detail.cta.new_moment",
        defaultValue: "New Moment",
        comment: "Button label for adding a new moment from pair detail."
    )

    static let pairDetailStatMoments = String(
        localized: "pair_detail.stat.moments",
        defaultValue: "Moments",
        comment: "Stat label for the total moments count."
    )

    static let pairDetailStatLast = String(
        localized: "pair_detail.stat.last",
        defaultValue: "Last",
        comment: "Stat label for the most recent entry placeholder."
    )

    static let pairDetailStatSince = String(
        localized: "pair_detail.stat.since",
        defaultValue: "Since",
        comment: "Stat label for the since placeholder."
    )

    static let pairDetailBackButton = String(
        localized: "pair_detail.back_button",
        defaultValue: "戻る",
        comment: "Accessibility label for returning from pair detail."
    )

    static let pairDetailEditButton = String(
        localized: "pair_detail.edit_button",
        defaultValue: "編集",
        comment: "Accessibility label for the pair detail edit button."
    )

    static let tabHome = String(
        localized: "tab.home",
        defaultValue: "Home",
        comment: "Bottom tab title for the home screen."
    )

    static let tabPairs = String(
        localized: "tab.pairs",
        defaultValue: "Pairs",
        comment: "Bottom tab title for the pairs screen."
    )

    static let tabMoments = String(
        localized: "tab.moments",
        defaultValue: "Moments",
        comment: "Bottom tab title for the moments screen."
    )

    static let tabSources = String(
        localized: "tab.sources",
        defaultValue: "Sources",
        comment: "Bottom tab title for the sources screen."
    )
}
