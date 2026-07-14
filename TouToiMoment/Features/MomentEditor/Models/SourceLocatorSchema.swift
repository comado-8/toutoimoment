import Foundation

enum LocatorInputKind: Hashable {
    case text
    case number
    case timestamp
}

struct SourceLocatorSchema: Identifiable, Hashable {
    struct ContextField: Identifiable, Hashable {
        let key: String
        let label: String
        let placeholder: String
        let inputKind: LocatorInputKind
        let unit: String?

        var id: String { key }
    }

    struct LocatorLevel: Hashable {
        let label: String
        let example: String
        let inputKind: LocatorInputKind

        init(
            label: String,
            example: String,
            inputKind: LocatorInputKind = .text
        ) {
            self.label = label
            self.example = example
            self.inputKind = inputKind
        }
    }

    let mediaType: String
    let mediaLabelJa: String
    let locatorLevels: [LocatorLevel]
    let timeOrPositionLabel: String?
    let timeOrPositionExample: String?
    let timeOrPositionInputKind: LocatorInputKind

    var id: String { mediaType }
    static let fallbackMediaType = "other"

    var contextFieldRows: [[ContextField]] {
        Self.contextFieldRows(for: mediaType)
    }

    init(
        mediaType: String,
        mediaLabelJa: String,
        locatorLevels: [LocatorLevel],
        timeOrPositionLabel: String?,
        timeOrPositionExample: String?,
        timeOrPositionInputKind: LocatorInputKind = .text
    ) {
        self.mediaType = mediaType
        self.mediaLabelJa = mediaLabelJa
        self.locatorLevels = locatorLevels
        self.timeOrPositionLabel = timeOrPositionLabel
        self.timeOrPositionExample = timeOrPositionExample
        self.timeOrPositionInputKind = timeOrPositionInputKind
    }

    static let all: [SourceLocatorSchema] = [
        SourceLocatorSchema(
            mediaType: "anime",
            mediaLabelJa: "アニメ",
            locatorLevels: [
                .init(label: "Season", example: "Season 3", inputKind: .number),
                .init(label: "Episode", example: "EP15", inputKind: .number),
                .init(label: "Scene/Chapter", example: "Aパート / Bパート"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "00:18:42",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "tv_drama",
            mediaLabelJa: "ドラマ・TV番組",
            locatorLevels: [
                .init(label: "Season", example: "Season 1", inputKind: .number),
                .init(label: "Episode/回", example: "第5話 / #05", inputKind: .number),
                .init(label: "Corner", example: "トークパート"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "00:23:10",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "movie",
            mediaLabelJa: "映画",
            locatorLevels: [
                .init(label: "Chapter", example: "Chapter 7", inputKind: .number),
                .init(label: "Scene", example: "駅の別れ"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "01:12:30",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "manga",
            mediaLabelJa: "漫画・コミック",
            locatorLevels: [
                .init(label: "Volume", example: "8巻", inputKind: .number),
                .init(label: "Chapter/話", example: "第42話", inputKind: .number),
                .init(label: "Page", example: "p.126", inputKind: .number),
                .init(label: "Panel", example: "3コマ目", inputKind: .number),
            ],
            timeOrPositionLabel: "Page/Panel",
            timeOrPositionExample: "p.126 3コマ目"
        ),
        SourceLocatorSchema(
            mediaType: "novel",
            mediaLabelJa: "小説・ラノベ",
            locatorLevels: [
                .init(label: "Volume", example: "3巻", inputKind: .number),
                .init(label: "Chapter", example: "第4章", inputKind: .number),
                .init(label: "Page", example: "p.88", inputKind: .number),
                .init(label: "Line", example: "12行目", inputKind: .number),
            ],
            timeOrPositionLabel: "Page/Line",
            timeOrPositionExample: "p.88 12行目"
        ),
        SourceLocatorSchema(
            mediaType: "doujin_book",
            mediaLabelJa: "同人誌・冊子",
            locatorLevels: [
                .init(label: "Book/Issue", example: "C105新刊"),
                .init(label: "Page", example: "p.14", inputKind: .number),
                .init(label: "Panel/Line", example: "2コマ目"),
            ],
            timeOrPositionLabel: "Page/Panel",
            timeOrPositionExample: "p.14 2コマ目"
        ),
        SourceLocatorSchema(
            mediaType: "youtube_video",
            mediaLabelJa: "YouTube動画",
            locatorLevels: [
                .init(label: "Channel", example: "公式チャンネル"),
                .init(label: "Video", example: "夏祭り配信"),
                .init(label: "Section", example: "質問コーナー"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "01:23:45",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "youtube_live",
            mediaLabelJa: "YouTubeライブ・配信",
            locatorLevels: [
                .init(label: "Platform", example: "YouTube"),
                .init(label: "Stream", example: "夏祭り生配信"),
                .init(label: "Segment", example: "スパチャ読み / ゲーム中"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "02:11:05",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "streaming",
            mediaLabelJa: "配信全般",
            locatorLevels: [
                .init(label: "Platform", example: "Twitch / ツイキャス"),
                .init(label: "Stream", example: "雑談配信"),
                .init(label: "Segment", example: "冒頭 / コラボ枠"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "00:45:12",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "radio_podcast",
            mediaLabelJa: "ラジオ・Podcast",
            locatorLevels: [
                .init(label: "Program", example: "〇〇ラジオ"),
                .init(label: "Episode/回", example: "#24", inputKind: .number),
                .init(label: "Corner", example: "ふつおた"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "00:12:34",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "music_video",
            mediaLabelJa: "MV・PV",
            locatorLevels: [
                .init(label: "Artist/Unit", example: "〇〇"),
                .init(label: "Song/Video", example: "Blue Hour MV"),
                .init(label: "Scene", example: "2番サビ"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "02:34",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "live_concert",
            mediaLabelJa: "ライブ・コンサート",
            locatorLevels: [
                .init(label: "Tour/Event", example: "Spring Live"),
                .init(label: "Date/Venue", example: "2026/04/10 東京"),
                .init(label: "Part", example: "MC / Encore"),
                .init(label: "Song", example: "3曲目"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "MC中 / 3曲目後"
        ),
        SourceLocatorSchema(
            mediaType: "stage_musical",
            mediaLabelJa: "舞台・ミュージカル",
            locatorLevels: [
                .init(label: "Production", example: "〇〇ミュージカル"),
                .init(label: "Performance", example: "2026/05/01 昼"),
                .init(label: "Act/Scene", example: "Act 2 Scene 3"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "Act2 Scene3"
        ),
        SourceLocatorSchema(
            mediaType: "event_fanmeeting",
            mediaLabelJa: "イベント・ファンミ",
            locatorLevels: [
                .init(label: "Event", example: "ファンミーティング"),
                .init(label: "Session/部", example: "2部", inputKind: .number),
                .init(label: "Corner", example: "質問コーナー"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "質問コーナー後半"
        ),
        SourceLocatorSchema(
            mediaType: "magazine",
            mediaLabelJa: "雑誌",
            locatorLevels: [
                .init(label: "Magazine", example: "anan"),
                .init(label: "Issue", example: "2026年8月号"),
                .init(label: "Page", example: "p.32", inputKind: .number),
                .init(label: "Section", example: "インタビュー"),
            ],
            timeOrPositionLabel: "Page",
            timeOrPositionExample: "p.32",
            timeOrPositionInputKind: .number
        ),
        SourceLocatorSchema(
            mediaType: "book_interview",
            mediaLabelJa: "書籍・写真集・インタビュー本",
            locatorLevels: [
                .init(label: "Book", example: "公式ガイドブック"),
                .init(label: "Chapter/Section", example: "対談ページ"),
                .init(label: "Page", example: "p.54", inputKind: .number),
            ],
            timeOrPositionLabel: "Page",
            timeOrPositionExample: "p.54",
            timeOrPositionInputKind: .number
        ),
        SourceLocatorSchema(
            mediaType: "sns_post",
            mediaLabelJa: "SNS投稿",
            locatorLevels: [
                .init(label: "Platform", example: "X / Instagram"),
                .init(label: "Post", example: "楽屋写真投稿"),
                .init(label: "Thread/Slide", example: "2枚目 / リプ欄"),
            ],
            timeOrPositionLabel: "URL/Position",
            timeOrPositionExample: "URL / 2枚目"
        ),
        SourceLocatorSchema(
            mediaType: "blog_article",
            mediaLabelJa: "ブログ・記事",
            locatorLevels: [
                .init(label: "Site", example: "公式ブログ"),
                .init(label: "Article", example: "撮影裏話"),
                .init(label: "Section", example: "後半のQ&A"),
            ],
            timeOrPositionLabel: "URL/Section",
            timeOrPositionExample: "URL / Q&A"
        ),
        SourceLocatorSchema(
            mediaType: "game",
            mediaLabelJa: "ゲーム",
            locatorLevels: [
                .init(label: "Game", example: "〇〇"),
                .init(label: "Story/Chapter", example: "第5章"),
                .init(label: "Quest/Scene", example: "再会シーン"),
                .init(label: "Line", example: "選択肢後"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "第5章 再会シーン"
        ),
        SourceLocatorSchema(
            mediaType: "voice_drama",
            mediaLabelJa: "ドラマCD・音声ドラマ",
            locatorLevels: [
                .init(label: "Album/Work", example: "ドラマCD"),
                .init(label: "Track", example: "Track 3", inputKind: .number),
                .init(label: "Scene", example: "喧嘩後の会話"),
            ],
            timeOrPositionLabel: "Timestamp",
            timeOrPositionExample: "00:08:12",
            timeOrPositionInputKind: .timestamp
        ),
        SourceLocatorSchema(
            mediaType: "other",
            mediaLabelJa: "その他",
            locatorLevels: [
                .init(label: "Category", example: "未分類"),
                .init(label: "Section", example: "任意"),
                .init(label: "Position", example: "任意"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "自由入力"
        ),
    ]

    static func schema(for mediaType: String) -> SourceLocatorSchema? {
        all.first(where: { $0.mediaType == mediaType })
    }

    private static func contextFieldRows(for mediaType: String) -> [[ContextField]] {
        switch mediaType {
        case "anime":
            return [
                [
                    field("season", "SEASON（シーズン）", "2", .number, copyKey: "anime.season", unit: "期"),
                    field("episode", "EPISODE（話数）", "12", .number, copyKey: "anime.episode", unit: "話"),
                ],
                [timestampField],
            ]
        case "tv_drama":
            return [
                [
                    field("season", "SEASON（シーズン）", "2", .number, copyKey: "tv_drama.season"),
                    field("episode", "EPISODE（話数・放送回）", "第5話 / 2026-07-03 / 特番", .text, copyKey: "tv_drama.episode"),
                ],
                [timestampField],
            ]
        case "movie", "youtube_video", "youtube_live", "streaming", "music_video":
            return [[timestampField]]
        case "manga":
            return [
                [
                    field("volume", "VOLUME（巻数）", "3", .number, copyKey: "manga.volume", unit: "巻"),
                    field("chapter", "CHAPTER（話数）", "42", .number, copyKey: "manga.chapter", unit: "話"),
                ],
                [field("page", "PAGE（ページ）", "126", .number, copyKey: "manga.page", unit: "ページ")],
            ]
        case "novel":
            return [
                [
                    field("volume", "VOLUME（巻数）", "3", .number, copyKey: "novel.volume", unit: "巻"),
                    field("chapter", "CHAPTER（章）", "4", .number, copyKey: "novel.chapter", unit: "章"),
                ],
                [field("page", "PAGE（ページ）", "88", .number, copyKey: "novel.page", unit: "ページ")],
            ]
        case "doujin_book":
            return [[field("page", "PAGE（ページ）", "14", .number, copyKey: "doujin_book.page", unit: "ページ")]]
        case "radio_podcast":
            return [
                [field("episode", "EPISODE（回数）", "24", .number, copyKey: "radio_podcast.episode", unit: "回")],
                [timestampField],
            ]
        case "live_concert":
            return [[field("position", "POSITION（位置）", "MC中 / 3曲目後", .text, copyKey: "live_concert.position")]]
        case "stage_musical":
            return [[
                field("performance", "PERFORMANCE（公演回）", "2026-05-01 昼", .text, copyKey: "stage_musical.performance"),
                field("scene", "SCENE（幕・シーン）", "第2幕 第3場", .text, copyKey: "stage_musical.scene"),
            ]]
        case "event_fanmeeting":
            return [
                [field("session", "SESSION（部）", "2", .number, copyKey: "event_fanmeeting.session", unit: "部")],
                [field("position", "POSITION（位置）", "質問コーナー後半", .text, copyKey: "event_fanmeeting.position")],
            ]
        case "magazine":
            return [[
                field("issue", "ISSUE（号）", "2026年8月号", .text, copyKey: "magazine.issue"),
                field("page", "PAGE（ページ）", "32", .number, copyKey: "magazine.page", unit: "ページ"),
            ]]
        case "book_interview":
            return [[
                field("section", "SECTION（章・セクション）", "対談ページ", .text, copyKey: "book_interview.section"),
                field("page", "PAGE（ページ）", "54", .number, copyKey: "book_interview.page", unit: "ページ"),
            ]]
        case "sns_post":
            return [[field("position", "POSITION（投稿内の位置）", "2枚目 / 返信欄", .text, copyKey: "sns_post.position")]]
        case "blog_article":
            return [[field("section", "SECTION（セクション）", "後半のQ&A", .text, copyKey: "blog_article.section")]]
        case "game":
            return [[
                field("story", "STORY（ストーリー・章）", "第5章", .text, copyKey: "game.story"),
                field("scene", "SCENE（クエスト・シーン）", "再会シーン", .text, copyKey: "game.scene"),
            ]]
        case "voice_drama":
            return [
                [field("track", "TRACK（トラック番号）", "3", .number, copyKey: "voice_drama.track", unit: "トラック")],
                [timestampField],
            ]
        default:
            return [[field("position", "POSITION（位置）", "自由入力", .text, copyKey: "other.position")]]
        }
    }

    private static var timestampField: ContextField {
        field("timestamp", "TIMESTAMP", "00:00:00", .timestamp, copyKey: "timestamp")
    }

    private static func field(
        _ key: String,
        _ defaultLabel: String,
        _ defaultPlaceholder: String,
        _ inputKind: LocatorInputKind,
        copyKey: String,
        unit defaultUnit: String? = nil
    ) -> ContextField {
        ContextField(
            key: key,
            label: AppStrings.newMomentStep2ContextCopy(
                key: "new_moment.step2.context.\(copyKey).label",
                defaultValue: defaultLabel
            ),
            placeholder: AppStrings.newMomentStep2ContextCopy(
                key: "new_moment.step2.context.\(copyKey).placeholder",
                defaultValue: defaultPlaceholder
            ),
            inputKind: inputKind,
            unit: defaultUnit.map {
                AppStrings.newMomentStep2ContextCopy(
                    key: "new_moment.step2.context.\(copyKey).unit",
                    defaultValue: $0
                )
            }
        )
    }


    static var fallback: SourceLocatorSchema {
        schema(for: fallbackMediaType) ?? SourceLocatorSchema(
            mediaType: fallbackMediaType,
            mediaLabelJa: "その他",
            locatorLevels: [
                .init(label: "Category", example: "未分類"),
                .init(label: "Section", example: "任意"),
            ],
            timeOrPositionLabel: "Position",
            timeOrPositionExample: "自由入力"
        )
    }
}
