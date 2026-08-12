import Foundation

enum AppStrings {
    static let xConnectionUnavailableTitle = String(
        localized: "x.connection.unavailable.title",
        defaultValue: "X connection isn’t configured"
    )
    static let xConnectionUnavailableMessage = String(
        localized: "x.connection.unavailable.message",
        defaultValue: "Add the Client ID and Callback URL to enable direct account connection. You can still share through the system share sheet."
    )
    static let xShareTooLongTitle = String(
        localized: "x.share.too_long.title",
        defaultValue: "This post is too long"
    )
    static let xShareTooLongMessage = String(
        localized: "x.share.too_long.message",
        defaultValue: "Shorten the HeartScream or Auto Hashtags before sharing."
    )
    static let momentTitleOptionalLabel = String(
        localized: "moment.title.optional.label",
        defaultValue: "MOMENT TITLE (OPTIONAL)"
    )
    static let momentTitlePlaceholder = String(
        localized: "moment.title.placeholder",
        defaultValue: "Give this Moment a short title"
    )
    static let sceneNoteLabel = String(
        localized: "moment.scene_note.label",
        defaultValue: "SCENE NOTE"
    )
    static let episodeDisplayTitleLabel = String(
        localized: "episode.display_title.label",
        defaultValue: "EPISODE TITLE (OPTIONAL)"
    )
    static let episodeDisplayTitlePlaceholder = String(
        localized: "episode.display_title.placeholder",
        defaultValue: "Add a display title"
    )
    static let episodeDeleteConfirmationTitle = String(
        localized: "episode.delete.confirmation.title",
        defaultValue: "Delete this Episode?"
    )
    static let episodeDeleteConfirmationMessage = String(
        localized: "episode.delete.confirmation.message",
        defaultValue: "Watch History and unsaved Live HeartScreams will be deleted. Saved Moments remain under this Source."
    )
    static let episodeDeleteErrorTitle = String(
        localized: "episode.delete.error.title",
        defaultValue: "Couldn’t delete Episode"
    )
    static let episodeDeleteError = String(
        localized: "episode.delete.error.message",
        defaultValue: "Please try again."
    )
    static let watchHistoryDeleteConfirmationTitle = String(
        localized: "watch_history.delete.confirmation.title",
        defaultValue: "Delete this Watch History?"
    )
    static let watchHistoryDeleteConfirmationMessage = String(
        localized: "watch_history.delete.confirmation.message",
        defaultValue: "Unsaved Live HeartScreams will be removed. Saved Moments will remain."
    )
    static let watchHistoryDeleteErrorTitle = String(
        localized: "watch_history.delete.error.title",
        defaultValue: "Couldn’t delete Watch History"
    )
    static let watchHistoryDeleteError = String(
        localized: "watch_history.delete.error.message",
        defaultValue: "Please try again."
    )
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

    static let newMomentBack = String(
        localized: "new_moment.back",
        defaultValue: "戻る",
        comment: "Back action in the new moment creation flow."
    )

    static let newMomentHeartScreamTitle = String(
        localized: "new_moment.heart_scream.title",
        defaultValue: "HeartScream",
        comment: "HeartScream capture step title."
    )

    static let newMomentHeartScreamSubtitle = String(
        localized: "new_moment.heart_scream.subtitle",
        defaultValue: "感情や心の叫びを、ありのままに書きなぐりましょう。",
        comment: "HeartScream capture step guidance."
    )

    static let newMomentSceneTitle = String(
        localized: "new_moment.scene.title",
        defaultValue: "Scene Note",
        comment: "Scene capture step title."
    )

    static let newMomentSceneSubtitle = String(
        localized: "new_moment.scene.subtitle",
        defaultValue: "尊いと感じたのはどんな場面？",
        comment: "Scene capture step guidance."
    )

    static let newMomentHeartScreamCardTitle = String(
        localized: "new_moment.details.heart_scream",
        defaultValue: "HEART SCREAM",
        comment: "HeartScream preview card heading in new moment details."
    )

    static let newMomentSceneCardTitle = String(
        localized: "new_moment.details.scene",
        defaultValue: "SCENE NOTE",
        comment: "Scene preview card heading in new moment details."
    )

    static let newMomentRequiredHeartScream = String(
        localized: "new_moment.validation.heart_scream_required",
        defaultValue: "HeartScreamを入力してください。",
        comment: "Required HeartScream validation message."
    )

    static let newMomentSceneEmpty = String(
        localized: "new_moment.details.scene_empty",
        defaultValue: "未入力（任意）",
        comment: "Empty optional Scene value in new moment details."
    )

    static let newMomentEdit = String(
        localized: "new_moment.details.edit",
        defaultValue: "編集",
        comment: "Edit action on a completed capture card."
    )

    static let newMomentReactionTags = String(
        localized: "new_moment.details.reaction_tags",
        defaultValue: "REACTION TAGS",
        comment: "Reaction section heading in new moment details."
    )

    static let newMomentPairRequiredLabel = String(
        localized: "new_moment.details.pair_required",
        defaultValue: "PAIR *",
        comment: "Required Pair field label in new moment details."
    )

    static let newMomentPairRequiredError = String(
        localized: "new_moment.validation.pair_required",
        defaultValue: "Pairを選択してください。",
        comment: "Required Pair validation message."
    )

    static func newMomentThreeStepProgress(_ current: Int) -> String {
        let format = String(
            localized: "new_moment.progress.three_step",
            defaultValue: "New Momentの3ステップ中%lldつ目",
            comment: "Accessible progress label for the three-step new moment flow."
        )
        return String(format: format, locale: .current, current)
    }

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
        defaultValue: "PAIR",
        comment: "Optional field label for pair selection."
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
        defaultValue: "ペアの呼び名・ニックネーム",
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
        defaultValue: "SOURCE NAME *",
        comment: "Label for the source name field in the new source sheet."
    )

    static let newMomentStep1NewSourceNamePlaceholder = String(
        localized: "new_moment.step1.new_source_name_placeholder",
        defaultValue: "e.g. Solo Leveling",
        comment: "Placeholder for the source name field in the new source sheet."
    )

    static let newMomentStep1NewSourceMediumLabel = String(
        localized: "new_moment.step1.new_source_medium_label",
        defaultValue: "MEDIUM *",
        comment: "Label for the medium field in the new source sheet."
    )

    static let newSourceSaveError = String(
        localized: "new_source.save.error",
        defaultValue: "Sourceを保存できませんでした。もう一度お試しください。",
        comment: "Error shown when a source cannot be created."
    )

    static let editSourceTitle = String(
        localized: "source.edit.title",
        defaultValue: "Edit Source",
        comment: "Title of the source edit sheet."
    )

    static let sourceRelatedURLLabel = String(
        localized: "source.related_url.label",
        defaultValue: "関連URL *",
        comment: "Required related URL field label."
    )

    static let sourceRelatedURLPlaceholder = String(
        localized: "source.related_url.placeholder",
        defaultValue: "https://example.com",
        comment: "Placeholder for a source related URL."
    )

    static let sourceRelatedURLError = String(
        localized: "source.related_url.error",
        defaultValue: "httpまたはhttpsで始まる有効なURLを入力してください。",
        comment: "Validation error for a source related URL."
    )

    static let streamingPlatformLabel = String(
        localized: "source.streaming_platform.label",
        defaultValue: "配信媒体 *",
        comment: "Required streaming platform field label."
    )

    static let streamingPlatformOtherLabel = String(
        localized: "source.streaming_platform.other.label",
        defaultValue: "その他の配信媒体",
        comment: "Custom streaming platform field label."
    )

    static let streamingPlatformOtherPlaceholder = String(
        localized: "source.streaming_platform.other.placeholder",
        defaultValue: "配信媒体名を入力",
        comment: "Custom streaming platform field placeholder."
    )

    static let streamingPlatformOtherError = String(
        localized: "source.streaming_platform.other.error",
        defaultValue: "配信媒体名を入力してください。",
        comment: "Validation error for a custom streaming platform."
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
        defaultValue: "SCENE NOTE",
        comment: "Label for the scene note field."
    )

    static let newMomentStep3SceneSummaryPlaceholder = String(
        localized: "new_moment.step3.scene_summary_placeholder",
        defaultValue: "場面や状況を短くメモ（再会の直前）",
        comment: "Placeholder for the scene note field."
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
        defaultValue: "Scene Note または Heart Scream を入力してください。",
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
        defaultValue: "Scene Note または Heart Scream を入力してください。",
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

    static let momentMemoriesSection = String(
        localized: "moment_detail.section.memories",
        defaultValue: "Fan Memories",
        comment: "Section title for personal memory photos attached to a saved Moment."
    )

    static let momentMemoriesDescription = String(
        localized: "moment_detail.section.memories_description",
        defaultValue: "聖地巡りやグッズなど、Momentにまつわる推し活の写真を残してみよう。",
        comment: "Description encouraging users to attach fan activity photos to a Moment."
    )

    static let momentImageAdd = String(
        localized: "moment_image.add",
        defaultValue: "思い出の写真を追加",
        comment: "Action that adds a personal memory photo to a saved Moment."
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

    static let pairEditorEditTitle = String(
        localized: "pair_editor.edit.title",
        defaultValue: "Edit Pair",
        comment: "Title for the pair editing sheet."
    )

    static let pairEditorDisplayNameHelp = String(
        localized: "pair_editor.display_name.help",
        defaultValue: "ニックネームを入力すると表示名になります。未入力の場合はメンバー名を表示します。",
        comment: "Helper text explaining how a pair display name is selected."
    )

    static let pairEditorNicknameOptional = String(
        localized: "pair_editor.nickname.optional",
        defaultValue: "ニックネーム（任意）",
        comment: "Label for the optional pair nickname field."
    )

    static let pairEditorSecondColor = String(
        localized: "pair_editor.second_color",
        defaultValue: "2色目を使う",
        comment: "Toggle label for enabling a second pair color."
    )

    static let pairEditorFirstColor = String(
        localized: "pair_editor.first_color",
        defaultValue: "Member1イメージカラー",
        comment: "Label for the Member 1 image color palette."
    )

    static let pairEditorSecondaryColor = String(
        localized: "pair_editor.secondary_color",
        defaultValue: "Member2イメージカラー",
        comment: "Label for the Member 2 image color palette."
    )

    static let pairEditorPreviewPlaceholder = String(
        localized: "pair_editor.preview.placeholder",
        defaultValue: "Member1 ・ Member2",
        comment: "Placeholder pair name shown in the Pair editor preview."
    )

    static let pairEditorSaveError = String(
        localized: "pair_editor.save.error",
        defaultValue: "保存できませんでした。同じ名前のPairがないか確認して、もう一度お試しください。",
        comment: "Error shown when a pair cannot be saved."
    )

    static let pairDetailDeleteConfirmationTitle = String(
        localized: "pair_detail.delete_confirmation.title",
        defaultValue: "このPairを削除しますか？",
        comment: "Title for pair deletion confirmation."
    )

    static let pairDetailDeleteConfirmationMessage = String(
        localized: "pair_detail.delete_confirmation.message",
        defaultValue: "Momentは削除されません。MomentからこのPairの関連付けだけが外れます。",
        comment: "Message explaining pair deletion behavior."
    )

    static let pairDetailMutationError = String(
        localized: "pair_detail.mutation.error",
        defaultValue: "Pairを更新できませんでした。時間をおいて、もう一度お試しください。",
        comment: "Error shown when updating or deleting a pair fails."
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
        defaultValue: "Moments",
        comment: "Section title for moments on the pair detail screen."
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

    static let pairDetailMore = String(
        localized: "pair_detail.more",
        defaultValue: "More",
        comment: "More menu label on pair detail."
    )

    static let pairDetailDelete = String(
        localized: "pair_detail.delete",
        defaultValue: "Pairを削除",
        comment: "Delete pair action label."
    )

    static let pairDetailUnavailableMessage = String(
        localized: "pair_detail.unavailable.message",
        defaultValue: "この機能は今後のアップデートで利用できるようになります。",
        comment: "Message for pair detail actions that are not implemented yet."
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

    static let commonOK = String(
        localized: "common.ok",
        defaultValue: "OK",
        comment: "Generic confirmation button title."
    )

    static let sourcesFilterAll = String(
        localized: "sources.filter.all",
        defaultValue: "All",
        comment: "All filter title on the sources screen."
    )

    static let sourcesFilterAnime = String(
        localized: "sources.filter.anime",
        defaultValue: "Anime",
        comment: "Anime filter title on the sources screen."
    )

    static let sourcesFilterManga = String(
        localized: "sources.filter.manga",
        defaultValue: "Manga",
        comment: "Manga filter title on the sources screen."
    )

    static let sourcesFilterDrama = String(
        localized: "sources.filter.drama",
        defaultValue: "Drama",
        comment: "Drama filter title on the sources screen."
    )

    static let sourcesFilterNovel = String(
        localized: "sources.filter.novel",
        defaultValue: "Novel",
        comment: "Novel filter title on the sources screen."
    )

    static let sourcesFilterStreaming = String(
        localized: "sources.filter.streaming",
        defaultValue: "Streaming",
        comment: "Streaming filter title on the sources screen."
    )

    static let sourceListRefreshErrorMessage = String(
        localized: "sources.refresh.error",
        defaultValue: "Unable to refresh sources.",
        comment: "Error shown when refreshing the source list fails."
    )

    static let sourcesNewSource = String(
        localized: "sources.new_source",
        defaultValue: "New Source",
        comment: "New source action title."
    )

    static let sourcesOpenDetailHint = String(
        localized: "sources.open_detail_hint",
        defaultValue: "Sourceの詳細を開きます。",
        comment: "Accessibility hint for opening source detail."
    )

    static let sourcesEmptyTitle = String(
        localized: "sources.empty.title",
        defaultValue: "No Sources",
        comment: "Empty state title when no sources exist."
    )

    static let sourcesEmptyMessage = String(
        localized: "sources.empty.message",
        defaultValue: "Sources will appear here.",
        comment: "Empty state message when no sources exist."
    )

    static let sourcesFilterEmptyTitle = String(
        localized: "sources.filter_empty.title",
        defaultValue: "No Matching Sources",
        comment: "Empty state title for a source filter with no matches."
    )

    static let sourcesFilterEmptyMessage = String(
        localized: "sources.filter_empty.message",
        defaultValue: "Try another category.",
        comment: "Empty state message for a source filter with no matches."
    )

    static let sourcesLoadErrorTitle = String(
        localized: "sources.load_error.title",
        defaultValue: "Couldn't Load Sources",
        comment: "Source list loading error title."
    )

    static let sourcesLoadErrorMessage = String(
        localized: "sources.load_error.message",
        defaultValue: "Please try again.",
        comment: "Source list loading error message."
    )

    static let sourcesRetry = String(
        localized: "sources.retry",
        defaultValue: "Retry",
        comment: "Retry button title for source loading."
    )

    static let sourceDetailTitle = String(
        localized: "source_detail.title",
        defaultValue: "Source",
        comment: "Navigation title on source detail."
    )

    static let sourceDetailBack = String(
        localized: "source_detail.back",
        defaultValue: "戻る",
        comment: "Accessibility label for returning from source detail."
    )

    static let sourceDetailMore = String(
        localized: "source_detail.more",
        defaultValue: "More",
        comment: "More menu label on source detail."
    )

    static let sourceDetailEdit = String(
        localized: "source_detail.edit",
        defaultValue: "Sourceを編集",
        comment: "Edit source action label."
    )

    static let sourceDetailDelete = String(
        localized: "source_detail.delete",
        defaultValue: "Sourceを削除",
        comment: "Delete source action label."
    )

    static let sourceDetailDeleteConfirmationTitle = String(
        localized: "source_detail.delete.confirmation.title",
        defaultValue: "このSourceを削除しますか？",
        comment: "Source deletion confirmation title."
    )

    static let sourceDetailDeleteConfirmationMessage = String(
        localized: "source_detail.delete.confirmation.message",
        defaultValue: "登録済みEpisodeも削除されます。Moment本体は残ります。",
        comment: "Source deletion confirmation message."
    )

    static let sourceDetailMutationError = String(
        localized: "source_detail.mutation.error",
        defaultValue: "変更を保存できませんでした。もう一度お試しください。",
        comment: "Source edit or delete error message."
    )

    static let sourceDetailRelatedURL = String(
        localized: "source_detail.related_url",
        defaultValue: "関連URL",
        comment: "Related URL label on source detail."
    )

    static let sourceDetailAddMoment = String(
        localized: "source_detail.add_moment",
        defaultValue: "Add Moment",
        comment: "Add moment action label on source detail."
    )

    static let sourceDetailEpisodes = String(
        localized: "source_detail.episodes",
        defaultValue: "Episodes",
        comment: "Episodes section title on source detail."
    )

    static let sourceDetailMoments = String(
        localized: "source_detail.moments",
        defaultValue: "Moments",
        comment: "Direct moments section title on source detail."
    )

    static let sourceDetailOtherMoments = String(
        localized: "source_detail.moments.other",
        defaultValue: "Other Moments",
        comment: "Unassigned moments section title on source detail."
    )

    static let sourceDetailEmptyMomentsTitle = String(
        localized: "source_detail.moments.empty.title",
        defaultValue: "No Moments",
        comment: "Empty direct moments title on source detail."
    )

    static let sourceDetailEmptyMomentsMessage = String(
        localized: "source_detail.moments.empty.message",
        defaultValue: "このSourceに紐づくMomentはまだありません。",
        comment: "Empty direct moments message on source detail."
    )

    static let sourceDetailAddEpisode = String(
        localized: "source_detail.add_episode",
        defaultValue: "Add Episode",
        comment: "Add episode action label on source detail."
    )

    static let sourceDetailOpenEpisodeHint = String(
        localized: "source_detail.open_episode_hint",
        defaultValue: "Episodeの詳細を開きます。",
        comment: "Accessibility hint for opening Episode detail."
    )

    static let newEpisodeTitle = String(
        localized: "new_episode.title",
        defaultValue: "New Episode",
        comment: "New episode sheet title."
    )

    static let editEpisodeTitle = String(
        localized: "edit_episode.title",
        defaultValue: "Edit Episode",
        comment: "Edit episode sheet title."
    )

    static let newEpisodeRequirement = String(
        localized: "new_episode.requirement",
        defaultValue: "媒体に対応する番号を入力してください。",
        comment: "New episode validation guidance."
    )

    static let newEpisodeInvalidValue = String(
        localized: "new_episode.invalid_value",
        defaultValue: "有効な数字を入力してください。",
        comment: "Invalid structured episode value."
    )

    static let newEpisodeUseDate = String(
        localized: "new_episode.use_date",
        defaultValue: "配信日で登録",
        comment: "Toggle for using a date as an episode locator."
    )

    static let episodeRelatedURLLabel = String(
        localized: "new_episode.related_url.label",
        defaultValue: "関連URL（任意）",
        comment: "Optional related URL label for an episode."
    )

    static let episodeRelatedURLPlaceholder = String(
        localized: "new_episode.related_url.placeholder",
        defaultValue: "https://example.com/episode",
        comment: "Optional related URL placeholder for an episode."
    )

    static let newEpisodeSaveError = String(
        localized: "new_episode.save.error",
        defaultValue: "Episodeを保存できませんでした。もう一度お試しください。",
        comment: "New episode save error."
    )

    static let newEpisodeLoadError = String(
        localized: "new_episode.load.error",
        defaultValue: "Episodeを読み込めませんでした。",
        comment: "Episode loading error."
    )

    static let newMomentEpisodeSectionTitle = String(
        localized: "new_moment.step2.episode.title",
        defaultValue: "EPISODE",
        comment: "Episode selection section title in New Moment."
    )

    static let newMomentEpisodeNone = String(
        localized: "new_moment.step2.episode.none",
        defaultValue: "指定なし",
        comment: "No episode selection label."
    )

    static let sourceDetailEpisodeUnavailableTitle = String(
        localized: "source_detail.episode_unavailable.title",
        defaultValue: "Episode Detail",
        comment: "Unavailable episode detail feature title."
    )

    static let sourceFeatureUnavailableMessage = String(
        localized: "source_feature.unavailable.message",
        defaultValue: "This feature will be available in a future update.",
        comment: "Message shown for source actions outside the current implementation scope."
    )

    static let sourceDetailEmptyEpisodesTitle = String(
        localized: "source_detail.episodes.empty.title",
        defaultValue: "No Episodes",
        comment: "Empty episode list title on source detail."
    )

    static let sourceDetailEmptyEpisodesMessage = String(
        localized: "source_detail.episodes.empty.message",
        defaultValue: "Episodes will appear here.",
        comment: "Empty episode list message on source detail."
    )

    static let sourceDetailLoadErrorTitle = String(
        localized: "source_detail.load_error.title",
        defaultValue: "Couldn't Load Source",
        comment: "Source detail loading error title."
    )

    static let sourceDetailLoadErrorMessage = String(
        localized: "source_detail.load_error.message",
        defaultValue: "The source may no longer be available. Please try again.",
        comment: "Source detail loading error message."
    )

    static let episodeDetailTitle = String(
        localized: "episode_detail.title",
        defaultValue: "Episode",
        comment: "Episode detail navigation title."
    )

    static let episodeDetailShare = String(
        localized: "episode_detail.share",
        defaultValue: "Episodeを共有",
        comment: "Episode share accessibility label."
    )

    static let episodeDetailMore = String(
        localized: "episode_detail.more",
        defaultValue: "その他",
        comment: "More actions accessibility label on Episode detail."
    )

    static let episodeDetailEdit = String(
        localized: "episode_detail.edit",
        defaultValue: "Episodeを編集",
        comment: "Edit Episode action label."
    )

    static let episodeDetailSaveTimeline = String(
        localized: "episode_detail.timeline.save",
        defaultValue: "Timelineを保存",
        comment: "Open the Episode timeline export screen."
    )

    static let episodeTimelineExportTitle = String(
        localized: "episode_timeline_export.title",
        defaultValue: "Timelineを保存",
        comment: "Episode timeline export screen title."
    )

    static let episodeTimelineExportClose = String(
        localized: "episode_timeline_export.close",
        defaultValue: "閉じる",
        comment: "Close the Episode timeline export screen."
    )

    static let episodeTimelineExportPreparing = String(
        localized: "episode_timeline_export.preparing",
        defaultValue: "プレビューを準備中…",
        comment: "Preparing the Episode timeline export preview."
    )

    static let episodeTimelineExportPreview = String(
        localized: "episode_timeline_export.preview",
        defaultValue: "Timelineの保存プレビュー",
        comment: "Accessibility label for the Episode timeline export preview."
    )

    static let episodeTimelineExportImageFormat = String(
        localized: "episode_timeline_export.format.image",
        defaultValue: "画像",
        comment: "Image format name on Episode timeline export."
    )

    static let episodeTimelineExportPDFFormat = String(
        localized: "episode_timeline_export.format.pdf",
        defaultValue: "PDF",
        comment: "PDF format name on Episode timeline export."
    )

    static let episodeTimelineExportSaveImage = String(
        localized: "episode_timeline_export.save_image",
        defaultValue: "画像で保存",
        comment: "Save the Episode timeline as images."
    )

    static let episodeTimelineExportSavePDF = String(
        localized: "episode_timeline_export.save_pdf",
        defaultValue: "PDFで保存",
        comment: "Save the Episode timeline as a PDF."
    )

    static let episodeTimelineExportErrorTitle = String(
        localized: "episode_timeline_export.error.title",
        defaultValue: "Timelineを生成できませんでした",
        comment: "Episode timeline export rendering error title."
    )

    static let episodeTimelineExportErrorMessage = String(
        localized: "episode_timeline_export.error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Episode timeline export rendering error message."
    )

    static let episodeTimelineExportPDFSaved = String(
        localized: "episode_timeline_export.pdf_saved",
        defaultValue: "PDFを保存しました",
        comment: "Confirmation after saving an Episode timeline PDF."
    )

    static let episodeTimelineExportPDFSaveErrorTitle = String(
        localized: "episode_timeline_export.pdf_error.title",
        defaultValue: "PDFを保存できませんでした",
        comment: "Episode timeline PDF save error title."
    )

    static let episodeTimelineExportPDFSaveErrorMessage = String(
        localized: "episode_timeline_export.pdf_error.message",
        defaultValue: "保存先を確認して、もう一度お試しください。",
        comment: "Episode timeline PDF save error message."
    )

    static let episodeDetailDelete = String(
        localized: "episode_detail.delete",
        defaultValue: "Episodeを削除",
        comment: "Delete Episode action."
    )

    static let episodeDetailLoadErrorTitle = String(
        localized: "episode_detail.load_error.title",
        defaultValue: "Episodeを読み込めませんでした",
        comment: "Episode detail loading error title."
    )

    static let episodeDetailLoadErrorMessage = String(
        localized: "episode_detail.load_error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Episode detail loading error message."
    )

    static let episodeDetailRefreshErrorTitle = String(
        localized: "episode_detail.refresh_error.title",
        defaultValue: "Watch Historyを更新できませんでした",
        comment: "Episode detail refresh error title."
    )

    static let episodeDetailRefreshErrorMessage = String(
        localized: "episode_detail.refresh_error.message",
        defaultValue: "表示中の内容を残しています。もう一度お試しください。",
        comment: "Episode detail refresh error message."
    )

    static let episodeDetailMissingTitle = String(
        localized: "episode_detail.missing.title",
        defaultValue: "Episodeが見つかりません",
        comment: "Missing episode detail title."
    )

    static let episodeDetailMissingMessage = String(
        localized: "episode_detail.missing.message",
        defaultValue: "このEpisodeは削除された可能性があります。",
        comment: "Missing episode detail message."
    )

    static let episodeDetailTabPickerLabel = String(
        localized: "episode_detail.tabs.label",
        defaultValue: "Episodeの表示内容",
        comment: "Accessibility label for the Episode detail segmented picker."
    )

    static let episodeDetailMomentsTab = String(
        localized: "episode_detail.tabs.moments",
        defaultValue: "Moments",
        comment: "Moments tab on Episode detail."
    )

    static let episodeDetailWatchHistoryTab = String(
        localized: "episode_detail.tabs.watch_history",
        defaultValue: "Watch History",
        comment: "Watch History tab on Episode detail."
    )

    static let watchHistoryDetailTitle = String(
        localized: "watch_history_detail.title",
        defaultValue: "Watch History",
        comment: "Watch History detail navigation title."
    )

    static let watchHistorySaved = String(
        localized: "watch_history_detail.saved",
        defaultValue: "Watch History saved",
        comment: "Confirmation shown after a Watching Mode session is saved."
    )

    static let watchHistoryDetailShare = String(
        localized: "watch_history_detail.share",
        defaultValue: "視聴履歴を共有",
        comment: "Accessibility label for sharing a Watch History session."
    )

    static let watchHistoryDetailMore = String(
        localized: "watch_history_detail.more",
        defaultValue: "その他",
        comment: "More actions accessibility label on Watch History detail."
    )

    static let watchHistoryDetailSaveLiveLog = String(
        localized: "watch_history_detail.save_live_log",
        defaultValue: "Live Logを保存",
        comment: "Open the Live Log export screen."
    )

    static let watchHistoryDetailDelete = String(
        localized: "watch_history_detail.delete",
        defaultValue: "Historyを削除",
        comment: "Delete Watch History action."
    )

    static let watchHistoryDetailLiveLog = String(
        localized: "watch_history_detail.live_log",
        defaultValue: "Live Log",
        comment: "Live log section title on Watch History detail."
    )

    static let watchHistoryDetailLiveLogSubtitle = String(
        localized: "watch_history_detail.live_log.subtitle",
        defaultValue: "Your real-time reactions",
        comment: "Live log section subtitle on Watch History detail."
    )

    static let watchHistoryDetailMomentSaved = String(
        localized: "watch_history_detail.event.moment_saved",
        defaultValue: "Moment saved",
        comment: "Live log event indicating that a Moment was saved."
    )
    static let watchHistoryDetailSaveAsMoment = String(
        localized: "watch_history_detail.event.save_as_moment",
        defaultValue: "Save as Moment"
    )
    static let watchHistoryDetailSaveMomentError = String(
        localized: "watch_history_detail.event.save_moment_error",
        defaultValue: "Couldn’t save this Live HeartScream as a Moment."
    )

    static let watchHistoryDetailEmptyLogTitle = String(
        localized: "watch_history_detail.empty_log.title",
        defaultValue: "Live Logはありません",
        comment: "Empty Live Log title."
    )

    static let watchHistoryDetailLoadErrorTitle = String(
        localized: "watch_history_detail.load_error.title",
        defaultValue: "Watch Historyを読み込めませんでした",
        comment: "Watch History detail loading error title."
    )

    static let watchHistoryDetailLoadErrorMessage = String(
        localized: "watch_history_detail.load_error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Watch History detail loading error message."
    )

    static let watchHistoryDetailMissingTitle = String(
        localized: "watch_history_detail.missing.title",
        defaultValue: "視聴履歴が見つかりません",
        comment: "Missing Watch History detail title."
    )

    static let watchHistoryDetailMissingMessage = String(
        localized: "watch_history_detail.missing.message",
        defaultValue: "この視聴履歴は削除された可能性があります。",
        comment: "Missing Watch History detail message."
    )

    static let watchHistoryLiveLogExportTitle = String(
        localized: "watch_history_live_log_export.title",
        defaultValue: "Live Logを保存",
        comment: "Live Log export screen title."
    )

    static let watchHistoryLiveLogExportPreparing = String(
        localized: "watch_history_live_log_export.preparing",
        defaultValue: "プレビューを準備中…",
        comment: "Preparing the Live Log export preview."
    )

    static let watchHistoryLiveLogExportPreview = String(
        localized: "watch_history_live_log_export.preview",
        defaultValue: "Live Logの保存プレビュー",
        comment: "Accessibility label for the Live Log export preview."
    )

    static let watchHistoryLiveLogExportErrorTitle = String(
        localized: "watch_history_live_log_export.error.title",
        defaultValue: "Live Logを生成できませんでした",
        comment: "Live Log export rendering error title."
    )

    static let watchHistoryLiveLogExportErrorMessage = String(
        localized: "watch_history_live_log_export.error.message",
        defaultValue: "時間をおいて、もう一度お試しください。",
        comment: "Live Log export rendering error message."
    )

    static let watchHistoryLiveLogExportPDFSaved = String(
        localized: "watch_history_live_log_export.pdf_saved",
        defaultValue: "PDFを保存しました",
        comment: "Confirmation after saving a Live Log PDF."
    )

    static let watchHistoryLiveLogExportPDFSaveErrorTitle = String(
        localized: "watch_history_live_log_export.pdf_error.title",
        defaultValue: "PDFを保存できませんでした",
        comment: "Live Log PDF save error title."
    )

    static let watchHistoryLiveLogExportPDFSaveErrorMessage = String(
        localized: "watch_history_live_log_export.pdf_error.message",
        defaultValue: "保存先を確認して、もう一度お試しください。",
        comment: "Live Log PDF save error message."
    )

    static let episodeDetailTimeline = String(
        localized: "episode_detail.moments.timeline",
        defaultValue: "Timeline",
        comment: "Timeline section heading on Episode detail."
    )

    static let episodeDetailEmptyMomentsTitle = String(
        localized: "episode_detail.moments.empty.title",
        defaultValue: "Momentはまだありません",
        comment: "Empty Moments title on Episode detail."
    )

    static let episodeDetailEmptyMomentsMessage = String(
        localized: "episode_detail.moments.empty.message",
        defaultValue: "このEpisodeのMomentを残してみましょう。",
        comment: "Empty Moments message on Episode detail."
    )

    static let episodeDetailEmptyHistoryTitle = String(
        localized: "episode_detail.history.empty.title",
        defaultValue: "視聴履歴はまだありません",
        comment: "Empty Watch History title on Episode detail."
    )

    static let episodeDetailEmptyHistoryMessage = String(
        localized: "episode_detail.history.empty.message",
        defaultValue: "視聴を開始すると、ここに履歴が表示されます。",
        comment: "Empty Watch History message on Episode detail."
    )

    static let episodeDetailAddMoment = String(
        localized: "episode_detail.add_moment",
        defaultValue: "Momentを追加",
        comment: "Add Moment accessibility label on Episode detail."
    )

    static let episodeDetailStartWatching = String(
        localized: "episode_detail.start_watching",
        defaultValue: "Start Watching",
        comment: "Start Watching button title on Episode detail."
    )

    static func episodeDetailViewedCount(_ count: Int) -> String {
        let format = String(
            localized: "episode_detail.viewed_count",
            defaultValue: "Viewed %lld+",
            comment: "Episode viewing session count."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeTimelineExportSplitNotice(_ count: Int) -> String {
        let format = String(
            localized: "episode_timeline_export.split_notice",
            defaultValue: "長いTimelineのため、%lld枚の画像に分けて保存します。",
            comment: "Notice explaining that a long timeline is split into images."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeTimelineExportImageCount(_ count: Int) -> String {
        let format = String(
            localized: "episode_timeline_export.image_count",
            defaultValue: "%lld枚",
            comment: "Number of images produced by Episode timeline export."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeTimelineExportPDFCount(_ count: Int) -> String {
        let format = String(
            localized: "episode_timeline_export.pdf_count",
            defaultValue: "%lldページ",
            comment: "Number of PDF pages produced by Episode timeline export."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeTimelineExportImagesSaved(_ count: Int) -> String {
        let format = String(
            localized: "episode_timeline_export.images_saved",
            defaultValue: "%lld枚の画像を保存しました",
            comment: "Confirmation after saving Episode timeline images."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeTimelineExportPartialSave(_ count: Int) -> String {
        let format = String(
            localized: "episode_timeline_export.partial_save",
            defaultValue: "%lld枚を保存した後に処理が中断されました。",
            comment: "Partial Episode timeline image save failure message."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func watchHistoryLiveLogExportSplitNotice(_ count: Int) -> String {
        let format = String(
            localized: "watch_history_live_log_export.split_notice",
            defaultValue: "長いLive Logのため、%lld枚の画像に分けて保存します。",
            comment: "Notice explaining that a long Live Log is split into images."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func watchHistoryLiveLogExportImagesSaved(_ count: Int) -> String {
        let format = String(
            localized: "watch_history_live_log_export.images_saved",
            defaultValue: "%lld枚の画像を保存しました",
            comment: "Confirmation after saving Live Log images."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func watchHistoryLiveLogExportPartialSave(_ count: Int) -> String {
        let format = String(
            localized: "watch_history_live_log_export.partial_save",
            defaultValue: "%lld枚を保存した後に処理が中断されました。",
            comment: "Partial Live Log image save failure message."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeDetailReactionCount(_ count: Int) -> String {
        let format = count == 1
            ? String(
                localized: "episode_detail.reaction_count.one",
                defaultValue: "1 Reaction",
                comment: "Singular reaction count in Watch History."
            )
            : String(
                localized: "episode_detail.reaction_count.many",
                defaultValue: "%lld Reactions",
                comment: "Plural reaction count in Watch History."
            )
        return String.localizedStringWithFormat(format, count)
    }

    static func episodeDetailDuration(hours: Int, minutes: Int) -> String {
        let format = String(
            localized: "episode_detail.duration.hours_minutes",
            defaultValue: "%lldh %lldm",
            comment: "Watch History duration in hours and minutes."
        )
        return String.localizedStringWithFormat(format, hours, minutes)
    }

    static func episodeDetailDuration(minutes: Int) -> String {
        let format = String(
            localized: "episode_detail.duration.minutes",
            defaultValue: "%lldm",
            comment: "Watch History duration in minutes."
        )
        return String.localizedStringWithFormat(format, minutes)
    }

    static func sourcesMomentCount(_ count: Int) -> String {
        if count == 1 {
            return String(
                localized: "sources.moment_count.one",
                defaultValue: "1 Moment",
                comment: "Singular moment count on source screens."
            )
        }

        let format = String(
            localized: "sources.moment_count.many",
            defaultValue: "%lld Moments",
            comment: "Plural moment count format on source screens."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static func sourceDetailViewedCount(_ count: Int) -> String {
        let format = String(
            localized: "source_detail.viewed_count",
            defaultValue: "Viewed %lld",
            comment: "Viewed count format on an episode row."
        )
        return String.localizedStringWithFormat(format, count)
    }

    static let watchingModeTitle = String(
        localized: "watching.mode.title",
        defaultValue: "Watching Mode"
    )
    static let watchingSource = String(
        localized: "watching.source",
        defaultValue: "Source"
    )
    static let watchingEpisode = String(
        localized: "watching.episode",
        defaultValue: "Episode"
    )
    static let watchingPair = String(
        localized: "watching.pair",
        defaultValue: "Pair"
    )
    static let watchingPairOptional = String(
        localized: "watching.pair.optional",
        defaultValue: "未選択"
    )
    static let watchingXShareSetting = String(
        localized: "watching.x_share_setting",
        defaultValue: "X Share Setting"
    )
    static let watchingXConnect = String(
        localized: "watching.x_connect",
        defaultValue: "𝕏 アカウントを連携"
    )
    static let watchingAutoHashtags = String(
        localized: "watching.auto_hashtags",
        defaultValue: "Auto Hashtags"
    )
    static let watchingReady = String(
        localized: "watching.ready",
        defaultValue: "Ready"
    )
    static let watchingStart = String(
        localized: "watching.start",
        defaultValue: "Start Watching"
    )
    static let watchingFinish = String(
        localized: "watching.finish",
        defaultValue: "Finish Watching"
    )
    static let watchingPause = String(
        localized: "watching.pause",
        defaultValue: "Pause"
    )
    static let watchingResume = String(
        localized: "watching.resume",
        defaultValue: "Resume"
    )
    static let watchingNewMoment = String(
        localized: "watching.new_moment",
        defaultValue: "＋New Live HeartScream"
    )
    static let watchingMomentSheetTitle = String(
        localized: "watching.moment_sheet.title",
        defaultValue: "New Live HeartScream"
    )
    static let watchingTimestamp = String(
        localized: "watching.timestamp",
        defaultValue: "Timestamp"
    )
    static let watchingHeartScream = String(
        localized: "watching.heart_scream",
        defaultValue: "HeartScream"
    )
    static let watchingHeartScreamPlaceholder = String(
        localized: "watching.heart_scream.placeholder",
        defaultValue: "Write your HeartScream..."
    )
    static let watchingSaveMoment = String(
        localized: "watching.save_moment",
        defaultValue: "Save Moment"
    )
    static let watchingAddToLiveLog = String(
        localized: "watching.add_to_live_log",
        defaultValue: "Add Live HeartScream"
    )
    static let watchingMomentSaved = String(
        localized: "watching.moment_saved",
        defaultValue: "TouToi Moment saved"
    )
    static let watchingMomentAddedToLiveLog = String(
        localized: "watching.moment_added_to_live_log",
        defaultValue: "Live HeartScream added"
    )
    static let watchingMomentReviewTitle = String(
        localized: "watching.moment_review.title",
        defaultValue: "Save Live HeartScreams as TouToi Moments?"
    )
    static let watchingMomentReviewDescription = String(
        localized: "watching.moment_review.description",
        defaultValue: "Select the Live HeartScreams you want to register as TouToi Moments. Unselected entries will remain in this Watch History’s Live Log."
    )
    static let watchingSelectAll = String(
        localized: "watching.moment_review.select_all",
        defaultValue: "Select All"
    )
    static let watchingClearAll = String(
        localized: "watching.moment_review.clear_all",
        defaultValue: "Clear All"
    )
    static let watchingFinishWithoutMoments = String(
        localized: "watching.moment_review.finish_without_moments",
        defaultValue: "Finish without Registering TouToi Moments"
    )
    static let watchingSelected = String(
        localized: "watching.moment_review.selected",
        defaultValue: "Selected"
    )
    static let watchingNotSelected = String(
        localized: "watching.moment_review.not_selected",
        defaultValue: "Not selected"
    )
    static func watchingSaveSelectedMoments(_ count: Int) -> String {
        String(
            format: String(
                localized: "watching.moment_review.save_selected",
                defaultValue: "Register %lld as TouToi Moments and Finish"
            ),
            locale: .current,
            Int64(count)
        )
    }
    static let watchingShareOnX = String(
        localized: "watching.share_on_x",
        defaultValue: "Share on X"
    )
    static let watchingReaction = String(
        localized: "watching.reaction",
        defaultValue: "Reaction"
    )
    static let watchingFinishConfirmationTitle = String(
        localized: "watching.finish_confirmation.title",
        defaultValue: "視聴を終了しますか？"
    )
    static let watchingFinishAndSave = String(
        localized: "watching.finish_and_save",
        defaultValue: "Finish and Save"
    )
    static let watchingFinishWithoutSaving = String(
        localized: "watching.finish_without_saving",
        defaultValue: "Finish without Saving"
    )
    static let watchingHistoryNotSaved = String(
        localized: "watching.history_not_saved",
        defaultValue: "No Moments or reactions were recorded, and the session was under one minute. This session won’t be saved to Watch History."
    )
    static let watchingDiscardSession = String(
        localized: "watching.discard_session",
        defaultValue: "履歴を保存せず終了"
    )
    static let watchingKeepWatching = String(
        localized: "watching.keep_watching",
        defaultValue: "視聴を続ける"
    )
    static let watchingCancel = String(
        localized: "watching.cancel",
        defaultValue: "Cancel"
    )
    static let watchingCloseReactions = String(
        localized: "watching.close_reactions",
        defaultValue: "Close reactions"
    )
    static let watchingSaveFailed = String(
        localized: "watching.save_failed",
        defaultValue: "Watch Historyを保存できませんでした。もう一度お試しください。"
    )
    static let watchingLoadFailed = String(
        localized: "watching.load_failed",
        defaultValue: "視聴設定を読み込めませんでした。"
    )
    static let watchingSettings = String(
        localized: "watching.settings",
        defaultValue: "Session Settings"
    )
    static let momentDate = String(
        localized: "moment.date",
        defaultValue: "MOMENT DATE",
        comment: "Label for the calendar day associated with a Moment."
    )
}
