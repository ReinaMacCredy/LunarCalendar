import Foundation

enum UpdateCheckResult: Sendable {
    case upToDate(currentVersion: String)
    case available(UpdateRelease)
}

enum UpdateServiceError: LocalizedError {
    case invalidResponse
    case unexpectedStatus(Int)
    case missingAsset
    case invalidAssetURL(String)
    case downloadFailed
    case extractionFailed(Int32)
    case appBundleNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.tr(
                "Unexpected response from update server.",
                fallback: "Unexpected response from update server."
            )
        case .unexpectedStatus(let status):
            return String(
                format: L10n.tr("Update server returned status %@.", fallback: "Update server returned status %@."),
                locale: L10n.locale,
                "\(status)"
            )
        case .missingAsset:
            return L10n.tr(
                "No downloadable update asset was found.",
                fallback: "No downloadable update asset was found."
            )
        case .invalidAssetURL(let value):
            return String(
                format: L10n.tr("Invalid asset URL: %@", fallback: "Invalid asset URL: %@"),
                locale: L10n.locale,
                value
            )
        case .downloadFailed:
            return L10n.tr("Failed to download update.", fallback: "Failed to download update.")
        case .extractionFailed(let code):
            return String(
                format: L10n.tr(
                    "Failed to extract update archive (code %@).",
                    fallback: "Failed to extract update archive (code %@)."
                ),
                locale: L10n.locale,
                "\(code)"
            )
        case .appBundleNotFound:
            return L10n.tr(
                "Extracted update does not contain an app bundle.",
                fallback: "Extracted update does not contain an app bundle."
            )
        }
    }
}

actor UpdateService {
    private let owner: String
    private let repository: String
    private let session: URLSession
    private let fileManager: FileManager
    private let updatesDirectory: URL

    init(
        owner: String = "ReinaMacCredy",
        repository: String = "LunarCalendar",
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.owner = owner
        self.repository = repository
        self.session = session
        self.fileManager = fileManager

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        updatesDirectory = appSupport
            .appendingPathComponent("LunarCalendarApp", isDirectory: true)
            .appendingPathComponent("Updates", isDirectory: true)
    }

    func checkForUpdate(currentVersion: String) async throws -> UpdateCheckResult {
        let endpoint = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateServiceError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            return .upToDate(currentVersion: currentVersion)
        }
        guard httpResponse.statusCode == 200 else {
            throw UpdateServiceError.unexpectedStatus(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let release = try decoder.decode(GitHubReleaseResponse.self, from: data)

        let latestVersion = normalizeVersionTag(release.tagName)
        let releaseAssets = release.assets.compactMap(mapAsset)
        let preferredAsset = preferredAsset(from: releaseAssets)
        let update = UpdateRelease(
            latestVersion: latestVersion,
            title: release.name,
            releaseNotes: release.body,
            releaseURL: release.htmlURL,
            publishedAt: release.publishedAt,
            asset: preferredAsset
        )

        if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
            return .available(update)
        }
        return .upToDate(currentVersion: currentVersion)
    }

    func downloadUpdate(
        _ release: UpdateRelease,
        onProgress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> DownloadedUpdate {
        guard let asset = release.asset else {
            throw UpdateServiceError.missingAsset
        }
        guard let assetURL = URL(string: asset.downloadURL) else {
            throw UpdateServiceError.invalidAssetURL(asset.downloadURL)
        }

        try fileManager.createDirectory(at: updatesDirectory, withIntermediateDirectories: true)

        let safeFileName = sanitizedFileName(asset.name)
        let destinationURL = updatesDirectory.appendingPathComponent(safeFileName)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        let temporaryURL: URL
        if let onProgress {
            temporaryURL = try await downloadWithProgress(from: assetURL, onProgress: onProgress)
        } else {
            let (tmpURL, response) = try await session.download(from: assetURL)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw UpdateServiceError.downloadFailed
            }
            temporaryURL = tmpURL
        }

        do {
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        } catch {
            try? fileManager.removeItem(at: destinationURL)
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        }

        var extractedAppPath: String?
        if asset.kind == .zip {
            let extractionDirectory = updatesDirectory
                .appendingPathComponent("extracted-\(release.latestVersion)-\(UUID().uuidString)", isDirectory: true)
            try fileManager.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)
            try extractZip(at: destinationURL, to: extractionDirectory)

            guard let appURL = findFirstAppBundle(in: extractionDirectory) else {
                throw UpdateServiceError.appBundleNotFound
            }
            extractedAppPath = appURL.path
        }

        return DownloadedUpdate(
            latestVersion: release.latestVersion,
            filePath: destinationURL.path,
            extractedAppPath: extractedAppPath
        )
    }

    private func normalizeVersionTag(_ tag: String) -> String {
        tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    private func mapAsset(_ asset: GitHubReleaseAsset) -> UpdateAsset? {
        let extensionValue = URL(fileURLWithPath: asset.name).pathExtension.lowercased()
        let kind: UpdateAssetKind
        switch extensionValue {
        case "zip":
            kind = .zip
        case "dmg":
            kind = .dmg
        default:
            kind = .other
        }

        return UpdateAsset(
            name: asset.name,
            downloadURL: asset.browserDownloadURL,
            sizeInBytes: asset.size,
            kind: kind
        )
    }

    private func preferredAsset(from assets: [UpdateAsset]) -> UpdateAsset? {
        if let zip = assets.first(where: { $0.kind == .zip }) {
            return zip
        }
        if let dmg = assets.first(where: { $0.kind == .dmg }) {
            return dmg
        }
        return assets.first
    }

    private func sanitizedFileName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    private func extractZip(at zipURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, destinationURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateServiceError.extractionFailed(process.terminationStatus)
        }
    }

    private func downloadWithProgress(
        from url: URL,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws -> URL {
        let delegate = ProgressDownloadDelegate(onProgress: onProgress)
        let progressSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { progressSession.finishTasksAndInvalidate() }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                let task = progressSession.downloadTask(with: url)
                delegate.downloadTask = task
                task.resume()
            }
        } onCancel: {
            delegate.downloadTask?.cancel()
        }
    }

    private func findFirstAppBundle(in directory: URL) -> URL? {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
                return fileURL
            }
        }
        return nil
    }
}

private final class ProgressDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let onProgress: @Sendable (Int64, Int64) -> Void
    var continuation: CheckedContinuation<URL, any Error>?
    var downloadTask: URLSessionDownloadTask?
    private var resumed = false

    init(onProgress: @escaping @Sendable (Int64, Int64) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard !resumed else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let stablePath = tempDir.appendingPathComponent(UUID().uuidString + ".download")
        do {
            try FileManager.default.moveItem(at: location, to: stablePath)
            if let httpResponse = downloadTask.response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                try? FileManager.default.removeItem(at: stablePath)
                resumed = true
                continuation?.resume(throwing: UpdateServiceError.downloadFailed)
            } else {
                resumed = true
                continuation?.resume(returning: stablePath)
            }
        } catch {
            resumed = true
            continuation?.resume(throwing: UpdateServiceError.downloadFailed)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        onProgress(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard !resumed, let error else { return }
        resumed = true
        continuation?.resume(throwing: error)
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: String?
    let publishedAt: Date?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

private struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: String
    let size: Int64?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}
