import Foundation

@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()

    private let directory: URL
    private var autoBackupTimer: Timer?
    private var snapshotProvider: (() -> Snapshot?)?

    private var sessionURL: URL { directory.appendingPathComponent("session.json") }
    private var guestListURL: URL { directory.appendingPathComponent("guestlist.json") }
    private var eventsDirectory: URL { directory.appendingPathComponent("Events") }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = appSupport.appendingPathComponent("RotaryDraw")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    var hasSession: Bool {
        FileManager.default.fileExists(atPath: sessionURL.path)
    }

    func save(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: sessionURL, options: .atomic)
    }

    func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: sessionURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    func clear() {
        try? FileManager.default.removeItem(at: sessionURL)
    }

    // MARK: - Event Archive

    /// Writes a permanent, timestamped record of a completed event. Never overwritten.
    func saveEventArchive(_ archive: EventArchive) {
        try? FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let illegalCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let safeName = archive.eventName
            .components(separatedBy: illegalCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)

        let filename = "\(safeName)_\(formatter.string(from: archive.date)).json"
        let url = eventsDirectory.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(archive) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Guest List

    func saveGuestList(_ list: [Int: GuestInfo]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        try? data.write(to: guestListURL, options: .atomic)
    }

    func loadGuestList() -> [Int: GuestInfo] {
        guard let data = try? Data(contentsOf: guestListURL),
              let list = try? JSONDecoder().decode([Int: GuestInfo].self, from: data)
        else { return [:] }
        return list
    }

    func startAutoBackup(provider: @escaping () -> Snapshot?) {
        snapshotProvider = provider
        autoBackupTimer?.invalidate()
        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.triggerBackup()
            }
        }
    }

    func stopAutoBackup() {
        autoBackupTimer?.invalidate()
        autoBackupTimer = nil
        snapshotProvider = nil
    }

    // MARK: - Private

    private func triggerBackup() {
        guard let snapshot = snapshotProvider?(),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let url = directory.appendingPathComponent("session_backup_\(formatter.string(from: Date())).json")
        try? data.write(to: url, options: .atomic)
        pruneBackups()
    }

    private func pruneBackups() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        let backups = files
            .filter { $0.lastPathComponent.hasPrefix("session_backup_") }
            .sorted {
                let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return a > b
            }

        backups.dropFirst(10).forEach { try? FileManager.default.removeItem(at: $0) }
    }
}
