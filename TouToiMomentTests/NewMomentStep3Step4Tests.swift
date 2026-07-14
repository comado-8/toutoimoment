import Testing
@testable import TouToiMoment

struct NewMomentStep3Step4Tests {
    @Test func draftKeepsCaptureAndReactionValuesAcrossSteps() {
        var draft = NewMomentDraft()
        draft.updateSceneSummary("場面メモ")
        draft.updateHeartScream("心の叫び")
        draft.updateSelectedReactions([
            NewMomentDraft.SelectedReaction(
                id: "positive.toutoi",
                section: "positive",
                emoji: "❤️",
                label: "尊い"
            ),
        ])

        #expect(draft.sceneSummary == "場面メモ")
        #expect(draft.heartScream == "心の叫び")
        #expect(draft.selectedReactions.map(\.id) == ["positive.toutoi"])
    }

    @Test func reactionCatalogMatchesDocsOrder() {
        let expectedSections = [
            "❤️ POSITIVE",
            "💜 EMOTIONAL",
            "🔥 EXCITED",
            "🤣 OTAKU",
            "🧠 ANALYSIS",
        ]
        let expectedLabels = [
            "❤️ 尊い", "🥰 キュン", "😊 大好き", "😌 癒された", "✨ 幸せ", "🙏 ありがとう…", "🌸 微笑ましい",
            "😭 泣いた", "🥹 感動", "💔 切ない", "🫠 しんどい", "🥺 胸が苦しい", "😮‍💨 エモい",
            "🤯 衝撃", "🔥 神回", "⭐ 神演技", "⚡ 鳥肌", "💥 最高", "👏 拍手",
            "😂 爆笑", "😳 可愛い", "🙈 見守りたい", "😏 ニヤけた", "🫥 無理…", "💘 沼",
            "🤸 横転", "🤸‍♂️ 大横転", "🚑 救急車", "⚰️ 墓入り", "🧎 ひれ伏す",
            "👀 伏線", "💡 考察", "✅ 解釈一致", "🤔 解釈違い", "😲 気づいた",
        ]

        #expect(ReactionCatalog.sections.map(\.title) == expectedSections)
        #expect(ReactionCatalog.allReactions.map(\.displayText) == expectedLabels)
        #expect(ReactionCatalog.allReactions.count == 35)
    }

    @MainActor
    @Test func reactionPickerCancelDiscardsTemporarySelection() {
        let selected = ReactionCatalog.allReactions[0]
        let next = ReactionCatalog.allReactions[1]
        let viewModel = NewMomentStep4ViewModel(
            draft: NewMomentDraft(
                sceneSummary: "場面",
                selectedReactions: [selected]
            )
        )

        viewModel.beginReactionEditing()
        viewModel.toggleReaction(next)
        viewModel.cancelReactionEditing()

        #expect(viewModel.selectedReactions.map(\.id) == [selected.id])
        #expect(viewModel.pickerSelectionIDs == Set([selected.id]))
    }

    @MainActor
    @Test func reactionPickerCommitUpdatesDraftInCatalogOrder() {
        let first = ReactionCatalog.allReactions[0]
        let later = ReactionCatalog.allReactions[10]
        let viewModel = NewMomentStep4ViewModel(
            draft: NewMomentDraft(sceneSummary: "場面")
        )

        viewModel.beginReactionEditing()
        viewModel.toggleReaction(later)
        viewModel.toggleReaction(first)
        viewModel.commitReactionEditing()

        #expect(viewModel.selectedReactions.map(\.id) == [first.id, later.id])
    }

    @MainActor
    @Test func step3NextRequiresSceneSummaryOrHeartScream() {
        let empty = NewMomentStep3ViewModel(draft: NewMomentDraft())
        #expect(empty.canContinue == false)

        let whitespace = NewMomentStep3ViewModel(draft: NewMomentDraft(sceneSummary: "  \n"))
        #expect(whitespace.canContinue == false)

        let sceneOnly = NewMomentStep3ViewModel(draft: NewMomentDraft(sceneSummary: "場面"))
        #expect(sceneOnly.canContinue == true)

        let heartOnly = NewMomentStep3ViewModel(draft: NewMomentDraft(heartScream: "尊い"))
        #expect(heartOnly.canContinue == true)
    }

    @MainActor
    @Test func step4SaveRequiresSceneSummaryOrHeartScreamOnly() {
        let empty = NewMomentStep4ViewModel(draft: NewMomentDraft())
        #expect(empty.canSave == false)

        let sceneOnly = NewMomentStep4ViewModel(draft: NewMomentDraft(sceneSummary: "場面"))
        #expect(sceneOnly.canSave == true)

        let heartOnly = NewMomentStep4ViewModel(draft: NewMomentDraft(heartScream: "尊い"))
        #expect(heartOnly.canSave == true)

        let reactionOnly = NewMomentStep4ViewModel(
            draft: NewMomentDraft(selectedReactions: [ReactionCatalog.allReactions[0]])
        )
        #expect(reactionOnly.canSave == false)
    }
}
