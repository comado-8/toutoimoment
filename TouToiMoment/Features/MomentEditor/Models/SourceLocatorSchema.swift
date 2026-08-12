import Foundation

enum LocatorInputKind: Hashable, Codable {
    case integer
    case decimal
    case timestamp
    case date
    case choice
}

struct LocatorOption: Identifiable, Hashable, Codable {
    let id: String
    let label: String
}

struct LocatorValue: Identifiable, Hashable, Codable {
    let key: String
    var value: String

    var id: String { key }
}

struct LocatorField: Identifiable, Hashable {
    let key: String
    let label: String
    let placeholder: String
    let inputKind: LocatorInputKind
    let unit: String?
    let options: [LocatorOption]
    let defaultValue: String?

    var id: String { key }

    init(
        key: String,
        label: String,
        placeholder: String,
        inputKind: LocatorInputKind,
        unit: String? = nil,
        options: [LocatorOption] = [],
        defaultValue: String? = nil
    ) {
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.inputKind = inputKind
        self.unit = unit
        self.options = options
        self.defaultValue = defaultValue
    }
}

enum LocatorValuePolicy {
    static let maximumIntegerValue = 99_999
    static let maximumDecimalValue = Decimal(string: "99999.99")!
    static let maximumIntegralDigits = 5
    static let maximumFractionalDigits = 2

    static func normalized(_ value: String, for field: LocatorField) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch field.inputKind {
        case .integer, .decimal:
            return normalizedNumberCharacters(trimmed)
        case .timestamp:
            return normalizedTimestamp(trimmed) ?? trimmed
        case .date, .choice:
            return trimmed
        }
    }

    static func isValid(_ value: String, for field: LocatorField) -> Bool {
        let normalized = normalized(value, for: field)
        guard !normalized.isEmpty else { return true }

        switch field.inputKind {
        case .integer:
            guard normalized.allSatisfy(\.isNumber), let number = Int(normalized) else {
                return false
            }
            return normalized.count <= maximumIntegralDigits
                && number >= 1
                && number <= maximumIntegerValue
        case .decimal:
            let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
            guard
                parts.count <= 2,
                parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
                parts[0].count <= maximumIntegralDigits,
                (parts.count == 1 || parts[1].count <= maximumFractionalDigits),
                let number = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
            else {
                return false
            }
            return number >= 0 && number <= maximumDecimalValue
        case .timestamp:
            return normalizedTimestamp(normalized) != nil
        case .date:
            return isoDateFormatter.date(from: normalized) != nil
        case .choice:
            return field.options.contains(where: { $0.id == normalized })
        }
    }

    static func valueMap(
        from values: [LocatorValue],
        fields: [LocatorField]
    ) -> [String: String] {
        let source = Dictionary(
            values.map { ($0.key, $0.value) },
            uniquingKeysWith: { _, latest in latest }
        )
        return Dictionary(uniqueKeysWithValues: fields.map { field in
            let rawValue = source[field.key] ?? field.defaultValue ?? ""
            return (field.key, normalized(rawValue, for: field))
        })
    }

    static func values(
        from map: [String: String],
        fields: [LocatorField]
    ) -> [LocatorValue] {
        fields.map { field in
            LocatorValue(
                key: field.key,
                value: normalized(map[field.key] ?? field.defaultValue ?? "", for: field)
            )
        }
    }

    static func formattedTimestamp(hour: Int, minute: Int, second: Int) -> String {
        String(
            format: "%02d:%02d:%02d",
            min(max(hour, 0), 99),
            min(max(minute, 0), 59),
            min(max(second, 0), 59)
        )
    }

    static func timestampComponents(_ value: String) -> (hour: Int, minute: Int, second: Int)? {
        guard let normalized = normalizedTimestamp(value) else { return nil }
        let parts = normalized.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return (parts[0], parts[1], parts[2])
    }

    private static func normalizedNumberCharacters(_ value: String) -> String {
        value.unicodeScalars.map { scalar -> String in
            switch scalar.value {
            case 0xFF10...0xFF19:
                return UnicodeScalar(scalar.value - 0xFF10 + 0x30).map(String.init) ?? ""
            case 0xFF0E:
                return "."
            case 0x2212, 0xFF0D:
                return "-"
            default:
                return String(scalar)
            }
        }
        .joined()
    }

    private static func normalizedTimestamp(_ value: String) -> String? {
        let normalized = normalizedNumberCharacters(value)
        let parts = normalized.split(separator: ":", omittingEmptySubsequences: false)
        guard
            (2...3).contains(parts.count),
            parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) })
        else {
            return nil
        }
        let numbers = parts.compactMap { Int($0) }
        guard numbers.count == parts.count else { return nil }
        let hour = parts.count == 3 ? numbers[0] : 0
        let minute = parts.count == 3 ? numbers[1] : numbers[0]
        let second = parts.count == 3 ? numbers[2] : numbers[1]
        guard (0...99).contains(hour), (0...59).contains(minute), (0...59).contains(second) else {
            return nil
        }
        return formattedTimestamp(hour: hour, minute: minute, second: second)
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct SourceLocatorSchema: Identifiable, Hashable {
    typealias ContextField = LocatorField

    enum EpisodeRequirement: Hashable {
        case none
        case all(Set<String>)
        case any(Set<String>)
    }

    let mediaType: String
    let mediaLabelJa: String
    let sourceNameExample: String
    let episodeFields: [LocatorField]
    let episodeRequirement: EpisodeRequirement
    let momentLocationFields: [LocatorField]

    var id: String { mediaType }
    var supportsEpisodes: Bool { !episodeFields.isEmpty }
    var locationContextFieldRows: [[LocatorField]] {
        momentLocationFields.map { [$0] }
    }
    var contextFieldRows: [[LocatorField]] {
        locationContextFieldRows
    }

    static let fallbackMediaType = "other"

    func initialEpisodeValues() -> [LocatorValue] {
        episodeFields.map {
            LocatorValue(key: $0.key, value: $0.defaultValue ?? "")
        }
    }

    func normalizedEpisodeValues(_ values: [LocatorValue]) -> [LocatorValue] {
        let map = LocatorValuePolicy.valueMap(from: values, fields: episodeFields)
        return LocatorValuePolicy.values(from: map, fields: episodeFields)
    }

    func isValidEpisodeValues(_ values: [LocatorValue]) -> Bool {
        guard supportsEpisodes else { return false }
        let map = LocatorValuePolicy.valueMap(from: values, fields: episodeFields)
        guard episodeFields.allSatisfy({
            LocatorValuePolicy.isValid(map[$0.key] ?? "", for: $0)
        }) else {
            return false
        }

        switch episodeRequirement {
        case .none:
            return true
        case .all(let keys):
            return keys.allSatisfy { !(map[$0] ?? "").isEmpty }
        case .any(let keys):
            return keys.contains { !(map[$0] ?? "").isEmpty }
        }
    }

    func episodeDisplayName(for values: [LocatorValue]) -> String {
        let map = LocatorValuePolicy.valueMap(from: values, fields: episodeFields)
        switch mediaType {
        case "anime", "tv_drama":
            return numberedEpisodeName(
                kind: map["episode_kind"] ?? "regular",
                number: map["episode"] ?? ""
            )
        case "manga":
            return joined([
                unitValue(map["volume"], unit: "巻"),
                chapterName(kind: map["manga_kind"] ?? "regular", number: map["chapter"] ?? "", unit: "話")
            ])
        case "novel":
            return joined([
                unitValue(map["volume"], unit: "巻"),
                chapterName(kind: map["novel_kind"] ?? "regular", number: map["chapter"] ?? "", unit: "章")
            ])
        case "radio_podcast":
            let number = map["episode"] ?? ""
            let kind = map["radio_kind"] ?? "regular"
            let numberText = number.isEmpty
                ? nil
                : (kind == "special" ? "特別回 \(number)" : "#\(number)")
            return joined([numberText, map["date"]?.nilIfEmpty])
        case "voice_drama":
            let number = map["track"] ?? ""
            guard !number.isEmpty else { return "" }
            return map["track_kind"] == "bonus" ? "Bonus Track \(number)" : "Track \(number)"
        default:
            return ""
        }
    }

    func formattedMomentValue(_ value: LocatorValue) -> String {
        guard let field = momentLocationFields.first(where: { $0.key == value.key }) else {
            return value.value
        }
        let normalized = LocatorValuePolicy.normalized(value.value, for: field)
        guard !normalized.isEmpty else { return "" }
        if field.inputKind == .choice {
            return field.options.first(where: { $0.id == normalized })?.label ?? normalized
        }
        if let unit = field.unit {
            return "\(normalized)\(unit)"
        }
        return normalized
    }

    static let all: [SourceLocatorSchema] = [
        schema(
            "anime", "アニメ", "例：Solo Leveling 第2期",
            episode: [
                choice("episode_kind", "種類", [
                    option("regular", "通常回"), option("special", "特別編"),
                    option("ova", "OVA／OAD"), option("recap", "総集編"),
                ]),
                decimal("episode", "話数", "12", unit: "話"),
            ],
            requirement: .all(["episode"]),
            moment: [timestamp]
        ),
        schema(
            "tv_drama", "ドラマ・TV番組", "例：番組名 Season 2",
            episode: [
                choice("episode_kind", "種類", [
                    option("regular", "通常回"), option("special", "特別編"),
                ]),
                decimal("episode", "話数・放送回", "5", unit: "話"),
            ],
            requirement: .all(["episode"]),
            moment: [timestamp]
        ),
        schema("movie", "映画", "例：作品名（字幕版）", moment: [timestamp]),
        schema(
            "manga", "漫画・コミック", "例：ONE PIECE",
            episode: [
                choice("manga_kind", "種類", [
                    option("regular", "通常話"), option("extra", "番外編"),
                    option("special", "特別編"),
                ]),
                integer("volume", "巻数", "3", unit: "巻"),
                decimal("chapter", "話数", "42", unit: "話"),
            ],
            requirement: .any(["volume", "chapter"]),
            moment: [page]
        ),
        schema(
            "novel", "小説・ラノベ", "例：作品名",
            episode: [
                choice("novel_kind", "種類", [
                    option("regular", "通常章"), option("prologue", "プロローグ"),
                    option("epilogue", "エピローグ"), option("extra", "番外編"),
                ]),
                integer("volume", "巻数", "3", unit: "巻"),
                decimal("chapter", "章数", "4", unit: "章"),
            ],
            requirement: .any(["volume", "chapter"]),
            moment: [page]
        ),
        schema("doujin_book", "同人誌・冊子", "例：C105新刊『作品名』", moment: [page]),
        schema("youtube_video", "YouTube動画", "例：動画タイトル", moment: [timestamp]),
        schema("streaming", "配信全般", "例：2026-07-03 配信タイトル", moment: [timestamp]),
        schema(
            "radio_podcast", "ラジオ・Podcast", "例：番組名",
            episode: [
                choice("radio_kind", "種類", [
                    option("regular", "通常回"), option("special", "特別回"),
                ]),
                integer("episode", "回数", "24", unit: "回"),
                date("date", "配信日"),
            ],
            requirement: .any(["episode", "date"]),
            moment: [timestamp]
        ),
        schema("music_video", "MV・PV", "例：楽曲名 Official MV", moment: [timestamp]),
        schema(
            "live_concert", "ライブ・コンサート", "例：公演名 2026-04-10 東京",
            moment: [
                choice("concert_part", "区分", [
                    option("main", "本編"), option("mc", "MC"), option("encore", "Encore"),
                ]),
                integer("song", "曲順", "3", unit: "曲目"),
            ]
        ),
        schema(
            "stage_musical", "舞台・ミュージカル", "例：演目 2026-05-01 昼公演",
            moment: [
                integer("act", "Act番号", "2", unit: "幕"),
                integer("scene", "Scene番号", "3", unit: "場"),
            ]
        ),
        schema("event_fanmeeting", "イベント・ファンミ", "例：イベント名 2026-07-03 2部"),
        schema("magazine", "雑誌", "例：雑誌名 2026年8月号", moment: [page]),
        schema("book_interview", "書籍・写真集・インタビュー本", "例：書籍名", moment: [page]),
        schema(
            "sns_post", "SNS投稿", "例：2026-07-03 投稿概要",
            moment: [integer("slide", "Slide番号", "2", unit: "枚目")]
        ),
        schema("blog_article", "ブログ・記事", "例：記事タイトル"),
        schema(
            "game", "ゲーム", "例：ゲーム名 Route／Chapter",
            moment: [integer("chapter", "Chapter番号", "5", unit: "章")]
        ),
        schema(
            "voice_drama", "ドラマCD・音声ドラマ", "例：作品名 Disc 1",
            episode: [
                choice("track_kind", "種類", [
                    option("regular", "通常Track"), option("bonus", "Bonus Track"),
                ]),
                integer("track", "Track番号", "3", unit: "Track"),
            ],
            requirement: .all(["track"]),
            moment: [timestamp]
        ),
        schema("other", "その他", "例：識別できるSource名"),
    ]

    static func schema(for mediaType: String) -> SourceLocatorSchema? {
        all.first(where: { $0.mediaType == mediaType })
    }

    static var fallback: SourceLocatorSchema {
        schema(for: fallbackMediaType) ?? all[all.count - 1]
    }

    private static var timestamp: LocatorField {
        LocatorField(
            key: "timestamp",
            label: copy("timestamp.label", "TIMESTAMP"),
            placeholder: "00:00:00",
            inputKind: .timestamp
        )
    }

    private static var page: LocatorField {
        integer("page", "Page", "32", unit: "ページ")
    }

    private static func schema(
        _ mediaType: String,
        _ label: String,
        _ sourceNameExample: String,
        episode: [LocatorField] = [],
        requirement: EpisodeRequirement = .none,
        moment: [LocatorField] = []
    ) -> SourceLocatorSchema {
        SourceLocatorSchema(
            mediaType: mediaType,
            mediaLabelJa: label,
            sourceNameExample: sourceNameExample,
            episodeFields: episode,
            episodeRequirement: requirement,
            momentLocationFields: moment
        )
    }

    private static func integer(
        _ key: String,
        _ label: String,
        _ placeholder: String,
        unit: String? = nil
    ) -> LocatorField {
        field(key, label, placeholder, .integer, unit: unit)
    }

    private static func decimal(
        _ key: String,
        _ label: String,
        _ placeholder: String,
        unit: String? = nil
    ) -> LocatorField {
        field(key, label, placeholder, .decimal, unit: unit)
    }

    private static func date(_ key: String, _ label: String) -> LocatorField {
        field(key, label, "yyyy-mm-dd", .date)
    }

    private static func choice(
        _ key: String,
        _ label: String,
        _ options: [LocatorOption]
    ) -> LocatorField {
        LocatorField(
            key: key,
            label: copy("\(key).label", label),
            placeholder: "",
            inputKind: .choice,
            options: options,
            defaultValue: options.first?.id
        )
    }

    private static func field(
        _ key: String,
        _ label: String,
        _ placeholder: String,
        _ inputKind: LocatorInputKind,
        unit: String? = nil
    ) -> LocatorField {
        LocatorField(
            key: key,
            label: copy("\(key).label", label),
            placeholder: copy("\(key).placeholder", placeholder),
            inputKind: inputKind,
            unit: unit.map { copy("\(key).unit", $0) }
        )
    }

    private static func option(_ id: String, _ label: String) -> LocatorOption {
        LocatorOption(id: id, label: copy("option.\(id)", label))
    }

    private static func copy(_ key: String, _ value: String) -> String {
        AppStrings.newMomentStep2ContextCopy(
            key: "source_locator.\(key)",
            defaultValue: value
        )
    }

    private func numberedEpisodeName(kind: String, number: String) -> String {
        guard !number.isEmpty else { return "" }
        switch kind {
        case "special": return "特別編 \(number)"
        case "ova": return "OVA \(number)"
        case "recap": return "総集編 \(number)"
        default: return "第\(number)話"
        }
    }

    private func chapterName(kind: String, number: String, unit: String) -> String? {
        if mediaType == "novel", kind == "prologue" {
            return number.isEmpty ? "プロローグ" : "プロローグ \(number)"
        }
        if mediaType == "novel", kind == "epilogue" {
            return number.isEmpty ? "エピローグ" : "エピローグ \(number)"
        }
        guard !number.isEmpty else { return nil }
        switch kind {
        case "extra": return "番外編 \(number)"
        case "special": return "特別編 \(number)"
        default: return "第\(number)\(unit)"
        }
    }

    private func unitValue(_ value: String?, unit: String) -> String? {
        guard let value = value?.nilIfEmpty else { return nil }
        return "\(value)\(unit)"
    }

    private func joined(_ values: [String?]) -> String {
        values.compactMap { $0?.nilIfEmpty }.joined(separator: "・")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
