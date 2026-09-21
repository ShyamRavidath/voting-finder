import SwiftUI

struct VoteSearchForm: View {
    @Binding var zip: String
    let canSearch: Bool
    let isBusy: Bool
    let onSearch: () -> Void
    let onUseLocation: () -> Void

    @FocusState private var zipFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Label {
                    TextField("ZIP code", text: $zip)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                        .focused($zipFocused)
                        .accessibilityLabel("ZIP code")
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(.background.opacity(0.72), in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))

                Button(action: submitZip) {
                    Text("Search")
                        .frame(minHeight: 32)
                }
                .vote4UPrimaryActionStyle()
                .disabled(!canSearch)
            }

            Button(action: submitLocation) {
                Label("Use my location", systemImage: "location.fill")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.bordered)
            .disabled(isBusy)
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }

    private func submitZip() {
        zipFocused = false
        onSearch()
    }

    private func submitLocation() {
        zipFocused = false
        onUseLocation()
    }
}

#Preview {
    VoteSearchForm(
        zip: .constant("90210"),
        canSearch: true,
        isBusy: false,
        onSearch: {},
        onUseLocation: {}
    )
    .padding()
}
