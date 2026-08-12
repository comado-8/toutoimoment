import Foundation

struct NewSourceDraft: Equatable {
    var displayName = ""
    var mediaType = "anime"
    var streamingPlatformID: StreamingPlatformID?
    var customStreamingPlatformName = ""
    var relatedURLText = ""

    init() {}

    init(source: SourceSummary) {
        displayName = source.displayName
        mediaType = source.mediaType
        streamingPlatformID = source.streamingPlatform?.id
        customStreamingPlatformName = source.streamingPlatform?.customName ?? ""
        relatedURLText = source.relatedURL.absoluteString
    }

    var trimmedDisplayName: String {
        SourceNamePolicy.normalized(displayName)
    }

    var relatedURL: URL? {
        SourceRelatedURLPolicy.normalizedURL(from: relatedURLText)
    }

    var isURLValid: Bool {
        relatedURL != nil
    }

    var streamingPlatform: StreamingPlatform? {
        guard mediaType == "streaming", let streamingPlatformID else {
            return nil
        }
        return StreamingPlatform(
            id: streamingPlatformID,
            customName: StreamingPlatformNamePolicy.limited(customStreamingPlatformName)
        )
    }

    var isStreamingPlatformValid: Bool {
        mediaType != "streaming" || streamingPlatform?.isValid == true
    }

    var isValid: Bool {
        !trimmedDisplayName.isEmpty
            && SourceLocatorSchema.schema(for: mediaType) != nil
            && isStreamingPlatformValid
            && isURLValid
    }

    func makeRequest() -> SourceCreateRequest? {
        guard
            isValid,
            let schema = SourceLocatorSchema.schema(for: mediaType),
            let relatedURL
        else {
            return nil
        }

        return SourceCreateRequest(
            displayName: trimmedDisplayName,
            helperText: schema.mediaLabelJa,
            mediaType: schema.mediaType,
            streamingPlatform: schema.mediaType == "streaming" ? streamingPlatform : nil,
            relatedURL: relatedURL
        )
    }

    func makeUpdateRequest() -> SourceUpdateRequest? {
        guard let request = makeRequest() else { return nil }
        return SourceUpdateRequest(
            displayName: request.displayName,
            streamingPlatform: request.streamingPlatform,
            relatedURL: request.relatedURL
        )
    }
}
