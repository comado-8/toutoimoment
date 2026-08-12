import Foundation

enum SourceListFilter: String, CaseIterable, Identifiable {
    case all
    case anime
    case manga
    case drama
    case novel
    case streaming

    var id: Self { self }

    var title: String {
        switch self {
        case .all: return AppStrings.sourcesFilterAll
        case .anime: return AppStrings.sourcesFilterAnime
        case .manga: return AppStrings.sourcesFilterManga
        case .drama: return AppStrings.sourcesFilterDrama
        case .novel: return AppStrings.sourcesFilterNovel
        case .streaming: return AppStrings.sourcesFilterStreaming
        }
    }

    func matches(mediaType: String) -> Bool {
        switch self {
        case .all:
            return true
        case .anime:
            return mediaType == "anime"
        case .manga:
            return mediaType == "manga"
        case .drama:
            return mediaType == "tv_drama"
        case .novel:
            return mediaType == "novel"
        case .streaming:
            return mediaType == "streaming"
        }
    }
}

enum SourceLoadState: Equatable {
    case idle
    case loading
    case loaded
    case missing
    case failed
}

enum SourceUnavailableFeature: String, Identifiable {
    case episodeDetail
    case addEpisode
    case addMoment
    case moreMenu

    var id: Self { self }

    var title: String {
        switch self {
        case .episodeDetail: return AppStrings.sourceDetailEpisodeUnavailableTitle
        case .addEpisode: return AppStrings.sourceDetailAddEpisode
        case .addMoment: return AppStrings.sourceDetailAddMoment
        case .moreMenu: return AppStrings.sourceDetailMore
        }
    }
}

struct SourceRelativeDateFormatter {
    private let formatter: RelativeDateTimeFormatter

    init(locale: Locale = Locale(identifier: "en_US")) {
        formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
    }

    func string(for date: Date, relativeTo referenceDate: Date = .now) -> String {
        formatter.localizedString(for: date, relativeTo: referenceDate)
    }
}
