import Foundation

struct MomentLocationField: Identifiable, Hashable {
    let key: String
    let label: String
    let placeholder: String
    let inputKind: LocatorInputKind
    let unit: String?
    let options: [LocatorOption]

    var id: String { key }

    init(_ field: LocatorField) {
        key = field.key
        label = field.label
        placeholder = field.placeholder
        inputKind = field.inputKind
        unit = field.unit
        options = field.options
    }
}
