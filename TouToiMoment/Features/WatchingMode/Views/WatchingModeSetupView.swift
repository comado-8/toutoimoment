import SwiftUI

struct WatchingModeSetupView: View {
    @StateObject private var viewModel: WatchingModeSetupViewModel
    @State private var isXConfigurationAlertPresented = false

    private let locksSourceAndEpisode: Bool
    let onReady: (WatchingModeSelection) -> Void
    let onClose: () -> Void

    init(
        sourceID: String,
        episodeID: String,
        pairID: String? = nil,
        autoHashtags: String = "#TouToiMoment",
        locksSourceAndEpisode: Bool = false,
        sourceRepository: any SourceRepository,
        pairRepository: any PairRepository,
        onReady: @escaping (WatchingModeSelection) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: WatchingModeSetupViewModel(
                sourceID: sourceID,
                episodeID: episodeID,
                pairID: pairID,
                autoHashtags: autoHashtags,
                sourceRepository: sourceRepository,
                pairRepository: pairRepository
            )
        )
        self.locksSourceAndEpisode = locksSourceAndEpisode
        self.onReady = onReady
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()
                .opacity(0.72)

            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .accessibilityIdentifier("watching_setup.view")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .tint(Color.appPrimary)
        case .failed:
            ContentUnavailableView {
                Label(AppStrings.watchingLoadFailed, systemImage: "exclamationmark.triangle")
            } actions: {
                Button(AppStrings.sourcesRetry) {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .loaded:
            setupForm
        }
    }

    private var setupForm: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.white.opacity(0.68))
                .foregroundStyle(Color.appPrimary)
                .accessibilityIdentifier("watching_setup.close")
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 7) {
                        Text(AppStrings.watchingModeTitle)
                            .font(.custom("InstrumentSerif-Regular", size: 20, relativeTo: .title3))
                        Text("Setup Session")
                            .font(.custom("InstrumentSerif-Regular", size: 40, relativeTo: .largeTitle))
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.2))
                            .frame(width: 184, height: 2)
                    }
                    .foregroundStyle(Color.appPrimary)

                    VStack(spacing: 16) {
                        setupPicker(
                            title: AppStrings.watchingSource,
                            selection: Binding(
                                get: { viewModel.selectedSourceID ?? "" },
                                set: { id in Task { await viewModel.selectSource(id) } }
                            ),
                            options: viewModel.sources.map { ($0.id, $0.displayName) },
                            identifier: "watching_setup.source",
                            isEnabled: !locksSourceAndEpisode
                        )

                        setupPicker(
                            title: AppStrings.watchingEpisode,
                            selection: Binding(
                                get: { viewModel.selectedEpisodeID ?? "" },
                                set: { viewModel.selectedEpisodeID = $0 }
                            ),
                            options: episodeOptions,
                            identifier: "watching_setup.episode",
                            isEnabled: !locksSourceAndEpisode
                        )

                        setupPicker(
                            title: AppStrings.watchingPair,
                            selection: Binding(
                                get: { viewModel.selectedPairID ?? "" },
                                set: { viewModel.selectedPairID = $0.isEmpty ? nil : $0 }
                            ),
                            options: [("", AppStrings.watchingPairOptional)]
                                + viewModel.pairs.map { ($0.id, $0.displayName) },
                            identifier: "watching_setup.pair"
                        )
                    }

                    Rectangle()
                        .fill(Color.appPrimary.opacity(0.12))
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(AppStrings.watchingXShareSetting.uppercased())
                                .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
                                .foregroundStyle(Color.appPrimarySoft)
                            Spacer()
                            Button {
                                isXConfigurationAlertPresented = true
                            } label: {
                                Text("𝕏 アカウントを連携")
                                    .font(.custom("Geist-SemiBold", size: 11, relativeTo: .caption2))
                                    .foregroundStyle(Color.appPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .overlay(Capsule().stroke(Color.appPrimary, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("watching_setup.x_connect")
                        }

                        Text(AppStrings.watchingAutoHashtags.uppercased())
                            .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.appPrimarySoft)

                        TextField("#TouToiMoment", text: $viewModel.autoHashtags)
                            .font(.custom("Geist-Regular", size: 17, relativeTo: .body))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 18)
                            .frame(height: 48)
                            .glassCard(cornerRadius: 15)
                            .accessibilityIdentifier("watching_setup.hashtags")
                    }

                    Button {
                        if let selection = viewModel.selection() {
                            onReady(selection)
                        }
                    } label: {
                        Text(AppStrings.watchingReady)
                            .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(
                                LinearGradient(
                                    stops: [
                                        .init(color: .appPrimary, location: 0),
                                        .init(color: Color(hex: "#8B70F0"), location: 0.5),
                                        .init(color: .appAccent, location: 1),
                                    ],
                                    startPoint: UnitPoint(x: 0.53, y: -0.98),
                                    endPoint: UnitPoint(x: 0.58, y: 1.78)
                                ),
                                in: Capsule()
                            )
                            .overlay(Capsule().stroke(.white, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canContinue)
                    .opacity(viewModel.canContinue ? 1 : 0.45)
                    .shadow(color: Color.appPrimary.opacity(0.25), radius: 12, y: 12)
                    .accessibilityIdentifier("watching_setup.ready")
                }
                .padding(.horizontal, 35)
                .padding(.top, 4)
                .padding(.bottom, 36)
            }
        }
        .alert(
            AppStrings.xConnectionUnavailableTitle,
            isPresented: $isXConfigurationAlertPresented
        ) {
            Button(AppStrings.commonOK, role: .cancel) {}
        } message: {
            Text(AppStrings.xConnectionUnavailableMessage)
        }
    }

    private var episodeOptions: [(String, String)] {
        guard let source = viewModel.selectedSource else { return [] }
        let schema = SourceLocatorSchema.schema(for: source.mediaType)
            ?? SourceLocatorSchema.fallback
        return viewModel.episodes.map { episode in
            (episode.id, schema.episodeDisplayName(for: episode.locatorValues))
        }
    }

    private func setupPicker(
        title: String,
        selection: Binding<String>,
        options: [(String, String)],
        identifier: String,
        isEnabled: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
                .foregroundStyle(Color.appPrimarySoft)

            Picker(title, selection: selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.appPrimary)
            .font(.custom("Geist-Regular", size: 17, relativeTo: .body))
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .padding(.horizontal, 18)
            .glassCard(cornerRadius: 20)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.72)
            .accessibilityIdentifier(identifier)
        }
    }
}
