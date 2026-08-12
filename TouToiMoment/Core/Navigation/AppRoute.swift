import Foundation

enum EpisodeDetailSection: Hashable {
    case moments
    case watchHistory
}

enum AppRoute: Hashable {
    case pairDetail(String)
    case sourceDetail(String)
    case episodeDetail(
        sourceID: String,
        episodeID: String,
        initialSection: EpisodeDetailSection = .moments
    )
    case watchHistoryDetail(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        showsSavedConfirmation: Bool = false
    )
    case watchingSetup(sourceID: String, episodeID: String)
    case watchingMode(WatchingModeSelection)
    case momentDetail(String)
    case momentEdit(String)
    case newMoment(pairID: String? = nil, sourceID: String?, episodeID: String?)
    case editProfile
    case settings
    case about
    case helpFeedback
    case premium
}

extension AppRoute {
    var hidesBottomTabBar: Bool {
        switch self {
        case .momentEdit, .newMoment, .watchingSetup, .watchingMode,
             .editProfile, .about, .helpFeedback, .premium:
            return true
        case .pairDetail, .sourceDetail, .episodeDetail, .watchHistoryDetail, .momentDetail,
             .settings:
            return false
        }
    }
}
