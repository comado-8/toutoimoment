import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EditProfileView: View {
    @ObservedObject var profileStore: ProfileStore
    let onBack: () -> Void

    @State private var nickname: String
    @State private var avatarColor: AvatarColorSelection
    @State private var showsSaveError = false
    @State private var showsCopiedConfirmation = false

    init(profileStore: ProfileStore, onBack: @escaping () -> Void) {
        self.profileStore = profileStore
        self.onBack = onBack
        _nickname = State(initialValue: profileStore.profile.nickname)
        _avatarColor = State(initialValue: profileStore.profile.avatarColor)
    }

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            ScrollView {
                VStack(spacing: 0) {
                    ProfileScreenHeader(title: AppStrings.profileEdit, onBack: onBack) {
                        Button(AppStrings.profileSave, action: save)
                            .font(.custom("Geist-SemiBold", size: 15, relativeTo: .subheadline))
                            .foregroundStyle(Color.appPrimary)
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("profile.edit.save")
                    }

                    content
                }
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Couldn’t Save Profile", isPresented: $showsSaveError) {
            Button("OK", role: .cancel) {}
        }
        .alert("User ID Copied", isPresented: $showsCopiedConfirmation) {
            Button("OK", role: .cancel) {}
        }
        .accessibilityIdentifier("profile.edit.screen")
    }

    private var content: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                ProfileAvatarView(color: avatarColor, size: 80)
                    .overlay(Circle().stroke(.white, lineWidth: 3))

                VStack(alignment: .leading, spacing: 12) {
                    SettingsSectionLabel(title: AppStrings.profileAvatarColor)

                    HStack(spacing: 0) {
                        ForEach(AvatarColorSelection.allCases) { color in
                            avatarColorButton(color)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            labeledField(title: AppStrings.profileNickname) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(AppStrings.profileNickname, text: $nickname)
                        .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                        .textInputAutocapitalization(.words)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .accessibilityIdentifier("profile.edit.nickname")
                        .onChange(of: nickname) { _, value in
                            let limited = ProfileNicknamePolicy.limited(value)
                            if limited != value { nickname = limited }
                        }

                    Text(AppStrings.profileNicknameInputNote)
                        .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionLabel(title: AppStrings.profileUserID)

                HStack(spacing: 12) {
                    Text(profileStore.profile.localUserID)
                        .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                        .foregroundStyle(Color.textPrimary)
                        .textSelection(.enabled)

                    Spacer()

                    Button(AppStrings.profileCopy, action: copyUserID)
                        .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 8))
                        .tint(Color.appPrimary)
                        .accessibilityIdentifier("profile.edit.copy_id")
                }
                .padding(16)
                .glassCard(cornerRadius: 20, fillOpacity: 0.4)

                Text("Used as your local identifier for future social features.")
                    .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 48)
    }

    private func labeledField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionLabel(title: title)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 20, fillOpacity: 0.4)
        }
    }

    private func avatarColorButton(_ color: AvatarColorSelection) -> some View {
        Button {
            avatarColor = color
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.color)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .padding(3)
                    .overlay {
                        if color == avatarColor {
                            Circle().stroke(Color.appPrimary, lineWidth: 2)
                        }
                    }

                Text(color.displayName)
                    .font(.custom("Geist-Regular", size: 10, relativeTo: .caption2))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.displayName)
        .accessibilityAddTraits(color == avatarColor ? .isSelected : [])
    }

    private func save() {
        if profileStore.update(nickname: nickname, avatarColor: avatarColor) {
            onBack()
        } else {
            showsSaveError = true
        }
    }

    private func copyUserID() {
        #if canImport(UIKit)
        UIPasteboard.general.string = profileStore.profile.localUserID
        #endif
        showsCopiedConfirmation = true
    }
}
