import Foundation

struct NewEpisodeDraft: Equatable {
    let schema: SourceLocatorSchema
    var locatorValues: [LocatorValue]
    var relatedURLText = ""
    var displayTitle = ""

    init(schema: SourceLocatorSchema) {
        self.schema = schema
        self.locatorValues = schema.initialEpisodeValues()
    }

    init(schema: SourceLocatorSchema, episode: EpisodeSummary) {
        self.schema = schema
        self.locatorValues = schema.normalizedEpisodeValues(episode.locatorValues)
        self.relatedURLText = episode.relatedURL?.absoluteString ?? ""
        self.displayTitle = episode.displayTitle ?? ""
    }

    func value(for key: String) -> String {
        locatorValues.first(where: { $0.key == key })?.value ?? ""
    }

    mutating func updateValue(_ value: String, for field: LocatorField) {
        let normalized = LocatorValuePolicy.normalized(value, for: field)
        if let index = locatorValues.firstIndex(where: { $0.key == field.key }) {
            locatorValues[index].value = normalized
        } else {
            locatorValues.append(LocatorValue(key: field.key, value: normalized))
        }
    }

    var relatedURL: URL? {
        guard !relatedURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return SourceRelatedURLPolicy.normalizedURL(from: relatedURLText)
    }

    var isRelatedURLValid: Bool {
        relatedURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || relatedURL != nil
    }

    var isValid: Bool {
        schema.isValidEpisodeValues(locatorValues) && isRelatedURLValid
    }

    var request: EpisodeCreateRequest? {
        guard isValid else { return nil }
        return EpisodeCreateRequest(
            locatorValues: schema.normalizedEpisodeValues(locatorValues),
            relatedURL: relatedURL,
            displayTitle: EpisodeDisplayTitlePolicy.normalized(displayTitle),
            updatesDisplayTitle: true
        )
    }
}
