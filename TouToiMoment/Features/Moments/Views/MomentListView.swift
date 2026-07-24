import SwiftUI

private enum MomentListLayout {
    static let floatingButtonTrailingInset: CGFloat = 24
    static let floatingButtonBottomInset: CGFloat = 96
    static let scrollBottomPadding: CGFloat = 184
}

struct MomentListView: View {
    @ObservedObject private var store: MomentStore
    @StateObject private var viewModel: MomentListViewModel
    var onCreateMoment: () -> Void
    var onOpenMoment: (String) -> Void

    init(
        store: MomentStore,
        onCreateMoment: @escaping () -> Void = {},
        onOpenMoment: @escaping (String) -> Void = { _ in }
    ) {
        _store = ObservedObject(wrappedValue: store)
        _viewModel = StateObject(
            wrappedValue: MomentListViewModel(store: store)
        )
        self.onCreateMoment = onCreateMoment
        self.onOpenMoment = onOpenMoment
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 12)

            searchAndFaceControls
                .padding(.horizontal, 16)
                .padding(.top, 8)

            filters
                .padding(.top, 6)

            ScrollView(.vertical, showsIndicators: true) {
                if viewModel.displayedMoments.isEmpty {
                    emptyState
                } else {
                    momentGrid
                }
            }
            .accessibilityIdentifier("moments.scroll")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .bottomTrailing) {
            addMomentButton
                .padding(.trailing, MomentListLayout.floatingButtonTrailingInset)
                .padding(.bottom, MomentListLayout.floatingButtonBottomInset)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(AppStrings.tabMoments)
                .font(AppTypography.momentsTitle())
                .foregroundStyle(Color.textPrimary)
                .accessibilityIdentifier("moments.title")

            Spacer(minLength: 0)
        }
        .frame(height: 48)
    }

    private var searchAndFaceControls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)

                TextField(
                    AppStrings.momentsSearchPlaceholder,
                    text: $viewModel.filter.query
                )
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("moments.search")
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.appPrimaryTint, lineWidth: 1)
            }

            faceToggle
                .frame(width: 106, height: 32)
        }
    }

    private var faceToggle: some View {
        HStack(spacing: 0) {
            faceToggleButton(.scene)
            faceToggleButton(.heart)
        }
        .padding(2)
        .background(Color.white.opacity(0.72), in: Capsule(style: .continuous))
        .shadow(color: Color(hex: "#7C6FCD", opacity: 0.12), radius: 4, y: 2)
        .accessibilityElement(children: .contain)
    }

    private func faceToggleButton(_ face: MomentFace) -> some View {
        let isSelected = viewModel.selectedGlobalFace == face
        let selectedColor = face == .scene ? Color.appPrimary : Color.sceneHeart

        return Button {
            viewModel.setAllFaces(face)
        } label: {
            Text(face == .scene ? AppStrings.momentsScene : AppStrings.momentsHeart)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : Color.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(selectedColor)
                            .shadow(color: selectedColor.opacity(0.12), radius: 1.5, y: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("moments.face.\(face.rawValue)")
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MomentFilterChip(
                    title: AppStrings.momentsFilterAll,
                    isSelected: !viewModel.filter.hasActiveSelection
                ) {
                    viewModel.resetSelections()
                }
                .accessibilityIdentifier("moments.filter.all")

                MomentFilterChip(
                    title: AppStrings.momentsFilterStar,
                    isSelected: viewModel.filter.favoritesOnly,
                    showsStar: true
                ) {
                    viewModel.filter.favoritesOnly.toggle()
                }
                .accessibilityIdentifier("moments.filter.star")

                MomentFilterMenu(
                    title: AppStrings.momentsFilterPair,
                    options: viewModel.pairOptions,
                    selection: $viewModel.filter.selectedPairID
                )

                MomentFilterMenu(
                    title: AppStrings.momentsFilterSource,
                    options: viewModel.sourceOptions,
                    selection: $viewModel.filter.selectedSourceID
                )

                MomentFilterMenu(
                    title: AppStrings.momentsFilterReaction,
                    options: viewModel.reactionOptions,
                    selection: $viewModel.filter.selectedReactionID
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .accessibilityIdentifier("moments.filters")
    }

    private var momentGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(viewModel.displayedMoments) { moment in
                MomentCard(
                    model: moment,
                    layout: .momentGrid,
                    face: faceBinding(for: moment.id),
                    onToggleFavorite: {
                        store.toggleFavorite(id: moment.id)
                    },
                    onOpen: { onOpenMoment(moment.id) }
                )
                .accessibilityIdentifier("moments.card.\(moment.id)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, MomentListLayout.scrollBottomPadding)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            AppStrings.momentsEmptyTitle,
            systemImage: "magnifyingglass"
        )
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .accessibilityIdentifier("moments.empty")
    }

    private var addMomentButton: some View {
        Button(action: onCreateMoment) {
            MomentSparkleIcon(color: .white, width: 18, height: 28)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.extraLarge)
        .tint(Color.appPrimary)
        .accessibilityLabel(AppStrings.momentsAddMoment)
        .accessibilityIdentifier("moments.add")
    }

    private func faceBinding(for momentID: String) -> Binding<MomentFace> {
        Binding(
            get: { viewModel.face(for: momentID) },
            set: { viewModel.setFace($0, for: momentID) }
        )
    }
}

private struct MomentFilterChip: View {
    let title: String
    let isSelected: Bool
    var showsStar = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if showsStar {
                    FavoriteStarIcon(
                        variant: isSelected ? .on : .default,
                        width: 16,
                        height: 16
                    )
                }

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.white : Color.appPrimarySoft)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.appPrimary)
                } else {
                    Capsule(style: .continuous)
                        .fill(Color.surfaceLight.opacity(0.92))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.appPrimaryTint, lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct MomentFilterMenu: View {
    let title: String
    let options: [MomentFilterOption]
    @Binding var selection: String?

    var body: some View {
        Menu {
            Button(AppStrings.momentsFilterAny) {
                setSelection(nil)
            }

            ForEach(options) { option in
                Button {
                    setSelection(option.id)
                } label: {
                    if selection == option.id {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: "triangle.fill")
                    .font(.system(size: 6, weight: .bold))
                    .rotationEffect(.degrees(180))
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.appPrimarySoft)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(
                Capsule(style: .continuous)
                    .fill(selection == nil ? Color.surfaceLight.opacity(0.92) : Color.white.opacity(0.86))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(
                                selection == nil ? Color.appPrimaryTint : Color.appPrimary,
                                lineWidth: 1
                            )
                    }
            )
        }
        .accessibilityLabel(title)
        .accessibilityValue(selectedLabel ?? AppStrings.momentsFilterAny)
    }

    private var selectedLabel: String? {
        options.first(where: { $0.id == selection })?.label
    }

    private func setSelection(_ id: String?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selection = id
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        MomentListView(store: MomentStore())

        BottomTabBar(selectedTab: .constant(.moments))
            .padding(.bottom, 8)
    }
}
