import SwiftUI

struct ErrorNotice: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            Button("Повторить", action: retry)
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
