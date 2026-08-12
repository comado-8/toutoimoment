import SwiftUI

struct ManualBackupPassphraseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let submitTitle: String
    let requiresConfirmation: Bool
    let isProcessing: Bool
    let onSubmit: (String, String) -> Void

    @State private var passphrase = ""
    @State private var confirmation = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case passphrase
        case confirmation
    }

    private var canSubmit: Bool {
        passphrase.count >= ManualBackupPassphrasePolicy.minimumLength
            && (!requiresConfirmation || passphrase == confirmation)
            && !isProcessing
    }

    private var validationMessage: String? {
        if !passphrase.isEmpty,
           passphrase.count < ManualBackupPassphrasePolicy.minimumLength {
            return "パスフレーズは\(ManualBackupPassphrasePolicy.minimumLength)文字以上で入力してください。"
        }
        if requiresConfirmation,
           !confirmation.isEmpty,
           passphrase != confirmation {
            return "確認用パスフレーズが一致しません。"
        }
        return nil
    }

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            VStack(spacing: 0) {
                ManualBackupScreenHeader(title: title, isDisabled: isProcessing) {
                    focusedField = nil
                    dismiss()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        introduction
                        passphraseFields
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .safeAreaInset(edge: .bottom) {
            submitButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
        }
        .interactiveDismissDisabled(isProcessing)
        .onAppear { focusedField = .passphrase }
        .accessibilityAddTraits(.isModal)
    }

    private var introduction: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.11))
                    .frame(width: 72, height: 72)
                Image(systemName: requiresConfirmation ? "archivebox.fill" : "lock.open.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(spacing: 8) {
                Text(requiresConfirmation ? "大切な記録を、安全に保存" : "バックアップを開く")
                    .font(AppTypography.titleMedium())
                    .foregroundStyle(Color.textPrimary)

                Text(message)
                    .font(.custom("Geist-Regular", size: 14, relativeTo: .body))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                securityNote(
                    icon: "checkmark.shield.fill",
                    text: "8文字以上、12文字以上をおすすめします",
                    tint: Color.appPrimary
                )
                if requiresConfirmation {
                    securityNote(
                        icon: "exclamationmark.triangle.fill",
                        text: "忘れたパスフレーズは復元できません",
                        tint: Color(hex: "#D97706")
                    )
                } else {
                    securityNote(
                        icon: "doc.badge.gearshape.fill",
                        text: "バックアップ作成時と同じものを入力してください",
                        tint: Color.appPrimary
                    )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 20, fillOpacity: 0.5)
        }
    }

    private var passphraseFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: "パスフレーズ")

            VStack(spacing: 0) {
                secureField(
                    title: "パスフレーズ",
                    prompt: "8文字以上",
                    text: $passphrase,
                    field: .passphrase,
                    submitLabel: requiresConfirmation ? .next : .done
                ) {
                    focusedField = requiresConfirmation ? .confirmation : nil
                }

                if requiresConfirmation {
                    SettingsDivider(leadingInset: 16)
                    secureField(
                        title: "確認用パスフレーズ",
                        prompt: "もう一度入力",
                        text: $confirmation,
                        field: .confirmation,
                        submitLabel: .done
                    ) {
                        focusedField = nil
                    }
                }
            }
            .glassCard(cornerRadius: 20, fillOpacity: 0.52)

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
    }

    private func secureField(
        title: String,
        prompt: String,
        text: Binding<String>,
        field: Field,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)

            SecureField(prompt, text: text)
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .textContentType(requiresConfirmation ? .newPassword : .password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(submitLabel)
                .focused($focusedField, equals: field)
                .onSubmit(onSubmit)
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
    }

    private func securityNote(icon: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(text)
                .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var submitButton: some View {
        Button {
            focusedField = nil
            onSubmit(passphrase, confirmation)
        } label: {
            HStack(spacing: 10) {
                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: requiresConfirmation ? "square.and.arrow.down" : "checkmark.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(isProcessing ? "処理中…" : submitTitle)
                    .font(AppTypography.cta())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.appPrimary)
                    .shadow(color: Color.appPrimary.opacity(canSubmit ? 0.24 : 0), radius: 14, y: 8)
            )
            .opacity(canSubmit ? 1 : 0.38)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }
}

struct ManualRestoreConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: ManualBackupPreview
    let isRestoring: Bool
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            VStack(spacing: 0) {
                ManualBackupScreenHeader(title: "復元内容を確認", isDisabled: isRestoring) {
                    dismiss()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        restoreIntroduction
                        backupContents
                        replacementWarning
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            restoreButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
        }
        .interactiveDismissDisabled(isRestoring)
        .accessibilityAddTraits(.isModal)
    }

    private var restoreIntroduction: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.11))
                    .frame(width: 72, height: 72)
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }
            Text("このバックアップで復元しますか？")
                .font(AppTypography.titleMedium())
                .foregroundStyle(Color.textPrimary)
            Text("内容を確認してから復元を開始してください。")
                .font(.custom("Geist-Regular", size: 14, relativeTo: .body))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var backupContents: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: "バックアップ内容")

            VStack(spacing: 0) {
                previewRow("作成日時", Self.dateFormatter.string(from: preview.header.createdAt), icon: "calendar")
                SettingsDivider(leadingInset: 52)
                previewRow("Moment", "\(preview.momentCount)件", icon: "sparkles")
                SettingsDivider(leadingInset: 52)
                previewRow("Source", "\(preview.sourceCount)件", icon: "books.vertical")
                SettingsDivider(leadingInset: 52)
                previewRow("Pair", "\(preview.pairCount)件", icon: "person.2")
                SettingsDivider(leadingInset: 52)
                previewRow("Episode", "\(preview.episodeCount)件", icon: "play.rectangle")
                SettingsDivider(leadingInset: 52)
                previewRow("視聴履歴", "\(preview.watchingSessionCount)件", icon: "clock.arrow.circlepath")
                SettingsDivider(leadingInset: 52)
                previewRow("画像", "\(preview.imageCount)枚", icon: "photo.on.rectangle")
            }
            .glassCard(cornerRadius: 20, fillOpacity: 0.52)
        }
    }

    private var replacementWarning: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "#D97706"))
            VStack(alignment: .leading, spacing: 6) {
                Text("復元前にご確認ください")
                    .font(.custom("Geist-SemiBold", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color.textPrimary)
                Text("現在の記録とプロフィールを置き換えます。表示設定・CloudKit設定・購入状態は変更されません。")
                    .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFF7ED", opacity: 0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#FDBA74", opacity: 0.7), lineWidth: 1)
        }
    }

    private func previewRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)
            Text(title)
                .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(value)
                .font(.custom("Geist-SemiBold", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    private var restoreButton: some View {
        Button(action: onConfirm) {
            HStack(spacing: 10) {
                if isRestoring {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(isRestoring ? "復元中…" : "バックアップから復元")
                    .font(AppTypography.cta())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.red.opacity(isRestoring ? 0.55 : 0.86), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isRestoring)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
}

private struct ManualBackupScreenHeader: View {
    let title: String
    let isDisabled: Bool
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 64)

            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.62), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityLabel("閉じる")

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
    }
}
