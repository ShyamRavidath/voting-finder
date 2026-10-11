import SwiftUI

struct PollingLocationCard: View {
    let location: PollingLocation
    var isSaved: Bool = false
    var onSave: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(location.type)
                    .font(.subheadline)
                    .foregroundStyle(Vote4UTheme.supportingText)
                Text(location.name)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text(location.addr)
                    .font(.subheadline)
                    .foregroundStyle(Vote4UTheme.supportingText)
                if let miles = location.milesAway {
                    Label("\(miles) away", systemImage: "location")
                        .font(.subheadline)
                        .foregroundStyle(Vote4UTheme.supportingText)
                }
            }

            if !location.isConfirmed {
                Group {
                    if typeSize.isAccessibilitySize {
                        Text("Not confirmed")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Label("Not confirmed", systemImage: "exclamationmark.triangle.fill")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.orange.opacity(0.14), in: .rect(cornerRadius: 8))
            }

            Button(action: onSave) {
                Group {
                    if typeSize.isAccessibilitySize {
                        Text(isSaved ? "Saved for offline" : "Save for offline")
                    } else {
                        Label(
                            isSaved ? "Saved for offline" : "Save for offline",
                            systemImage: isSaved ? "checkmark.circle.fill" : "bookmark"
                        )
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32)
            }
            .vote4UPrimaryActionStyle()
            .disabled(isSaved)
            .accessibilityIdentifier("save-location")

            if typeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    directions
                    share
                }
            } else {
                HStack(spacing: 10) {
                    directions
                    share
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: Vote4UTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Vote4UTheme.cardCornerRadius)
                .stroke(.secondary.opacity(0.15), lineWidth: 1)
        }
        .sensoryFeedback(.success, trigger: isSaved)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(location.name), \(location.addr)\(location.isConfirmed ? "" : ", Not confirmed")")
    }

    private var directions: some View {
        Button {
            MapDirections.open(
                name: location.name, address: location.addr,
                latitude: location.lat, longitude: location.lng)
        } label: {
            Group {
                if typeSize.isAccessibilitySize {
                    Text("Directions")
                } else {
                    Label("Directions", systemImage: "arrow.turn.up.right")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
    }

    private var share: some View {
        ShareLink(item: location.shareText) {
            Group {
                if typeSize.isAccessibilitySize {
                    Text("Share")
                } else {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
    }
}
