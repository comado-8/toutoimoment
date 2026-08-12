import SwiftUI

struct MomentCountPill: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            MomentSparkleIcon(color: .white, width: 9, height: 13)

            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .frame(minWidth: 45, minHeight: 23)
        .background(
            Capsule(style: .continuous)
                .fill(Color.appPrimary)
        )
    }
}

#Preview {
    MomentCountPill(count: 12)
        .padding()
}
