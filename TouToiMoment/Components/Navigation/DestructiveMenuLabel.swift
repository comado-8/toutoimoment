import SwiftUI

struct DestructiveMenuLabel: View {
    let title: String

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(Color.red)
        } icon: {
            Image(systemName: "trash")
                .foregroundStyle(Color.red)
        }
        .tint(Color.red)
    }
}
