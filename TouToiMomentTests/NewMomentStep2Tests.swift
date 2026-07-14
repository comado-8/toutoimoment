import Testing
@testable import TouToiMoment

struct NewMomentStep2Tests {
    @Test func everyMediaTypeHasExpectedContextFields() {
        let expectedKeys: [String: [String]] = [
            "anime": ["season", "episode", "timestamp"],
            "tv_drama": ["season", "episode", "timestamp"],
            "movie": ["timestamp"],
            "manga": ["volume", "chapter", "page"],
            "novel": ["volume", "chapter", "page"],
            "doujin_book": ["page"],
            "youtube_video": ["timestamp"],
            "youtube_live": ["timestamp"],
            "streaming": ["timestamp"],
            "radio_podcast": ["episode", "timestamp"],
            "music_video": ["timestamp"],
            "live_concert": ["position"],
            "stage_musical": ["performance", "scene"],
            "event_fanmeeting": ["session", "position"],
            "magazine": ["issue", "page"],
            "book_interview": ["section", "page"],
            "sns_post": ["position"],
            "blog_article": ["section"],
            "game": ["story", "scene"],
            "voice_drama": ["track", "timestamp"],
            "other": ["position"],
        ]

        #expect(SourceLocatorSchema.all.count == expectedKeys.count)

        for schema in SourceLocatorSchema.all {
            let fields = schema.contextFieldRows.flatMap { $0 }
            #expect(fields.map(\.key) == expectedKeys[schema.mediaType])
            #expect(Set(fields.map(\.key)).count == fields.count)
        }
    }

    @Test func printedMediaUsesPageWithoutLineOrPanel() {
        for mediaType in ["manga", "novel", "doujin_book"] {
            let keys = SourceLocatorSchema.schema(for: mediaType)?.contextFieldRows
                .flatMap { $0 }
                .map(\.key)

            #expect(keys?.contains("page") == true)
            #expect(keys?.contains("line") == false)
            #expect(keys?.contains("panel") == false)
        }
    }

    @Test func videoSourcesOnlyRequestTimestamp() {
        for mediaType in ["movie", "youtube_video", "youtube_live", "streaming", "music_video"] {
            let fields = SourceLocatorSchema.schema(for: mediaType)?.contextFieldRows.flatMap { $0 }
            #expect(fields?.map(\.key) == ["timestamp"])
            #expect(fields?.first?.inputKind == .timestamp)
        }
    }

    @Test func numericFieldsUseDigitsOnlyExamplesAndExpectedUnits() {
        let expectedUnits: [String: String] = [
            "anime.season": "期",
            "anime.episode": "話",
            "tv_drama.season": "",
            "manga.volume": "巻",
            "manga.chapter": "話",
            "manga.page": "ページ",
            "novel.volume": "巻",
            "novel.chapter": "章",
            "novel.page": "ページ",
            "doujin_book.page": "ページ",
            "radio_podcast.episode": "回",
            "event_fanmeeting.session": "部",
            "magazine.page": "ページ",
            "book_interview.page": "ページ",
            "voice_drama.track": "トラック",
        ]

        let numericFields = SourceLocatorSchema.all.flatMap { schema in
            schema.contextFieldRows.flatMap { $0 }
                .filter { $0.inputKind == .number }
                .map { ("\(schema.mediaType).\($0.key)", $0) }
        }

        #expect(Set(numericFields.map(\.0)) == Set(expectedUnits.keys))
        for (identifier, field) in numericFields {
            #expect(!field.placeholder.isEmpty)
            #expect(field.placeholder.allSatisfy { $0.isASCII && $0.isNumber })
            #expect((field.unit ?? "") == expectedUnits[identifier])
        }
    }

    @MainActor
    @Test func numericInputIsNormalizedToASCIIDigits() {
        let viewModel = NewMomentStep2ViewModel(draft: draft(mediaType: "manga"))
        let volume = viewModel.contextFieldRows.flatMap { $0 }.first { $0.key == "volume" }!

        viewModel.updateValue(for: volume, value: "12話")
        #expect(viewModel.value(for: "volume") == "12")

        viewModel.updateValue(for: volume, value: "３巻")
        #expect(viewModel.value(for: "volume") == "3")

        viewModel.updateValue(for: volume, value: "abc")
        #expect(viewModel.value(for: "volume").isEmpty)
    }

    @MainActor
    @Test func contextValuesAreRestoredByStableKey() {
        let viewModel = NewMomentStep2ViewModel(draft: draft(mediaType: "novel"))
        let page = viewModel.contextFieldRows.flatMap { $0 }.first { $0.key == "page" }!
        viewModel.updateValue(for: page, value: "88")

        let restored = NewMomentStep2ViewModel(draft: viewModel.draft)

        #expect(restored.value(for: "page") == "88")
    }

    @MainActor
    @Test func selectingAnotherSourceClearsExistingContext() {
        let viewModel = NewMomentStep2ViewModel(draft: draft(mediaType: "novel"))
        let page = viewModel.contextFieldRows.flatMap { $0 }.first { $0.key == "page" }!
        viewModel.updateValue(for: page, value: "88")

        var changedDraft = viewModel.draft
        changedDraft.selectSource(
            id: "another-source",
            displayName: "別のソース",
            helperText: "",
            mediaType: "novel",
            totalCount: nil,
            isFavorite: false
        )
        let changedViewModel = NewMomentStep2ViewModel(draft: changedDraft)

        #expect(changedViewModel.value(for: "page").isEmpty)
    }

    @MainActor
    @Test func timestampUsesTargetFieldAndHHMMSSFormat() {
        let viewModel = NewMomentStep2ViewModel(draft: draft(mediaType: "anime"))

        viewModel.updateTimestamp(key: "timestamp", hour: 1, minute: 2, second: 3)

        #expect(viewModel.value(for: "timestamp") == "01:02:03")
        let components = viewModel.timestampComponents(for: "timestamp")
        #expect(components.hour == 1)
        #expect(components.minute == 2)
        #expect(components.second == 3)
    }

    private func draft(mediaType: String) -> NewMomentDraft {
        NewMomentDraft(
            selectedSource: .init(
                id: "source-id",
                displayName: "テスト用ソース",
                helperText: "",
                mediaType: mediaType,
                totalCount: nil,
                isFavorite: false
            )
        )
    }
}
