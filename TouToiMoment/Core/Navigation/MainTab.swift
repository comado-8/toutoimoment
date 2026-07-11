import Foundation

enum MainTab: CaseIterable, Identifiable {
    case home
    case pairs
    case moments
    case sources

    var id: Self { self }

    var title: String {
        switch self {
        case .home:
            return AppStrings.tabHome
        case .pairs:
            return AppStrings.tabPairs
        case .moments:
            return AppStrings.tabMoments
        case .sources:
            return AppStrings.tabSources
        }
    }

    var iconName: String {
        switch self {
        case .home:
            return "house"
        case .pairs:
            return "person.2"
        case .moments:
            return "sparkles"
        case .sources:
            return "book.closed"
        }
    }

    var selectedIconName: String {
        switch self {
        case .home:
            return "house"
        case .pairs:
            return "person.2.fill"
        case .moments:
            return "sparkles"
        case .sources:
            return "book.closed.fill"
        }
    }
}
