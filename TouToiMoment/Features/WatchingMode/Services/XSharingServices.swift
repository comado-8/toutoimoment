import Foundation
import SwiftUI
import UIKit

struct XShareDraft: Identifiable {
    let id = UUID()
    let body: String
    let hashtags: [String]
    let attachment: UIImage?

    init(body: String, autoHashtags: String, attachment: UIImage? = nil) {
        self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.hashtags = Self.normalizedHashtags(autoHashtags)
        self.attachment = attachment
    }

    var text: String {
        ([body] + hashtags).filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    var exceedsRecommendedLength: Bool {
        text.count > 280
    }

    var activityItems: [Any] {
        attachment.map { [text, $0] } ?? [text]
    }

    static func normalizedHashtags(_ rawValue: String) -> [String] {
        AutoHashtagPolicy.normalizedTags(rawValue)
    }
}

struct SystemActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

protocol XAuthenticationService {
    var isConfigured: Bool { get }
    func authenticate() async throws
}

protocol XPostingService {
    var isConfigured: Bool { get }
    func post(_ draft: XShareDraft) async throws
}

struct XServiceConfiguration {
    let clientID: String?
    let callbackURL: URL?

    static var appConfiguration: XServiceConfiguration {
        let dictionary = Bundle.main.infoDictionary
        return XServiceConfiguration(
            clientID: dictionary?["XClientID"] as? String,
            callbackURL: (dictionary?["XCallbackURL"] as? String).flatMap(URL.init(string:))
        )
    }

    var isConfigured: Bool {
        clientID?.isEmpty == false && callbackURL != nil
    }
}
