import SwiftUI

struct VoteSearchForm: View {
    @Binding var zip: String
    let canSearch: Bool
    let isBusy: Bool
    let onSearch: () -> Void
    let onUseLocation: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var zipFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start with your ZIP code")
                .font(.headline)
            Text("Location access is optional. Always confirm your assigned polling place with an official source.")
                .font(.subheadline)
                .foregroundStyle(Vote4UTheme.supportingText)

            if typeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    zipField
                    searchButton
                }
            } else {
                HStack(spacing: 10) {
                    zipField
                    searchButton
                }
            }

            Button(action: submitLocation) {
                Label("Use my location", systemImage: "location")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(isBusy)
        }
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { zipFocused = false }
            }
        }
    }

    private var zipField: some View {
        TextField("ZIP code", text: $zip)
            .keyboardType(.numberPad)
            .textContentType(.postalCode)
            .focused($zipFocused)
            .accessibilityLabel("ZIP code")
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(.background, in: .rect(cornerRadius: Vote4UTheme.compactCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Vote4UTheme.compactCornerRadius)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            }
    }

    private var searchButton: some View {
        Button(action: submitZip) {
            Text(isBusy ? "Searching…" : "Search")
                .font(.headline)
                .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil, minHeight: 36)
        }
        .vote4UPrimaryActionStyle()
        .disabled(!canSearch)
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
