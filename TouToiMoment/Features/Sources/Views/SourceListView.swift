import SwiftUI

struct SourceListView: View {
    @StateObject private var viewModel: SourceListViewModel
    @State private var isNewSourcePresented = false

    private let onOpenSource: (String) -> Void

    init(
        repository: any SourceRepository,
        onOpenSource: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SourceListViewModel(repository: repository)
        )
        self.onOpenSource = onOpenSource
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(AppStrings.tabSources)
                    .font(AppTypography.momentsTitle())
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, 12)
                    .accessibilityIdentifier("sources.title")

                filterRow
                    .padding(.top, 16)

                content
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.refresh()
        }
        .sheet(isPresented: $isNewSourcePresented) {
            NewSourceSheet(
                saveAction: { request in
                    try await viewModel.createSource(request)
                }
            )
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SourceListFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(duration: 0.28, bounce: 0.12)) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(.custom(
                                viewModel.selectedFilter == filter
                                    ? "Geist-SemiBold"
                                    : "Geist-Medium",
                                size: 13,
                                relativeTo: .footnote
                            ))
                            .foregroundStyle(
                                viewModel.selectedFilter == filter
                                    ? Color.white
                                    : Color.appPrimarySoft
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(
                                        viewModel.selectedFilter == filter
                                            ? Color.appPrimary
                                            : Color.surfaceLight
                                    )
                                    .overlay {
                                        if viewModel.selectedFilter != filter {
                                            Capsule(style: .continuous)
                                                .stroke(Color.appPrimaryTint, lineWidth: 1)
                                        }
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sources.filter.\(filter.rawValue)")
                    .accessibilityAddTraits(
                        viewModel.selectedFilter == filter ? .isSelected : []
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("sources.loading")
        case .missing, .failed:
            SourceLoadFailureView {
                Task { await viewModel.retry() }
            }
        case .loaded:
            sourceList
        }
    }

    private var sourceList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 10) {
                Button {
                    isNewSourcePresented = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .medium))

                        Text(AppStrings.sourcesNewSource)
                            .font(.custom(
                                "Geist-Bold",
                                size: 17,
                                relativeTo: .headline
                            ))

                        Spacer()
                    }
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .glassCard(cornerRadius: 20, fillOpacity: 0.60)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sources.new_source")

                if viewModel.sources.isEmpty {
                    SourceEmptyView(
                        title: AppStrings.sourcesEmptyTitle,
                        message: AppStrings.sourcesEmptyMessage
                    )
                } else if viewModel.displayedSources.isEmpty {
                    SourceEmptyView(
                        title: AppStrings.sourcesFilterEmptyTitle,
                        message: AppStrings.sourcesFilterEmptyMessage
                    )
                } else {
                    ForEach(viewModel.displayedSources) { source in
                        SourceListRow(
                            source: source,
                            updatedText: viewModel.relativeDateText(for: source)
                        ) {
                            onOpenSource(source.id)
                        }
                        .accessibilityIdentifier("sources.card.\(source.id)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, AppTheme.Layout.bottomTabBarReservedHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SourceListRow: View {
    let source: SourceSummary
    let updatedText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                SourceThumbnailView(sourceID: source.id)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 6) {
                    Text(source.displayName)
                        .font(.custom(
                            "Geist-Bold",
                            size: 16,
                            relativeTo: .body
                        ))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(source.contextualHelperText)
                            .font(.custom(
                                "Geist-Bold",
                                size: 10,
                                relativeTo: .caption2
                            ))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.surfaceLight, in: RoundedRectangle(
                                cornerRadius: 6,
                                style: .continuous
                            ))

                        MomentCountPill(count: source.momentCount)
                        Text(updatedText)
                    }
                    .font(.custom(
                        "Geist-Regular",
                        size: 12,
                        relativeTo: .caption
                    ))
                    .foregroundStyle(Color(hex: "#9B9EC4"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "#C7B7FF"))
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92)
            .contentShape(Rectangle())
            .glassCard(cornerRadius: 20, fillOpacity: 0.40)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(AppStrings.sourcesOpenDetailHint)
    }
}

private struct SourceLoadFailureView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(AppStrings.sourcesLoadErrorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(AppStrings.sourcesLoadErrorMessage)
        } actions: {
            Button(AppStrings.sourcesRetry, action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.appPrimary)
        }
        .accessibilityIdentifier("sources.load_error")
    }
}

private struct SourceEmptyView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "books.vertical",
            description: Text(message)
        )
        .accessibilityIdentifier("sources.empty")
    }
}

#Preview {
    SourceListView(
        repository: InMemorySourceRepository(),
        onOpenSource: { _ in }
    )
}
