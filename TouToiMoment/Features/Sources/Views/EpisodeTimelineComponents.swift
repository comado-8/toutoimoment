import SwiftUI

struct EpisodeTimelineMoment: Identifiable {
    let id: String
    let heartText: String
    let timestamp: String?
    let pairName: String?
    let reactionLabels: [String]
    let isFavorite: Bool

    init(moment: MomentCardModel) {
        id = moment.id
        heartText = moment.displayHeading
        timestamp = MomentContextDisplayFormatter.timestamp(for: moment)
            .map { Self.compactTimestamp($0) }
        pairName = moment.pairName.nilIfPlaceholder
        reactionLabels = MomentContextDisplayFormatter.reactionLabels(for: moment)
        isFavorite = moment.isFavorite
    }

    init(
        id: String,
        heartText: String,
        timestamp: String?,
        pairName: String?,
        reactionLabels: [String],
        isFavorite: Bool
    ) {
        self.id = id
        self.heartText = heartText
        self.timestamp = timestamp
        self.pairName = pairName
        self.reactionLabels = reactionLabels
        self.isFavorite = isFavorite
    }

    private static func compactTimestamp(_ timestamp: String) -> String {
        let components = timestamp.split(separator: ":")
        if components.count == 3, components.first == "00" {
            return components.dropFirst().joined(separator: ":")
        }
        return timestamp
    }
}

struct EpisodeMomentTimelineRow: View {
    let moment: EpisodeTimelineMoment
    let showsLine: Bool
    var onOpen: (() -> Void)?

    init(
        moment: MomentCardModel,
        showsLine: Bool,
        onOpen: (() -> Void)? = nil
    ) {
        self.moment = EpisodeTimelineMoment(moment: moment)
        self.showsLine = showsLine
        self.onOpen = onOpen
    }

    init(
        moment: EpisodeTimelineMoment,
        showsLine: Bool,
        onOpen: (() -> Void)? = nil
    ) {
        self.moment = moment
        self.showsLine = showsLine
        self.onOpen = onOpen
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 5) {
                MomentSparkleIcon(color: .appPrimary, width: 14, height: 21)

                if showsLine {
                    Rectangle()
                        .fill(Color.white.opacity(0.88))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 32)

            VStack(alignment: .leading, spacing: 8) {
                if let timestamp = moment.timestamp {
                    Text(timestamp)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.appPrimary, in: Capsule())
                }

                if let onOpen {
                    Button(action: onOpen) {
                        momentCard
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("episode_detail.moment.\(moment.id)")
                } else {
                    momentCard
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var momentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(moment.heartText)
                .font(.custom("ZenKakuGothicNew-Medium", size: 14, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    metadataChips
                }
                VStack(alignment: .leading, spacing: 8) {
                    metadataChips
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 12, fillOpacity: 0.40)
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let pairName = moment.pairName {
            EpisodeMetadataChip(
                text: pairName,
                foregroundColor: Color.appPrimarySoft
            )
        }

        if !moment.reactionLabels.isEmpty {
            EpisodeMetadataChip(
                text: moment.reactionLabels.joined(separator: "  "),
                foregroundColor: Color.appPrimary
            )
        }

        if moment.isFavorite {
            Spacer(minLength: 0)
            FavoriteStarIcon(variant: .on, width: 18, height: 19)
        }
    }
}

struct EpisodeMetadataChip: View {
    let text: String
    let foregroundColor: Color

    var body: some View {
        Text(text)
            .font(.custom("Geist-SemiBold", size: 11, relativeTo: .caption2))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.surfaceLight.opacity(0.86), in: Capsule())
    }
}
