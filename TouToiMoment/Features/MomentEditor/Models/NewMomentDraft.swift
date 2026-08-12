import Foundation

struct NewMomentDraft: Hashable {
    struct ContextValue: Hashable, Identifiable {
        let key: String
        var value: String

        var id: String { key }
    }

    struct SelectedPair: Hashable {
        let id: String
        let displayName: String
        let nickname: String
        let member1Name: String
        let member2Name: String?
        let leadingColorHex: String?
        let trailingColorHex: String?

        init(
            id: String,
            displayName: String,
            nickname: String,
            member1Name: String? = nil,
            member2Name: String? = nil,
            leadingColorHex: String? = nil,
            trailingColorHex: String? = nil
        ) {
            self.id = id
            self.displayName = displayName
            self.nickname = nickname
            self.member1Name = member1Name ?? displayName
            self.member2Name = member2Name
            self.leadingColorHex = leadingColorHex
            self.trailingColorHex = trailingColorHex
        }
    }

    struct SelectedSource: Hashable {
        let id: String
        let displayName: String
        let helperText: String
        let mediaType: String
    }

    struct SelectedEpisode: Hashable {
        let id: String
        let sourceID: String
        let locatorValues: [LocatorValue]
        let displayName: String
    }

    struct SelectedReaction: Hashable, Identifiable {
        let id: String
        let section: String
        let emoji: String
        let label: String

        var displayText: String {
            "\(emoji) \(label)"
        }
    }

    var selectedPair: SelectedPair?
    var selectedSource: SelectedSource?
    var selectedEpisode: SelectedEpisode?
    var contextValues: [ContextValue]
    private var storedMomentTitle: String
    var momentTitle: String {
        get { storedMomentTitle }
        set { storedMomentTitle = MomentTitlePolicy.limited(newValue) }
    }
    private var storedSceneSummary: String
    var sceneSummary: String {
        get { storedSceneSummary }
        set { storedSceneSummary = MomentSceneTextPolicy.limited(newValue) }
    }
    private var storedHeartScream: String
    var heartScream: String {
        get { storedHeartScream }
        set { storedHeartScream = HeartScreamTextPolicy.limited(newValue) }
    }
    var selectedReactions: [SelectedReaction]
    var momentDate: MomentDate
    private var contextMediaType: String?

    nonisolated init(
        selectedPair: SelectedPair? = nil,
        selectedSource: SelectedSource? = nil,
        selectedEpisode: SelectedEpisode? = nil,
        contextValues: [ContextValue] = [],
        momentTitle: String = "",
        sceneSummary: String = "",
        heartScream: String = "",
        selectedReactions: [SelectedReaction] = [],
        momentDate: MomentDate = MomentDate(date: .now),
        contextMediaType: String? = nil
    ) {
        self.selectedPair = selectedPair
        self.selectedSource = selectedSource
        self.selectedEpisode = selectedEpisode
        self.contextValues = contextValues
        // Existing records are not silently truncated when opened for editing.
        // Setters and persistence boundaries still enforce the current limits.
        self.storedMomentTitle = momentTitle
        self.storedSceneSummary = sceneSummary
        self.storedHeartScream = heartScream
        self.selectedReactions = selectedReactions
        self.momentDate = momentDate
        self.contextMediaType = contextMediaType
    }

    var selectedPairID: String? {
        selectedPair?.id
    }

    var selectedPairDisplayName: String? {
        selectedPair?.displayName
    }

    var selectedSourceID: String? {
        selectedSource?.id
    }

    var selectedSourceDisplayName: String? {
        selectedSource?.displayName
    }

    var selectedSourceHelperText: String? {
        selectedSource?.helperText
    }

    var selectedEpisodeID: String? {
        selectedEpisode?.id
    }

    var hasMomentBody: Bool {
        !sceneSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !heartScream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasRequiredHeartScream: Bool {
        !heartScream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isWithinTextLimits: Bool {
        MomentTitlePolicy.isValid(momentTitle)
            && MomentSceneTextPolicy.isValid(sceneSummary)
            && HeartScreamTextPolicy.isValid(heartScream)
    }

    var hasAnyCreationInput: Bool {
        hasMomentBody
            || !momentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedPair != nil
            || selectedSource != nil
            || selectedEpisode != nil
            || contextValues.contains {
                !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            || !selectedReactions.isEmpty
    }

    mutating func selectPair(
        id: String,
        displayName: String,
        nickname: String,
        member1Name: String? = nil,
        member2Name: String? = nil,
        leadingColorHex: String? = nil,
        trailingColorHex: String? = nil
    ) {
        selectedPair = SelectedPair(
            id: id,
            displayName: displayName,
            nickname: nickname,
            member1Name: member1Name,
            member2Name: member2Name,
            leadingColorHex: leadingColorHex,
            trailingColorHex: trailingColorHex
        )
    }

    mutating func clearPair() {
        selectedPair = nil
    }

    mutating func selectSource(
        id: String,
        displayName: String,
        helperText: String,
        mediaType: String
    ) {
        if selectedSource?.id != id {
            selectedEpisode = nil
            contextValues = []
            contextMediaType = nil
        }

        selectedSource = SelectedSource(
            id: id,
            displayName: displayName,
            helperText: helperText,
            mediaType: mediaType
        )
    }

    mutating func clearSource() {
        selectedSource = nil
        selectedEpisode = nil
        contextValues = []
        contextMediaType = nil
    }

    mutating func selectEpisode(
        _ episode: EpisodeSummary,
        schema: SourceLocatorSchema
    ) {
        guard let sourceID = selectedSourceID else { return }
        selectedEpisode = SelectedEpisode(
            id: episode.id,
            sourceID: sourceID,
            locatorValues: episode.locatorValues,
            displayName: schema.episodeDisplayName(for: episode.locatorValues)
        )
    }

    mutating func clearEpisode() {
        selectedEpisode = nil
    }

    mutating func configureContext(using schema: SourceLocatorSchema) {
        let existingValues = contextMediaType == schema.mediaType
            ? Dictionary(
                contextValues.map { ($0.key, $0.value) },
                uniquingKeysWith: { _, latest in latest }
            )
            : [:]
        let fields = schema.locationContextFieldRows.flatMap { $0 }
        contextValues = fields.map { field in
            ContextValue(
                key: field.key,
                value: existingValues[field.key] ?? field.defaultValue ?? ""
            )
        }
        contextMediaType = schema.mediaType
    }

    func contextValue(for key: String) -> String {
        contextValues.first(where: { $0.key == key })?.value ?? ""
    }

    mutating func updateContextValue(key: String, value: String) {
        guard let index = contextValues.firstIndex(where: { $0.key == key }) else {
            return
        }

        contextValues[index].value = value
    }

    mutating func updateSceneSummary(_ value: String) {
        sceneSummary = value
    }

    mutating func updateMomentTitle(_ value: String) {
        momentTitle = value
    }

    mutating func updateHeartScream(_ value: String) {
        heartScream = value
    }

    mutating func updateSelectedReactions(_ reactions: [SelectedReaction]) {
        selectedReactions = reactions
    }

    mutating func updateMomentDate(_ date: Date, calendar: Calendar = .current) {
        momentDate = MomentDate(date: date, calendar: calendar)
    }
}
