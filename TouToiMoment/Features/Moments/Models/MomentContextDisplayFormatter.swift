import Foundation

struct MomentContextDisplayItem: Hashable, Identifiable {
    let key: String
    let label: String
    let value: String

    var id: String { key }
}

enum MomentContextDisplayFormatter {
    private static let cardPriority = [
        "page", "slide", "songOrder", "act", "scene", "chapter", "timestamp"
    ]

    static func items(for moment: MomentCardModel) -> [MomentContextDisplayItem] {
        let fieldsByKey = schema(for: moment).contextFieldRows
            .flatMap { $0 }
            .reduce(into: [String: SourceLocatorSchema.ContextField]()) { result, field in
                result[field.key] = field
            }

        return moment.contextValues.compactMap { context in
            let trimmed = context.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            let field = fieldsByKey[context.key]
            let formattedValue: String
            formattedValue = field.map {
                schema(for: moment).formattedMomentValue(
                    LocatorValue(key: $0.key, value: trimmed)
                )
            } ?? trimmed

            return MomentContextDisplayItem(
                key: context.key,
                label: field?.label ?? context.key,
                value: formattedValue
            )
        }
    }

    static func compactSummary(for moment: MomentCardModel) -> String {
        items(for: moment).map(\.value).joined(separator: " · ")
    }

    static func locationSummary(for moment: MomentCardModel) -> String {
        items(for: moment)
            .filter { $0.key != "timestamp" }
            .map(\.value)
            .joined(separator: " · ")
    }

    static func timestamp(for moment: MomentCardModel) -> String? {
        items(for: moment).first(where: { $0.key == "timestamp" })?.value
    }

    static func reactionLabels(for moment: MomentCardModel) -> [String] {
        guard !moment.reactionIDs.isEmpty else { return moment.reactionLabels }

        return moment.reactionIDs.enumerated().map { index, reactionID in
            ReactionCatalog.reaction(withID: reactionID)?.displayText
                ?? (moment.reactionLabels.indices.contains(index) ? moment.reactionLabels[index] : reactionID)
        }
    }

    static func cardLabel(for moment: MomentCardModel) -> String? {
        let valuesByKey = Dictionary(uniqueKeysWithValues: items(for: moment).map { ($0.key, $0.value) })
        return cardPriority.lazy.compactMap { valuesByKey[$0] }.first
    }

    static func contextValues(from draft: NewMomentDraft) -> [MomentCardModel.ContextValue] {
        draft.contextValues.map {
            MomentCardModel.ContextValue(key: $0.key, value: $0.value)
        }
    }

    private static func schema(for moment: MomentCardModel) -> SourceLocatorSchema {
        SourceLocatorSchema.schema(
            for: moment.mediaType ?? SourceLocatorSchema.fallbackMediaType
        ) ?? .fallback
    }
}

enum MomentShareTextFormatter {
    static func text(
        for moment: MomentCardModel,
        configuration: MomentShareConfiguration? = nil
    ) -> String {
        let configuration = configuration ?? .initial(for: moment)
        let sourceLine = [
            moment.sourceName.nilIfPlaceholder,
            moment.episodeDisplayLabel,
            MomentContextDisplayFormatter.compactSummary(for: moment).trimmedOrNil
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        let reactionLine = MomentContextDisplayFormatter.reactionLabels(for: moment)
            .joined(separator: "  ")

        return (
            [configuration.heartText(for: moment)] + [
                sourceLine.trimmedOrNil,
                configuration.showsPair ? moment.pairName.nilIfPlaceholder : nil,
                configuration.showsReaction ? reactionLine.trimmedOrNil : nil,
                configuration.showsHashtag ? "#TouToiMoment" : nil
            ]
        )
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}

extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var nilIfPlaceholder: String? {
        guard let value = trimmedOrNil, value != "—" else { return nil }
        return value
    }
}
