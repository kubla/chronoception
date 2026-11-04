import ChronoceptionCore
import Foundation

public struct HistoryRepository: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> PracticeHistory {
        guard FileManager.default.fileExists(atPath: url.path) else { return PracticeHistory() }
        return try JSONDecoder().decode(PracticeHistory.self, from: Data(contentsOf: url))
    }

    public func save(_ history: PracticeHistory) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(history).write(to: url, options: .atomic)
    }
}
