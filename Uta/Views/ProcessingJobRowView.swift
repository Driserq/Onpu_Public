import SwiftUI

struct ProcessingJobRowView: View {
    let title: String
    let artist: String
    let statusText: String
    let statusRaw: String
    let errorMessage: String?
    let isActive: Bool

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.appAccentLight)
                .frame(width: 48, height: 48)
                .overlay(
                    Group {
                        if isActive {
                            ProgressView()
                                .controlSize(.small)
                        } else if statusRaw == "succeeded" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "Untitled" : title)
                    .font(.headline)

                if !artist.isEmpty {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
