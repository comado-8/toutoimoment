import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
protocol MomentStorePersistence {
    func load() -> [MomentCardModel]?
    func save(_ moments: [MomentCardModel]) throws
}

struct PersistedMomentSnapshot: Codable {
    struct ContextValue: Codable {
        let key: String
        let value: String
    }

    let id: String
    let title: String?
    let sceneNote: String
    let heartText: String
    let caption: String
    let pairID: String?
    let pairName: String
    let pairMemberNames: [String]?
    let sourceID: String?
    let sourceName: String
    let mediaType: String?
    let episodeID: String?
    let episodeLocatorValues: [LocatorValue]
    let contextValues: [ContextValue]
    let reactionIDs: [String]
    let reactionLabels: [String]
    var images: [MomentImage]
    let leadingColorHex: String
    let trailingColorHex: String
    var momentDate: MomentDate?
    let createdAt: Date
    let isFavorite: Bool

    init(moment: MomentCardModel) {
        id = moment.id
        title = moment.title
        sceneNote = moment.sceneNote
        heartText = moment.heartText
        caption = moment.caption
        pairID = moment.pairID
        pairName = moment.pairName
        pairMemberNames = moment.pairMemberNames
        sourceID = moment.sourceID
        sourceName = moment.sourceName
        mediaType = moment.mediaType
        episodeID = moment.episodeID
        episodeLocatorValues = moment.episodeLocatorValues
        contextValues = moment.contextValues.map {
            ContextValue(key: $0.key, value: $0.value)
        }
        reactionIDs = moment.reactionIDs
        reactionLabels = moment.reactionLabels
        images = moment.images
        leadingColorHex = Self.hex(moment.leadingDotColor)
        trailingColorHex = Self.hex(moment.trailingDotColor)
        momentDate = moment.momentDate
        createdAt = moment.createdAt
        isFavorite = moment.isFavorite
    }

    var moment: MomentCardModel {
        MomentCardModel(
            id: id,
            title: MomentTitlePolicy.normalized(title),
            sceneText: sceneNote,
            heartText: heartText,
            caption: caption,
            pairID: pairID,
            pairName: pairName,
            pairMemberNames: pairMemberNames ?? [],
            sourceID: sourceID,
            sourceName: sourceName,
            mediaType: mediaType,
            episodeID: episodeID,
            episodeLocatorValues: episodeLocatorValues,
            contextValues: contextValues.map {
                MomentCardModel.ContextValue(key: $0.key, value: $0.value)
            },
            reactionIDs: reactionIDs,
            reactionLabels: reactionLabels,
            images: images,
            leadingDotColor: Color(hex: leadingColorHex),
            trailingDotColor: Color(hex: trailingColorHex),
            momentDate: momentDate ?? MomentDate(date: createdAt),
            createdAt: createdAt,
            isFavorite: isFavorite
        )
    }

    static func hex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#403CF8"
        }
        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}

@MainActor
final class SwiftDataMomentStorePersistence: MomentStorePersistence {
    private static let fixtureVersion = 1
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() -> [MomentCardModel]? {
        let descriptor = FetchDescriptor<PersistedMomentState>()
        guard
            let fetched = try? context.fetch(descriptor),
            let state = fetched.first,
            let snapshots = try? JSONDecoder().decode(
                [PersistedMomentSnapshot].self,
                from: state.payload
            )
        else {
            return nil
        }
        let moments = snapshots.map(\.moment)
        if snapshots.contains(where: { $0.momentDate == nil || $0.pairMemberNames == nil }),
           let migrated = try? JSONEncoder().encode(moments.map(PersistedMomentSnapshot.init(moment:))) {
            state.payload = migrated
            try? context.save()
        }
        return moments
    }

    func save(_ moments: [MomentCardModel]) throws {
        let snapshots = moments.map(PersistedMomentSnapshot.init(moment:))
        let payload = try JSONEncoder().encode(snapshots)
        let descriptor = FetchDescriptor<PersistedMomentState>()
        if let existing = try context.fetch(descriptor).first {
            existing.fixtureVersion = Self.fixtureVersion
            existing.payload = payload
        } else {
            context.insert(
                PersistedMomentState(
                    fixtureVersion: Self.fixtureVersion,
                    payload: payload
                )
            )
        }
        try context.save()
    }
}
