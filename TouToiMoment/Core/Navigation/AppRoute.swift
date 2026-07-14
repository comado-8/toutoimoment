import Foundation

enum AppRoute: Hashable {
    case pairDetail(String)
    case newMomentStep1
    case newMomentStep2(NewMomentDraft)
    case newMomentStep3(NewMomentDraft)
    case newMomentStep4(NewMomentDraft)
}

extension AppRoute {
    var hidesBottomTabBar: Bool {
        switch self {
        case .newMomentStep1, .newMomentStep2, .newMomentStep3, .newMomentStep4:
            return true
        case .pairDetail:
            return false
        }
    }
}
