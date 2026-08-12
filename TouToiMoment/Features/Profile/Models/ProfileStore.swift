import Foundation
import Combine

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profile: UserProfile
    private let repository: any ProfileRepository

    init(repository: any ProfileRepository) {
        self.repository = repository
        profile = (try? repository.loadProfile()) ?? .initial()
    }

    func reloadFromPersistence() throws {
        profile = try repository.loadProfile()
    }

    @discardableResult
    func update(nickname: String, avatarColor: AvatarColorSelection) -> Bool {
        var updated = profile
        let normalizedNickname = ProfileNicknamePolicy.normalized(nickname)
        updated.nickname = normalizedNickname.isEmpty ? "Comado" : normalizedNickname
        updated.avatarColor = avatarColor
        updated.updatedAt = .now

        do {
            try repository.saveProfile(updated)
            profile = updated
            return true
        } catch {
            return false
        }
    }
}
