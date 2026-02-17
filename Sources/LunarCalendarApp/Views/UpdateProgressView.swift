import SwiftUI

struct UpdateProgressView: View {
    @Bindable var model: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 8) {
                if isDownloaded {
                    readyToInstallContent
                } else {
                    downloadingContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(width: 380)
    }

    private var isDownloaded: Bool {
        if case .downloaded = model.updateStatus {
            return true
        }
        return false
    }

    private var downloadingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Downloading update…")
                .font(.headline)

            ProgressView(value: progressFraction)

            HStack {
                Text(progressText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel") {
                    model.cancelDownload()
                }
            }
        }
    }

    private var readyToInstallContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready to Install")
                .font(.headline)

            ProgressView(value: 1.0)

            HStack {
                Spacer()
                Button("Install and Relaunch") {
                    model.relaunchFromDownloadedUpdate()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var progressFraction: Double {
        guard model.downloadTotalBytes > 0 else { return 0 }
        return Double(model.downloadBytesReceived) / Double(model.downloadTotalBytes)
    }

    private var progressText: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let received = formatter.string(fromByteCount: model.downloadBytesReceived)
        let total = formatter.string(fromByteCount: model.downloadTotalBytes)
        return "\(received) of \(total)"
    }
}
