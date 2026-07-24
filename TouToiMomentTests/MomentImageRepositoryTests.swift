import Testing
import UIKit
@testable import TouToiMoment

@MainActor
struct MomentImageRepositoryTests {
    @Test func localRepositoryResizesPersistsOrdersAndEnforcesThreeImageLimit() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalMomentImageRepository(rootURL: root)
        let data = makeImageData(width: 3_000, height: 1_000)

        for index in 0..<3 {
            let images = try await repository.addImage(
                data: data,
                id: "image-\(index)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                to: "moment-a"
            )
            #expect(images.count == index + 1)
        }

        let reloadedRepository = LocalMomentImageRepository(rootURL: root)
        let reloaded = try await reloadedRepository.images(for: "moment-a")
        #expect(reloaded.map(\.id) == ["image-0", "image-1", "image-2"])
        #expect(reloaded.map(\.order) == [0, 1, 2])
        #expect(reloaded.allSatisfy { max($0.pixelWidth, $0.pixelHeight) <= 2_048 })

        await #expect(throws: MomentImageRepositoryError.limitExceeded) {
            try await repository.addImage(
                data: data,
                id: "image-3",
                createdAt: Date(),
                to: "moment-a"
            )
        }
    }

    @Test func localRepositoryCommitsEditChangesAndRemovesOrphans() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalMomentImageRepository(rootURL: root)
        let data = makeImageData(width: 800, height: 600)

        _ = try await repository.addImage(
            data: data,
            id: "keep",
            createdAt: Date(timeIntervalSince1970: 1),
            to: "valid"
        )
        _ = try await repository.addImage(
            data: data,
            id: "remove",
            createdAt: Date(timeIntervalSince1970: 2),
            to: "valid"
        )
        _ = try await repository.addImage(
            data: data,
            id: "orphan",
            createdAt: Date(),
            to: "orphan-moment"
        )

        let committed = try await repository.commit(
            MomentImageChangeSet(
                retainedImageIDs: ["keep"],
                additions: [
                    .init(
                        id: "new",
                        data: data,
                        createdAt: Date(timeIntervalSince1970: 3)
                    )
                ]
            ),
            for: "valid"
        )

        #expect(committed.map(\.id) == ["keep", "new"])
        #expect(committed.map(\.order) == [0, 1])

        try await repository.removeOrphans(validMomentIDs: ["valid"])
        #expect(try await repository.images(for: "orphan-moment").isEmpty)
        #expect(try await repository.images(for: "valid").map(\.id) == ["keep", "new"])
    }

    @Test func editViewModelStagesImagesUntilAChangeSetIsCommitted() {
        var moment = MomentCardModel.preview[0]
        moment.images = [
            MomentImage(
                id: "existing",
                relativeFileName: "existing.heic",
                createdAt: Date(),
                order: 0,
                pixelWidth: 1_000,
                pixelHeight: 800
            )
        ]
        let viewModel = MomentEditViewModel(
            moment: moment,
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository()
        )

        #expect(!viewModel.hasImageChanges)
        #expect(viewModel.addImage(data: makeImageData(width: 40, height: 40)))
        #expect(viewModel.hasImageChanges)
        #expect(viewModel.imageChangeSet.retainedImageIDs == ["existing"])
        #expect(viewModel.imageChangeSet.additions.count == 1)

        viewModel.removeImage(id: "existing")
        #expect(viewModel.imageChangeSet.retainedImageIDs.isEmpty)
    }

    @Test func deletingAMomentRemovesItsPrivateImagesBeforeTheModel() async throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalMomentImageRepository(rootURL: root)
        let moment = MomentCardModel.preview[0]
        let store = MomentStore(moments: [moment], imageRepository: repository)

        _ = try await store.addImage(
            data: makeImageData(width: 800, height: 600),
            to: moment.id
        )
        #expect(store.moment(id: moment.id)?.images.count == 1)

        #expect(try await store.delete(id: moment.id))
        #expect(store.moment(id: moment.id) == nil)
        #expect(try await repository.images(for: moment.id).isEmpty)
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MomentImageTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeImageData(width: Int, height: Int) -> Data {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height)
        )
        return renderer.jpegData(withCompressionQuality: 0.95) { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
