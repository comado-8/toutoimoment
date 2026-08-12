import Foundation

enum NewMomentContextSummaryFormatter {
    static func summary(for draft: NewMomentDraft) -> String {
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        let schema = SourceLocatorSchema.schema(for: mediaType) ?? .fallback
        let valuesByKey = Dictionary(uniqueKeysWithValues: draft.contextValues.map { ($0.key, $0.value) })

        let formattedValues = schema.contextFieldRows
            .flatMap { $0 }
            .compactMap { field -> String? in
                let value = valuesByKey[field.key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !value.isEmpty else {
                    return nil
                }

                return schema.formattedMomentValue(
                    LocatorValue(key: field.key, value: value)
                )
            }

        if formattedValues.isEmpty {
            return draft.selectedSourceHelperText ?? AppStrings.newMomentStep2NoSource
        }

        return formattedValues.joined(separator: " / ")
    }
}
