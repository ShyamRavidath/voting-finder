import SwiftUI

struct OfficialSourcesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Official sources", systemImage: "checkmark.shield.fill")
                .font(.title3.bold())
                .foregroundStyle(.tint)

            Text("Confirm your polling place, registration, and voting rules with an official source.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(BundledData.officialLinks) { link in
                    if let destination = URL(string: link.href) {
                        Link(destination: destination) {
                            HStack(spacing: 12) {
                                Image(systemName: "building.columns.fill")
                                    .foregroundStyle(.tint)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(link.label)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Text(link.source)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                            .padding(.vertical, 8)
                        }

                        if link.id != BundledData.officialLinks.last?.id {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
    }
}

#Preview {
    OfficialSourcesView()
        .padding()
}
