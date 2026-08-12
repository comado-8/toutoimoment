import Foundation

struct NewMomentSelectableOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let helperText: String?
    let leadingColorHex: String?
    let trailingColorHex: String?
    let pairMember1Name: String?
    let pairMember2Name: String?
    let sourceMediaType: String?

    init(
        id: String,
        title: String,
        subtitle: String?,
        helperText: String?,
        leadingColorHex: String?,
        trailingColorHex: String?,
        pairMember1Name: String? = nil,
        pairMember2Name: String? = nil,
        sourceMediaType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.helperText = helperText
        self.leadingColorHex = leadingColorHex
        self.trailingColorHex = trailingColorHex
        self.pairMember1Name = pairMember1Name
        self.pairMember2Name = pairMember2Name
        self.sourceMediaType = sourceMediaType
    }

    init(source: SourceSummary) {
        self.init(
            id: source.id,
            title: source.displayName,
            subtitle: source.contextualHelperText,
            helperText: nil,
            leadingColorHex: nil,
            trailingColorHex: nil,
            sourceMediaType: source.mediaType
        )
    }
}
