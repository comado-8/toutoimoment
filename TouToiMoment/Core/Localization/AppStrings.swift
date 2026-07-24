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
        defaultValue: "Member 1 ・ Member 2",
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

    static let momentsSearchPlaceholder = String(
        localized: "moments.search.placeholder",
        defaultValue: "Search moments",
        comment: "Placeholder in the Moments search field."
    )

    static let momentsScene = String(
        localized: "moments.face.scene",
        defaultValue: "Scene",
        comment: "Scene face label in the Moments display toggle."
    )

    static let momentsHeart = String(
        localized: "moments.face.heart",
        defaultValue: "Heart",
        comment: "Heart face label in the Moments display toggle."
    )

    static let momentsFilterAll = String(
        localized: "moments.filter.all",
        defaultValue: "すべて",
        comment: "Filter that clears all Moment category filters."
    )

    static let momentsFilterStar = String(
        localized: "moments.filter.star",
        defaultValue: "Star",
        comment: "Filter that shows favorite Moments."
    )

    static let momentsFilterPair = String(
        localized: "moments.filter.pair",
        defaultValue: "Pair",
        comment: "Pair filter menu title."
    )

    static let momentsFilterSource = String(
        localized: "moments.filter.source",
        defaultValue: "Source",
        comment: "Source filter menu title."
    )

    static let momentsFilterReaction = String(
        localized: "moments.filter.reaction",
        defaultValue: "Reaction",
        comment: "Reaction filter menu title."
    )

    static let momentsFilterAny = String(
        localized: "moments.filter.any",
        defaultValue: "指定なし",
        comment: "Menu option that clears one Moment filter category."
    )

    static let momentsEmptyTitle = String(
        localized: "moments.empty.title",
        defaultValue: "Momentが見つかりません",
        comment: "Empty state title when no Moments match filters."
    )

    static let momentsAddMoment = String(
        localized: "moments.add.accessibility_label",
        defaultValue: "新しいMomentを追加",
        comment: "Accessibility label for the add Moment button."
    )

    static let momentsFavoriteToggle = String(
        localized: "moments.favorite.toggle",
        defaultValue: "Favoriteを切り替える",
        comment: "Accessibility label for a Moment favorite button."
    )

    static let momentsFavoriteOn = String(
        localized: "moments.favorite.on",
        defaultValue: "ON",
        comment: "Accessibility value for a favorite Moment."
    )

    static let momentsFavoriteOff = String(
        localized: "moments.favorite.off",
        defaultValue: "OFF",
        comment: "Accessibility value for a non-favorite Moment."
    )

    static let momentsShowScene = String(
        localized: "moments.card.show_scene",
        defaultValue: "Sceneを表示",
        comment: "Accessibility action that shows the Scene face."
    )

    static let momentsShowHeart = String(
        localized: "moments.card.show_heart",
        defaultValue: "Heartを表示",
        comment: "Accessibility action that shows the Heart face."
    )

    static let momentDetailTitle = String(
        localized: "moment_detail.title",
        defaultValue: "Moment",
        comment: "Navigation title on Moment detail."
    )

    static let momentDetailMissingTitle = String(
        localized: "moment_detail.missing",
        defaultValue: "Momentが見つかりません",
        comment: "Message shown when a Moment no longer exists."
    )

    static let momentDetailShare = String(
        localized: "moment_detail.share",
        defaultValue: "HeartScreamカードを共有",
        comment: "Accessibility label for the Moment share action."
    )

    static let momentDetailMore = String(
        localized: "moment_detail.more",
        defaultValue: "その他の操作",
        comment: "Accessibility label for the Moment detail more menu."
    )

    static let momentDetailCopyHeart = String(
        localized: "moment_detail.copy_heart",
        defaultValue: "HeartScreamをコピー",
        comment: "Menu action that copies the Moment HeartScream."
    )

    static let momentDetailHeartCopied = String(
        localized: "moment_detail.heart_copied",
        defaultValue: "HeartScreamをコピーしました",
        comment: "Accessibility announcement after copying a HeartScream."
    )

    static let momentDetailDelete = String(
        localized: "moment_detail.delete",
        defaultValue: "Momentを削除",
        comment: "Destructive action that deletes a Moment."
    )

    static let momentDetailDeleteConfirmationTitle = String(
        localized: "moment_detail.delete_confirmation.title",
        defaultValue: "このMomentを削除しますか？",
        comment: "Title for the Moment deletion confirmation."
    )

    static let momentDetailDeleteConfirmationMessage = String(
        localized: "moment_detail.delete_confirmation.message",
        defaultValue: "添付した画像も削除されます。この操作は取り消せません。",
        comment: "Message for the Moment deletion confirmation."
    )

    static let momentDetailDeleteErrorMessage = String(
        localized: "moment_detail.delete_error",
        defaultValue: "Momentを削除できませんでした。もう一度お試しください。",
        comment: "Error shown when a Moment cannot be deleted."
    )

    static let momentDetailEdit = String(
        localized: "moment_detail.edit",
        defaultValue: "Momentを編集",
        comment: "Accessibility label for the Moment edit action."
    )

    static let momentDetailExpandScene = String(
        localized: "moment_detail.scene.expand",
        defaultValue: "全文を表示",
        comment: "Button that expands a long Scene on Moment detail."
    )

    static let momentDetailCollapseScene = String(
        localized: "moment_detail.scene.collapse",
        defaultValue: "閉じる",
        comment: "Button that collapses a long Scene on Moment detail."
    )

    static let sceneCharacterLimitReached = String(
        localized: "moment.scene.limit_reached",
        defaultValue: "Sceneは1000文字までです",
        comment: "Accessibility announcement when Scene reaches its character limit."
    )

    static func sceneCharacterCount(current: Int, maximum: Int) -> String {
        String(
            format: String(
                localized: "moment.scene.character_count",
                defaultValue: "%1$d／%2$d文字",
                comment: "Accessible Scene character count and maximum."
            ),
            locale: .current,
            current,
            maximum
        )
    }

    static let momentEditTitle = String(
        localized: "moment_edit.title",
        defaultValue: "Edit Moment",
        comment: "Navigation title on the Moment editor."
    )

    static let momentEditBack = String(
        localized: "moment_edit.back",
        defaultValue: "Moment詳細へ戻る",
        comment: "Accessibility label for the Moment editor back button."
    )

    static let momentEditSave = String(
        localized: "moment_edit.save",
        defaultValue: "変更を保存",
        comment: "Accessibility label for saving Moment edits."
    )

    static let momentEditDiscardTitle = String(
        localized: "moment_edit.discard.title",
        defaultValue: "変更を破棄しますか？",
        comment: "Title for the discard Moment edits confirmation."
    )

    static let momentEditDiscardMessage = String(
        localized: "moment_edit.discard.message",
        defaultValue: "保存していない変更は失われます。",
        comment: "Message for the discard Moment edits confirmation."
    )

    static let momentEditDiscardConfirm = String(
        localized: "moment_edit.discard.confirm",
        defaultValue: "変更を破棄",
        comment: "Destructive action that discards Moment edits."
    )

    static let momentEditKeepEditing = String(
        localized: "moment_edit.discard.keep_editing",
        defaultValue: "編集を続ける",
        comment: "Action that dismisses the discard confirmation."
    )

    static let momentEditLoadError = String(
        localized: "moment_edit.error.load",
        defaultValue: "選択肢を読み込めませんでした。現在の内容は編集できます。",
        comment: "Error shown when editor picker options cannot be loaded."
    )

    static let momentEditSaveError = String(
        localized: "moment_edit.error.save",
        defaultValue: "Momentを保存できませんでした。",
        comment: "Error shown when a Moment edit cannot be saved."
    )

    static let momentDetailHeartScream = String(
        localized: "moment_detail.section.heart_scream",
        defaultValue: "HeartScream",
        comment: "Heart scream section title on Moment detail."
    )

    static let momentDetailReaction = String(
        localized: "moment_detail.section.reaction",
        defaultValue: "Reaction",
        comment: "Reaction section title on Moment detail."
    )

    static let momentDetailSource = String(
        localized: "moment_detail.section.source",
        defaultValue: "Source",
        comment: "Source section title on Moment detail."
    )

    static let momentDetailSourceName = String(
        localized: "moment_detail.source.name",
        defaultValue: "Source",
        comment: "Label for the source name row on Moment detail."
    )

    static let momentDetailPair = String(
        localized: "moment_detail.section.pair",
        defaultValue: "Pair",
        comment: "Pair section title on Moment detail."
    )

    static let momentDetailRelated = String(
        localized: "moment_detail.section.related",
        defaultValue: "Related Moments",
        comment: "Related Moments section title."
    )

    static let momentDetailDetails = String(
        localized: "moment_detail.section.details",
        defaultValue: "Details",
        comment: "Metadata section title on Moment detail."
    )

    static let momentDetailCreated = String(
        localized: "moment_detail.created",
        defaultValue: "Created",
        comment: "Label for the Moment creation date."
    )

    static let momentDetailOpenPairHint = String(
        localized: "moment_detail.open_pair_hint",
        defaultValue: "Pairの詳細を表示します。",
        comment: "Accessibility hint for opening Pair detail from Moment detail."
    )

    static let momentImageSection = String(
        localized: "moment_image.section",
        defaultValue: "Momentの画像",
        comment: "Accessibility label for the Moment image attachment section."
    )

    static let momentImageAdd = String(
        localized: "moment_image.add",
        defaultValue: "画像を追加",
        comment: "Action that adds a private image to a Moment."
    )

    static let momentImageOpen = String(
        localized: "moment_image.open",
        defaultValue: "画像を全画面で表示",
        comment: "Accessibility label for opening a Moment image."
    )

    static let momentImageDelete = String(
        localized: "moment_image.delete",
        defaultValue: "画像を削除",
        comment: "Destructive action that deletes a Moment image."
    )

    static let momentImageDeleteHint = String(
        localized: "moment_image.delete_hint",
        defaultValue: "長押しすると削除できます。",
        comment: "Accessibility hint for deleting a Moment image."
    )

    static let momentImageDeleteConfirmationTitle = String(
        localized: "moment_image.delete_confirmation.title",
        defaultValue: "この画像を削除しますか？",
        comment: "Title for a Moment image deletion confirmation."
    )

    static let momentImageDeleteConfirmationMessage = String(
        localized: "moment_image.delete_confirmation.message",
        defaultValue: "削除した画像は元に戻せません。",
        comment: "Message for a Moment image deletion confirmation."
    )

    static let momentImageDeleteCancel = String(
        localized: "moment_image.delete.cancel",
        defaultValue: "キャンセル",
        comment: "Cancel action for image or Moment deletion."
    )

    static let momentImageErrorTitle = String(
        localized: "moment_image.error.title",
        defaultValue: "画像を処理できませんでした",
        comment: "Title for Moment image import and storage errors."
    )

    static let momentImageErrorMessage = String(
        localized: "moment_image.error.message",
        defaultValue: "別の画像を選ぶか、時間をおいてもう一度お試しください。",
        comment: "Message for Moment image import and storage errors."
    )

    static let momentImageDeleteErrorMessage = String(
        localized: "moment_image.delete_error",
        defaultValue: "画像を削除できませんでした。もう一度お試しください。",
        comment: "Message shown when a Moment image cannot be deleted."
    )

    static let momentImageViewerClose = String(
        localized: "moment_image.viewer.close",
        defaultValue: "画像を閉じる",
        comment: "Accessibility label for closing the Moment image viewer."
    )

    static func momentImagePage(current: Int, total: Int) -> String {
        String(
            format: String(
                localized: "moment_image.viewer.page_format",
                defaultValue: "%1$d／%2$d枚目",
                comment: "Current page and total image count in the Moment image viewer."
            ),
            locale: .current,
            current,
            total
        )
    }

    static let momentEditImagesTitle = String(
        localized: "moment_edit.images.title",
        defaultValue: "5 - IMAGES",
        comment: "Section title for private Moment images in the Moment editor."
    )

    static func momentDetailMoreFromPair(_ pairName: String) -> String {
        String(
            format: String(
                localized: "moment_detail.more_from_pair_format",
                defaultValue: "More from %@",
                comment: "Subheading for additional Moments from the same Pair."
            ),
            locale: .current,
            pairName
        )
    }

    static let momentShareClose = String(
        localized: "moment_share.close",
        defaultValue: "共有画面を閉じる",
        comment: "Accessibility label for closing Moment share preview."
    )

    static let momentShareAction = String(
        localized: "moment_share.action",
        defaultValue: "Momentカードを共有",
        comment: "Accessibility label for sharing a Moment card."
    )

    static let momentShareActionHint = String(
        localized: "moment_share.action_hint",
        defaultValue: "共有先を選択します。",
        comment: "Accessibility hint for sharing a Moment card."
    )

    static let momentShareHint = String(
        localized: "moment_share.hint",
        defaultValue: "Tap to share",
        comment: "Hint below the Moment share card."
    )

    static let momentShareCustomizationTitle = String(
        localized: "moment_share.customization.title",
        defaultValue: "カードのカスタマイズ",
        comment: "Heading above the Moment share card customization controls."
    )

    static let momentShareInformationTitle = String(
        localized: "moment_share.information.title",
        defaultValue: "表示する情報",
        comment: "Title for Moment share information visibility settings."
    )

    static let momentShareShowPair = String(
        localized: "moment_share.information.pair",
        defaultValue: "Pair",
        comment: "Toggle label for Pair visibility on Moment share output."
    )

    static let momentShareShowReaction = String(
        localized: "moment_share.information.reaction",
        defaultValue: "Reaction",
        comment: "Toggle label for Reaction visibility on Moment share output."
    )

    static let momentShareShowHashtag = String(
        localized: "moment_share.information.hashtag",
        defaultValue: "Hashtag",
        comment: "Toggle label for the TouToiMoment hashtag on Moment share output."
    )

    static let momentShareCreatedWith = String(
        localized: "moment_share.created_with",
        defaultValue: "Created by TouToiMoment",
        comment: "Brand attribution shown at the bottom of a Moment share card."
    )

    static let momentShareSavePhoto = String(
        localized: "moment_share.save_photo",
        defaultValue: "写真に保存",
        comment: "Action that saves the Moment share card to Photos."
    )

    static let momentShareSavingPhoto = String(
        localized: "moment_share.saving_photo",
        defaultValue: "保存中",
        comment: "Progress label while saving a Moment share card to Photos."
    )

    static let momentShareShare = String(
        localized: "moment_share.share",
        defaultValue: "共有する",
        comment: "Action that opens the system share sheet for a Moment card."
    )

    static let momentShareSaved = String(
        localized: "moment_share.saved",
        defaultValue: "写真に保存しました",
        comment: "Confirmation shown after saving a Moment share card to Photos."
    )

    static let momentSharePhotoAccessErrorTitle = String(
        localized: "moment_share.photo_access_error.title",
        defaultValue: "写真へのアクセスが必要です",
        comment: "Title shown when add-only Photos access is unavailable."
    )

    static let momentSharePhotoAccessErrorMessage = String(
        localized: "moment_share.photo_access_error.message",
        defaultValue: "設定で写真への追加を許可してから、もう一度お試しください。",
        comment: "Message shown when add-only Photos access is unavailable."
    )

    static let momentSharePhotoSaveErrorTitle = String(
        localized: "moment_share.photo_save_error.title",
        defaultValue: "写真を保存できませんでした",
        comment: "Title shown when saving a Moment share card fails."
    )

    static let momentSharePhotoSaveErrorMessage = String(
        localized: "moment_share.photo_save_error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Message shown when saving a Moment share card fails."
    )

    static let momentShareErrorTitle = String(
        localized: "moment_share.error.title",
        defaultValue: "共有カードを作成できませんでした",
        comment: "Title shown when Moment share image rendering fails."
    )

    static let momentShareErrorMessage = String(
        localized: "moment_share.error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Message shown when Moment share image rendering fails."
    )

    static let momentShareErrorDismiss = String(
        localized: "moment_share.error.dismiss",
        defaultValue: "閉じる",
        comment: "Dismiss action for the Moment share rendering error."
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
