import Combine
import Foundation

struct NewMomentStep2ContextField: Identifiable, Hashable {
    let key: String
    let label: String
    let placeholder: String
    let inputKind: LocatorInputKind
    let unit: String?

    var id: String { key }
}

@MainActor
final class NewMomentStep2ViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft

    private let schema: SourceLocatorSchema

    init(draft: NewMomentDraft) {
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        let schema = SourceLocatorSchema.schema(for: mediaType) ?? SourceLocatorSchema.fallback
        var configuredDraft = draft
        configuredDraft.configureContext(using: schema)

        self.schema = schema
        self.draft = configuredDraft
    }

    var chooseSummary: String {
        let pairName = draft.selectedPairDisplayName ?? AppStrings.newMomentStep2NoPair
        let sourceName = draft.selectedSourceDisplayName ?? AppStrings.newMomentStep2NoSource
        return "\(pairName) · \(sourceName)"
    }

    var contextFieldRows: [[NewMomentStep2ContextField]] {
        schema.contextFieldRows.map { row in
            row.map {
                NewMomentStep2ContextField(
                    key: $0.key,
                    label: $0.label,
                    placeholder: $0.placeholder,
                    inputKind: $0.inputKind,
                    unit: $0.unit
                )
            }
        }
    }

    var orderedTextFieldIDs: [String] {
        contextFieldRows
            .flatMap { $0 }
            .filter { $0.inputKind != .timestamp }
            .map(\.id)
    }

    func value(for key: String) -> String {
        draft.contextValue(for: key)
    }

    func updateValue(for field: NewMomentStep2ContextField, value: String) {
        draft.updateContextValue(
            key: field.key,
            value: sanitizedValue(value, for: field.inputKind)
        )
    }

    func timestampComponents(for key: String) -> (hour: Int, minute: Int, second: Int) {
        Self.parseTimestamp(draft.contextValue(for: key)) ?? (0, 0, 0)
    }

    func updateTimestamp(key: String, hour: Int, minute: Int, second: Int) {
        draft.updateContextValue(
            key: key,
            value: Self.formattedTimestamp(hour: hour, minute: minute, second: second)
        )
    }

    private func sanitizedValue(_ value: String, for inputKind: LocatorInputKind) -> String {
        guard inputKind == .number else {
            return value
        }

        return value.unicodeScalars.compactMap { scalar -> Character? in
            switch scalar.value {
            case 0x30...0x39:
                return Character(String(scalar))
            case 0xFF10...0xFF19:
                let asciiValue = scalar.value - 0xFF10 + 0x30
                return UnicodeScalar(asciiValue).map { Character(String($0)) }
            default:
                return nil
            }
        }
        .map(String.init)
        .joined()
    }

    private static func formattedTimestamp(hour: Int, minute: Int, second: Int) -> String {
        String(
            format: "%02d:%02d:%02d",
            min(max(hour, 0), 99),
            min(max(minute, 0), 59),
            min(max(second, 0), 59)
        )
    }

    private static func parseTimestamp(_ value: String) -> (hour: Int, minute: Int, second: Int)? {
        let parts = value.split(separator: ":").compactMap { Int($0) }

        switch parts.count {
        case 2:
            return (0, min(max(parts[0], 0), 59), min(max(parts[1], 0), 59))
        case 3:
            return (
                min(max(parts[0], 0), 99),
                min(max(parts[1], 0), 59),
                min(max(parts[2], 0), 59)
            )
        default:
            return nil
        }
    }
}
