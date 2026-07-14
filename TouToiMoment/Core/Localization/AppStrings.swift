import Foundation

enum AppStrings {
    static let newMomentStep1ScreenTitle = String(
        localized: "new_moment.step1.screen_title",
        defaultValue: "New TouToi Moment",
        comment: "Top title for new moment step 1."
    )

    static let newMomentDismiss = String(
        localized: "new_moment.dismiss",
        defaultValue: "閉じる",
        comment: "Accessibility label for dismissing the new moment flow."
    )

    static let newMomentEditCompletedStepHint = String(
        localized: "new_moment.edit_completed_step_hint",
        defaultValue: "このステップを編集します。",
        comment: "Accessibility hint for returning to an already completed new moment step."
    )

    static let newMomentDiscardTitle = String(
        localized: "new_moment.discard.title",
        defaultValue: "作成をやめますか？",
        comment: "Title for confirming dismissal of the new moment flow."
    )

    static let newMomentDiscardMessage = String(
        localized: "new_moment.discard.message",
        defaultValue: "入力した内容は保存されません。",
        comment: "Message for confirming dismissal of the new moment flow."
    )

    static let newMomentDiscardKeepEditing = String(
        localized: "new_moment.discard.keep_editing",
        defaultValue: "編集を続ける",
        comment: "Button label for cancelling dismissal of the new moment flow."
    )

    static let newMomentDiscardConfirm = String(
        localized: "new_moment.discard.confirm",
        defaultValue: "破棄して閉じる",
        comment: "Button label for confirming dismissal of the new moment flow."
    )

    static let newMomentStep1Progress = String(
        localized: "new_moment.step1.progress",
        defaultValue: "New Moment の 4 ステップ中 1 つ目",
        comment: "Progress label for the first new moment step."
    )

    static let newMomentStep1ChooseTitle = String(
        localized: "new_moment.step1.choose_title",
        defaultValue: "1 - CHOOSE",
        comment: "Section title for the choose step."
    )

    static let newMomentStep1PairLabel = String(
        localized: "new_moment.step1.pair_label",
        defaultValue: "PAIR *",
        comment: "Field label for pair selection."
    )

    static let newMomentStep1SourceLabel = String(
        localized: "new_moment.step1.source_label",
        defaultValue: "SOURCE",
        comment: "Field label for source selection."
    )

    static let newMomentStep1PairPlaceholder = String(
        localized: "new_moment.step1.pair_placeholder",
        defaultValue: "ペアを選択",
        comment: "Placeholder for pair field."
    )

    static let newMomentStep1SourcePlaceholder = String(
        localized: "new_moment.step1.source_placeholder",
        defaultValue: "例: ドラマ・アニメ・漫画等のタイトル",
        comment: "Placeholder for source field."
    )

    static let newMomentStep1NewSource = String(
        localized: "new_moment.step1.new_source",
        defaultValue: "+ New Source",
        comment: "Placeholder action for creating a new source."
    )

    static let newMomentStep1NewPair = String(
        localized: "new_moment.step1.new_pair",
        defaultValue: "+ New Pair",
        comment: "Placeholder action for creating a new pair."
    )

    static let newMomentStep1PairNoneOption = String(
        localized: "new_moment.step1.pair_none_option",
        defaultValue: "None",
        comment: "Clear selection option in pair dropdown."
    )

    static let newMomentStep1NewPairSheetTitle = String(
        localized: "new_moment.step1.new_pair_sheet_title",
        defaultValue: "New Pair",
        comment: "Title for the new pair bottom sheet."
    )

    static let newMomentStep1NewPairMember1Label = String(
        localized: "new_moment.step1.new_pair_member1_label",
        defaultValue: "MEMBER 1 *",
        comment: "Label for the first member field in the new pair sheet."
    )

    static let newMomentStep1NewPairMember1Placeholder = String(
        localized: "new_moment.step1.new_pair_member1_placeholder",
        defaultValue: "例: キャラクター名",
        comment: "Placeholder for the first member field in the new pair sheet."
    )

    static let newMomentStep1NewPairMember2Label = String(
        localized: "new_moment.step1.new_pair_member2_label",
        defaultValue: "MEMBER 2",
        comment: "Label for the second member field in the new pair sheet."
    )

    static let newMomentStep1NewPairMember2Placeholder = String(
        localized: "new_moment.step1.new_pair_member2_placeholder",
        defaultValue: "例: キャラクター名",
        comment: "Placeholder for the second member field in the new pair sheet."
    )

    static let newMomentStep1NewPairNameLabel = String(
        localized: "new_moment.step1.new_pair_name_label",
        defaultValue: "ペア名",
        comment: "Label for the pair name field in the new pair sheet."
    )

    static let newMomentStep1NewPairNamePlaceholder = String(
        localized: "new_moment.step1.new_pair_name_placeholder",
        defaultValue: "例: ペア名",
        comment: "Placeholder for the pair name field in the new pair sheet."
    )

    static let newMomentStep1NewPairOptional = String(
        localized: "new_moment.step1.new_pair_optional",
        defaultValue: "(optional)",
        comment: "Optional marker for the pair name field in the new pair sheet."
    )

    static let newMomentStep1NewPairNameNote = String(
        localized: "new_moment.step1.new_pair_name_note",
        defaultValue: "ここに入力した内容がディスプレイネームとして表示されます。未入力の場合は、MEMBER 1 ・ MEMBER 2 が表示されます。",
        comment: "Helper note under the pair name field in the new pair sheet."
    )

    static let newMomentStep1NewPairDisplayNameLabel = String(
        localized: "new_moment.step1.new_pair_display_name_label",
        defaultValue: "DISPLAY NAME",
        comment: "Label for the generated display name preview in the new pair sheet."
    )

    static let newMomentStep1NewPairDisplayNamePlaceholder = String(
        localized: "new_moment.step1.new_pair_display_name_placeholder",
        defaultValue: "Member 1 • Member 2",
        comment: "Placeholder for the generated display name preview in the new pair sheet."
    )

    static let newMomentStep1NewPairDisplayNameHelp = String(
        localized: "new_moment.step1.new_pair_display_name_help",
        defaultValue: "Auto-generated from member names · Updates as you type",
        comment: "Helper text for the generated display name preview in the new pair sheet."
    )

    static let newMomentStep1NewPairNicknameLabel = String(
        localized: "new_moment.step1.new_pair_nickname_label",
        defaultValue: "NICKNAME",
        comment: "Label for the pair nickname field in the new pair sheet."
    )

    static let newMomentStep1NewPairNicknamePlaceholder = String(
        localized: "new_moment.step1.new_pair_nickname_placeholder",
        defaultValue: "e.g. ひめフリ",
        comment: "Placeholder for the pair nickname field in the new pair sheet."
    )

    static let newMomentStep1NewPairColorLabel = String(
        localized: "new_moment.step1.new_pair_color_label",
        defaultValue: "PAIR COLOR",
        comment: "Label for the pair color selector in the new pair sheet."
    )

    static let newMomentStep1NewPairPreviewLabel = String(
        localized: "new_moment.step1.new_pair_preview_label",
        defaultValue: "PREVIEW",
        comment: "Label for the pair preview section in the new pair sheet."
    )

    static let newMomentStep1NewPairSave = String(
        localized: "new_moment.step1.new_pair_save",
        defaultValue: "Save",
        comment: "Save action title in the new pair sheet."
    )

    static let newMomentStep1NewPairCancel = String(
        localized: "new_moment.step1.new_pair_cancel",
        defaultValue: "Cancel",
        comment: "Cancel action title in the new pair sheet."
    )

    static let newMomentStep1Next = String(
        localized: "new_moment.step1.next",
        defaultValue: "次へ",
        comment: "Primary CTA title for proceeding from step 1."
    )

    static let newMomentStep1NewSourceSheetTitle = String(
        localized: "new_moment.step1.new_source_sheet_title",
        defaultValue: "New Source",
        comment: "Title for the new source bottom sheet."
    )

    static let newMomentStep1NewSourceCancel = String(
        localized: "new_moment.step1.new_source_cancel",
        defaultValue: "Cancel",
        comment: "Cancel action title in the new source sheet."
    )

    static let newMomentStep1NewSourceSave = String(
        localized: "new_moment.step1.new_source_save",
        defaultValue: "Save",
        comment: "Save action title in the new source sheet."
    )

    static let newMomentStep1NewSourceNameLabel = String(
        localized: "new_moment.step1.new_source_name_label",
        defaultValue: "ソース名 *",
        comment: "Label for the source name field in the new source sheet."
    )

    static let newMomentStep1NewSourceNamePlaceholder = String(
        localized: "new_moment.step1.new_source_name_placeholder",
        defaultValue: "例: ドラマ・アニメ・漫画等のタイトル",
        comment: "Placeholder for the source name field in the new source sheet."
    )

    static let newMomentStep1NewSourceMediumLabel = String(
        localized: "new_moment.step1.new_source_medium_label",
        defaultValue: "媒体 *",
        comment: "Label for the medium field in the new source sheet."
    )

    static let newMomentStep1HelpTitle = String(
        localized: "new_moment.step1.help_title",
        defaultValue: "SOURCE について",
        comment: "Alert title for source help."
    )

    static let newMomentStep1HelpMessage = String(
        localized: "new_moment.step1.help_message",
        defaultValue: "作品名や配信タイトルなど、モーメントの出典をあとで見返しやすくするための情報です。",
        comment: "Alert message for source help."
    )

    static let newMomentStep1HelpDismiss = String(
        localized: "new_moment.step1.help_dismiss",
        defaultValue: "閉じる",
        comment: "Dismiss button title for source help."
    )

    static let newMomentStep1ProceedToContext = String(
        localized: "new_moment.step1.proceed_to_context",
        defaultValue: "Step2 に進む",
        comment: "Accessibility label for proceeding to step 2 from the summary block."
    )

    static let newMomentStep2Title = String(
        localized: "new_moment.step2.title",
        defaultValue: "2 - CONTEXT",
        comment: "Step 2 summary title."
    )

    static let newMomentStep2Subtitle = String(
        localized: "new_moment.step2.subtitle",
        defaultValue: "Media Locator",
        comment: "Step 2 summary subtitle."
    )

    static let newMomentStep2Progress = String(
        localized: "new_moment.step2.progress",
        defaultValue: "New Moment の 4 ステップ中 2 つ目",
        comment: "Progress label for the second new moment step."
    )

    static let newMomentStep2ChooseCompletedTitle = String(
        localized: "new_moment.step2.choose_completed_title",
        defaultValue: "✓ 1 - CHOOSE",
        comment: "Completed step 1 summary title in step 2."
    )

    static let newMomentStep2NoPair = String(
        localized: "new_moment.step2.no_pair",
        defaultValue: "Pair未選択",
        comment: "Fallback pair name in step 2 summary."
    )

    static let newMomentStep2NoSource = String(
        localized: "new_moment.step2.no_source",
        defaultValue: "Source未選択",
        comment: "Fallback source name in step 2 summary."
    )

    static let newMomentStep2Next = String(
        localized: "new_moment.step2.next",
        defaultValue: "次へ",
        comment: "Primary CTA title for proceeding from step 2."
    )

    static let newMomentStep2TimestampCancel = String(
        localized: "new_moment.step2.timestamp.cancel",
        defaultValue: "Cancel",
        comment: "Cancel action title in the timestamp picker."
    )

    static let newMomentStep2TimestampTitle = String(
        localized: "new_moment.step2.timestamp.title",
        defaultValue: "Timestamp",
        comment: "Title in the timestamp picker."
    )

    static let newMomentStep2TimestampDone = String(
        localized: "new_moment.step2.timestamp.done",
        defaultValue: "Done",
        comment: "Confirmation action title in the timestamp picker."
    )

    static let newMomentStep2KeyboardNext = String(
        localized: "new_moment.step2.keyboard.next",
        defaultValue: "Next",
        comment: "Keyboard toolbar action for moving to the next context field."
    )

    static let newMomentStep2KeyboardDone = String(
        localized: "new_moment.step2.keyboard.done",
        defaultValue: "Done",
        comment: "Keyboard toolbar action for finishing context entry."
    )

    static func newMomentStep2ContextCopy(key: String, defaultValue: String) -> String {
        Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    }

    static let newMomentStep3Title = String(
        localized: "new_moment.step3.title",
        defaultValue: "3 - CAPTURE",
        comment: "Step 3 summary title."
    )

    static let newMomentStep3Subtitle = String(
        localized: "new_moment.step3.subtitle",
        defaultValue: "Scene · Heart",
        comment: "Step 3 summary subtitle."
    )

    static let newMomentStep4Title = String(
        localized: "new_moment.step4.title",
        defaultValue: "4 - REACT",
        comment: "Step 4 summary title."
    )

    static let newMomentStep4Subtitle = String(
        localized: "new_moment.step4.subtitle",
        defaultValue: "Reaction",
        comment: "Step 4 summary subtitle."
    )

    static let newMomentStep3Progress = String(
        localized: "new_moment.step3.progress",
        defaultValue: "New Moment の 4 ステップ中 3 つ目",
        comment: "Progress label for the third new moment step."
    )

    static let newMomentStep3SceneSummaryLabel = String(
        localized: "new_moment.step3.scene_summary_label",
        defaultValue: "SCENE SUMMARY",
        comment: "Label for the scene summary field."
    )

    static let newMomentStep3SceneSummaryPlaceholder = String(
        localized: "new_moment.step3.scene_summary_placeholder",
        defaultValue: "場面や状況を短くメモ（再会の直前）",
        comment: "Placeholder for the scene summary field."
    )

    static let newMomentStep3HeartScreamLabel = String(
        localized: "new_moment.step3.heart_scream_label",
        defaultValue: "HEART SCREAM *",
        comment: "Label for the heart scream field."
    )

    static let newMomentStep3HeartScreamPlaceholder = String(
        localized: "new_moment.step3.heart_scream_placeholder",
        defaultValue: "その瞬間の気持ちをそのまま残す（尊い……！！）",
        comment: "Placeholder for the heart scream field."
    )

    static let newMomentStep3Next = String(
        localized: "new_moment.step3.next",
        defaultValue: "次へ",
        comment: "Primary CTA title for proceeding from step 3."
    )

    static let newMomentStep3NextDisabledHint = String(
        localized: "new_moment.step3.next_disabled_hint",
        defaultValue: "Scene Summary または Heart Scream を入力してください。",
        comment: "Accessibility hint for disabled step 3 next button."
    )

    static let newMomentStep4Progress = String(
        localized: "new_moment.step4.progress",
        defaultValue: "New Moment の 4 ステップ中 4 つ目",
        comment: "Progress label for the fourth new moment step."
    )

    static let newMomentStep4ChooseCompletedTitle = String(
        localized: "new_moment.step4.choose_completed_title",
        defaultValue: "✓ 1 - CHOOSE",
        comment: "Completed step 1 summary title in step 4."
    )

    static let newMomentStep4ContextCompletedTitle = String(
        localized: "new_moment.step4.context_completed_title",
        defaultValue: "✓ 2 - CONTEXT",
        comment: "Completed step 2 summary title in step 4."
    )

    static let newMomentStep4CaptureCompletedTitle = String(
        localized: "new_moment.step4.capture_completed_title",
        defaultValue: "✓ 3 - CAPTURE",
        comment: "Completed step 3 summary title in step 4."
    )

    static let newMomentStep4ReactionPickerPrompt = String(
        localized: "new_moment.step4.reaction_picker_prompt",
        defaultValue: "REACTIONS",
        comment: "Label above the reaction picker trigger."
    )

    static let newMomentStep4AddReactions = String(
        localized: "new_moment.step4.add_reactions",
        defaultValue: "✨ Add Reactions",
        comment: "Empty reaction picker trigger title."
    )

    static let newMomentStep4ReactionHelp = String(
        localized: "new_moment.step4.reaction_help",
        defaultValue: "Tap to choose one or more reactions.",
        comment: "Helper text for reaction selection."
    )

    static let newMomentStep4SaveMoment = String(
        localized: "new_moment.step4.save_moment",
        defaultValue: "Save Moment",
        comment: "Primary CTA title for saving a moment."
    )

    static let newMomentStep4SaveDisabledHint = String(
        localized: "new_moment.step4.save_disabled_hint",
        defaultValue: "Scene Summary または Heart Scream を入力してください。",
        comment: "Accessibility hint for disabled save button."
    )

    static let newMomentReactionPickerCancel = String(
        localized: "new_moment.reaction_picker.cancel",
        defaultValue: "Cancel",
        comment: "Cancel action title in the reaction picker."
    )

    static let newMomentReactionPickerTitle = String(
        localized: "new_moment.reaction_picker.title",
        defaultValue: "Choose Reactions",
        comment: "Title for the reaction picker."
    )

    static let newMomentReactionPickerSave = String(
        localized: "new_moment.reaction_picker.save",
        defaultValue: "Save",
        comment: "Save action title in the reaction picker."
    )

    static let newMomentStepSummaryEmpty = String(
        localized: "new_moment.step.summary_empty",
        defaultValue: "未入力",
        comment: "Fallback summary text when a completed step has no entered value."
    )

    static func newMomentStepCompletedSummary(_ value: String) -> String {
        value.isEmpty ? newMomentStepSummaryEmpty : value
    }

    static let newMomentStep1Retry = String(
        localized: "new_moment.step1.retry",
        defaultValue: "再読み込み",
        comment: "Retry action for reloading pair options."
    )

    static let newMomentStep1LoadError = String(
        localized: "new_moment.step1.load_error",
        defaultValue: "Step1 の候補を読み込めませんでした。",
        comment: "Error message for pair loading failure."
    )

    static let newMomentStepPlaceholderTitle = String(
        localized: "new_moment.placeholder.title",
        defaultValue: "Step2 は次に実装します",
        comment: "Placeholder title for the next new moment steps."
    )

    static let newMomentStep3PlaceholderTitle = String(
        localized: "new_moment.placeholder.step3_title",
        defaultValue: "Step3 は次に実装します",
        comment: "Placeholder title for new moment step 3."
    )

    static let newMomentStepPlaceholderNoPair = String(
        localized: "new_moment.placeholder.no_pair",
        defaultValue: "未選択",
        comment: "Fallback label when no pair has been selected yet."
    )

    static let newMomentStepPlaceholderNoSource = String(
        localized: "new_moment.placeholder.no_source",
        defaultValue: "未選択",
        comment: "Fallback label when no source has been selected yet."
    )

    static func newMomentStep1MomentCount(count: Int) -> String {
        String(
            format: String(
                localized: "new_moment.step1.moment_count_format",
                defaultValue: "Moments %d",
                comment: "Moment count for a pair option in step 1."
            ),
            locale: .current,
            count
        )
    }

    static func newMomentStep1ContinueWithPair(name: String) -> String {
        String(
            format: String(
                localized: "new_moment.step1.continue_with_pair_format",
                defaultValue: "%@ で Step2 へ",
                comment: "Continue CTA when a pair is selected in step 1."
            ),
            locale: .current,
            name
        )
    }

    static let newMomentStep1ContinueWithoutPair = String(
        localized: "new_moment.step1.continue_without_pair",
        defaultValue: "Pair を選ばず Step2 へ",
        comment: "Continue CTA when no pair is selected in step 1."
    )

    static func newMomentStep1SelectedPairHint(name: String) -> String {
        String(
            format: String(
                localized: "new_moment.step1.selected_pair_hint_format",
                defaultValue: "選択中: %@",
                comment: "Hint showing the currently selected pair in step 1."
            ),
            locale: .current,
            name
        )
    }

    static func newMomentStepPlaceholderSelectedPair(name: String) -> String {
        String(
            format: String(
                localized: "new_moment.placeholder.selected_pair_format",
                defaultValue: "ここまでで選ばれた Pair: %@",
                comment: "Placeholder body showing the selected pair after step 1."
            ),
            locale: .current,
            name
        )
    }

    static func newMomentStepPlaceholderSelectedSource(name: String) -> String {
        String(
            format: String(
                localized: "new_moment.placeholder.selected_source_format",
                defaultValue: "ここまでで選ばれた Source: %@",
                comment: "Placeholder body showing the selected source after step 1."
            ),
            locale: .current,
            name
        )
    }

    static func pairsFavoriteToggleLabel(name: String) -> String {
        String(
            format: String(
                localized: "pairs.favorite_toggle.label_format",
                defaultValue: "%@ のお気に入り状態を切り替える",
                comment: "Accessibility label for the pair favorite toggle button."
            ),
            locale: .current,
            name
        )
    }

    static func homeGreetingTitle(name: String) -> String {
        String(
            format: String(
                localized: "home.greeting.title_format",
                defaultValue: "Hi, %@.",
                comment: "Home greeting title format with the user's display name."
            ),
            locale: .current,
            name
        )
    }

    static let homeGreetingSubtitle = String(
        localized: "home.greeting.subtitle",
        defaultValue: "今日も尊い瞬間を残そう。",
        comment: "Home greeting subtitle under the main title."
    )

    static let homeRecordMomentHint = String(
        localized: "home.record_moment.hint",
        defaultValue: "タップして新しい瞬間を残す＋",
        comment: "Hint below the central home record button."
    )

    static let homeNewMomentCTA = String(
        localized: "home.cta.new_moment",
        defaultValue: "New Toutoi Moment",
        comment: "Primary call-to-action on the home screen."
    )

    static let homeFavMomentsTitle = String(
        localized: "home.section.fav_moments",
        defaultValue: "Fav Moments",
        comment: "Section title for favorite moments on the home screen."
    )

    static let homeTopPairsTitle = String(
        localized: "home.section.top_pairs",
        defaultValue: "Your Top Pairs",
        comment: "Section title for top pairs on the home screen."
    )

    static let pairsNewPair = String(
        localized: "pairs.cta.new_pair",
        defaultValue: "New Pair",
        comment: "Call-to-action card label on the pairs screen."
    )

    static let pairsFilterAll = String(
        localized: "pairs.filter.all",
        defaultValue: "All",
        comment: "Filter chip for showing all pairs."
    )

    static let pairsFilterFavorite = String(
        localized: "pairs.filter.favorite",
        defaultValue: "Favorite",
        comment: "Filter chip for showing favorite pairs."
    )

    static let pairDetailTitle = String(
        localized: "pair_detail.title",
        defaultValue: "Pair",
        comment: "Navigation title for the pair detail screen."
    )

    static let pairDetailRecentMomentsTitle = String(
        localized: "pair_detail.section.recent_moments",
        defaultValue: "Recent Moments",
        comment: "Section title for recent moments on the pair detail screen."
    )

    static let pairDetailNewMomentButton = String(
        localized: "pair_detail.cta.new_moment",
        defaultValue: "New Moment",
        comment: "Button label for adding a new moment from pair detail."
    )

    static let pairDetailStatMoments = String(
        localized: "pair_detail.stat.moments",
        defaultValue: "Moments",
        comment: "Stat label for the total moments count."
    )

    static let pairDetailStatLast = String(
        localized: "pair_detail.stat.last",
        defaultValue: "Last",
        comment: "Stat label for the most recent entry placeholder."
    )

    static let pairDetailStatSince = String(
        localized: "pair_detail.stat.since",
        defaultValue: "Since",
        comment: "Stat label for the since placeholder."
    )

    static let pairDetailBackButton = String(
        localized: "pair_detail.back_button",
        defaultValue: "戻る",
        comment: "Accessibility label for returning from pair detail."
    )

    static let pairDetailEditButton = String(
        localized: "pair_detail.edit_button",
        defaultValue: "編集",
        comment: "Accessibility label for the pair detail edit button."
    )

    static let tabHome = String(
        localized: "tab.home",
        defaultValue: "Home",
        comment: "Bottom tab title for the home screen."
    )

    static let tabPairs = String(
        localized: "tab.pairs",
        defaultValue: "Pairs",
        comment: "Bottom tab title for the pairs screen."
    )

    static let tabMoments = String(
        localized: "tab.moments",
        defaultValue: "Moments",
        comment: "Bottom tab title for the moments screen."
    )

    static let tabSources = String(
        localized: "tab.sources",
        defaultValue: "Sources",
        comment: "Bottom tab title for the sources screen."
    )
}
