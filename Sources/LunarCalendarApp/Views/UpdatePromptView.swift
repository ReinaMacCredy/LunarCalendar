import SwiftUI

struct UpdatePromptView: View {
    let release: UpdateRelease
    let currentVersion: String
    @Binding var autoDownloadUpdates: Bool
    var onInstall: () -> Void
    var onSkip: () -> Void
    var onRemindLater: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            header
            releaseNotesSection
            autoDownloadToggle
            actionButtons
        }
        .padding(20)
        .frame(width: 540)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("A new version is available!")
                    .font(.headline)
                Text("LunarCalendar \(release.latestVersion) is available — you have \(currentVersion).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var releaseNotesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(releaseTitle)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)

            ScrollView {
                Text(releaseNotesText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.separator, lineWidth: 1)
            )
        }
    }

    private var autoDownloadToggle: some View {
        Toggle("Automatically download updates in the future", isOn: $autoDownloadUpdates)
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack {
            Button("Skip This Version") {
                onSkip()
            }

            Spacer()

            Button("Remind Me Later") {
                onRemindLater()
            }

            Button("Install Update") {
                onInstall()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var releaseTitle: String {
        let trimmedTitle = release.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let baseTitle: String
        if trimmedTitle.isEmpty {
            baseTitle = "LunarCalendar >= \(release.latestVersion)"
        } else {
            baseTitle = trimmedTitle
        }

        guard let publishedAt = release.publishedAt else {
            return baseTitle
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return "\(baseTitle) (\(formatter.string(from: publishedAt)))"
    }

    private var releaseNotesText: String {
        guard let notes = release.releaseNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
              !notes.isEmpty else {
            return "Release notes are not available for this version."
        }
        return notes
    }
}
