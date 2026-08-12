import Foundation
import Testing
@testable import TouToiMoment

struct UserInputPolicyTests {
    @Test func expressiveTextAllowsEmojiAndCountsAJoinedEmojiAsOneCharacter() {
        let family = "👨‍👩‍👧‍👦"
        let input = String(repeating: "あ", count: 999) + family + "末"

        let heart = HeartScreamTextPolicy.limited(input)

        #expect(heart.count == 1_000)
        #expect(heart.hasSuffix(family))
    }

    @Test func sanitizerRemovesControlAndBidirectionalOverrideCharacters() {
        let input = "safe\u{0000}\u{202E}text\tend"

        #expect(SourceNamePolicy.limited(input) == "safetext end")
    }

    @Test func allPrimaryMomentTextLimitsAreEnforcedAtTheirSetters() {
        var draft = NewMomentDraft()
        draft.updateMomentTitle(String(repeating: "T", count: 21))
        draft.updateSceneSummary(String(repeating: "S", count: 1_001))
        draft.updateHeartScream(String(repeating: "H", count: 1_001))

        #expect(draft.momentTitle.count == 20)
        #expect(draft.sceneSummary.count == 1_000)
        #expect(draft.heartScream.count == 1_000)
        #expect(draft.isWithinTextLimits)
    }

    @Test func existingOverLimitTextIsPreservedUntilTheUserEditsIt() {
        let legacy = String(repeating: "旧", count: 1_001)
        var draft = NewMomentDraft(heartScream: legacy)

        #expect(draft.heartScream == legacy)
        #expect(!draft.isWithinTextLimits)

        draft.updateHeartScream(legacy)
        #expect(draft.heartScream.count == 1_000)
        #expect(draft.isWithinTextLimits)
    }

    @Test func URLPolicyRejectsOversizeCredentialsAndUnsupportedSchemes() {
        #expect(SourceRelatedURLPolicy.normalizedURL(from: "https://example.com/path") != nil)
        #expect(SourceRelatedURLPolicy.normalizedURL(from: "https://user:pass@example.com") == nil)
        #expect(SourceRelatedURLPolicy.normalizedURL(from: "javascript:alert(1)") == nil)
        #expect(
            SourceRelatedURLPolicy.normalizedURL(
                from: "https://example.com/" + String(repeating: "a", count: 2_100)
            ) == nil
        )
    }

    @Test func hashtagPolicyRejectsEmojiAndCapsTagCountAndLength() {
        let valid = (1...12).map { "#tag\($0)" }.joined(separator: " ")
        let result = AutoHashtagPolicy.normalizedTags(
            valid + " #tag1 #推し活 #尊い🥰 #" + String(repeating: "a", count: 51)
        )

        #expect(result.count == 10)
        #expect(Set(result).count == result.count)
        #expect(!result.contains(where: { $0.contains("🥰") }))
    }

    @Test func searchAndNamesHaveDefensiveLimitsWhileAllowingEmoji() {
        #expect(MomentSearchQueryPolicy.limited(String(repeating: "q", count: 101)).count == 100)
        #expect(SourceNamePolicy.limited("推し作品🥰").contains("🥰"))
        #expect(PairTextPolicy.limitedMember(String(repeating: "a", count: 51)).count == 50)
        #expect(PairTextPolicy.limitedDisplayName(String(repeating: "a", count: 101)).count == 100)
    }

    @Test func profileNicknameAllowsEnglishLettersAndHalfWidthSymbolsOnly() {
        let input = " Yumiko-_.!123 日本語 émoji🥰 "

        #expect(ProfileNicknamePolicy.limited(input) == " Yumiko-_.!  moji ")
        #expect(ProfileNicknamePolicy.normalized(input) == "Yumiko-_.!  moji")
        #expect(
            ProfileNicknamePolicy.limited(String(repeating: "A", count: 101)).count == 100
        )
    }
}
