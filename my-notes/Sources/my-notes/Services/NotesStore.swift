import Foundation
import Observation

@MainActor
@Observable
final class NotesStore {
    private(set) var notes: [Note] = []
    private(set) var selectedNoteID: UUID?
    var searchQuery = ""

    private let vault: VaultManager
    private let fileManager = FileManager.default
    private let storageURL: URL
    private let indexURL: URL
    private var saveTask: Task<Void, Never>?

    var selectedNote: Note? {
        get {
            guard let selectedNoteID else { return nil }
            return notes.first { $0.id == selectedNoteID }
        }
        set {
            guard let newValue else {
                selectedNoteID = nil
                return
            }
            selectedNoteID = newValue.id
            if let index = notes.firstIndex(where: { $0.id == newValue.id }) {
                notes[index] = newValue
            }
        }
    }

    var filteredNotes: [Note] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return notes.sorted { $0.modifiedAt > $1.modifiedAt }
        }
        return notes
            .filter {
                $0.displayTitle.lowercased().contains(query) ||
                $0.body.lowercased().contains(query)
            }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    var groupedNotes: [(section: NoteSection, notes: [Note])] {
        let grouped = Dictionary(grouping: filteredNotes) { NoteSection.section(for: $0.modifiedAt) }
        return NoteSection.allCases.compactMap { section in
            guard let notes = grouped[section], !notes.isEmpty else { return nil }
            return (section, notes)
        }
    }

    init(vault: VaultManager, storageDirectory: URL? = nil) {
        self.vault = vault
        let base = storageDirectory ?? NotesStore.defaultStorageDirectory()
        storageURL = base
        indexURL = base.appendingPathComponent("notes.json", isDirectory: false)
    }

    func prepareForUse() {
        guard vault.canReadNotes else { return }
        loadNotes()
        if notes.isEmpty, !fileManager.fileExists(atPath: indexURL.path) {
            ensureWelcomeNoteIfNeeded()
        }
    }

    func loadNotes() {
        guard vault.canReadNotes else { return }

        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        guard fileManager.fileExists(atPath: indexURL.path) else {
            notes = []
            selectedNoteID = nil
            recoverOrphanedNotes()
            return
        }

        do {
            let raw = try Data(contentsOf: indexURL)
            let data = try revealStoredData(raw)
            let metadata = try JSONDecoder().decode([NoteMetadata].self, from: data)
            notes = try metadata.map { item in
                let body = try readBody(for: item.id)
                return Note(
                    id: item.id,
                    title: item.title,
                    body: body,
                    createdAt: item.createdAt,
                    modifiedAt: item.modifiedAt
                )
            }
            selectedNoteID = notes.sorted { $0.modifiedAt > $1.modifiedAt }.first?.id
            recoverOrphanedNotes()
        } catch {
            notes = []
            selectedNoteID = nil
            recoverOrphanedNotes()
        }
    }

    func enableEncryption(with vault: VaultManager) {
        persistImmediately()
    }

    func disableEncryption(with vault: VaultManager) {
        persistImmediately()
    }

    func createNote() {
        let note = Note(title: "", body: "")
        notes.insert(note, at: 0)
        selectedNoteID = note.id
        scheduleSave()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        try? fileManager.removeItem(at: contentURL(for: note.id))

        if selectedNoteID == note.id {
            selectedNoteID = notes.sorted { $0.modifiedAt > $1.modifiedAt }.first?.id
        }

        scheduleSave()
    }

    func updateSelectedNote(title: String? = nil, body: String? = nil) {
        guard var note = selectedNote else { return }

        var didChange = false
        if let title, title != note.title {
            note.title = title
            didChange = true
        }
        if let body, body != note.body {
            note.body = body
            didChange = true
        }

        guard didChange else { return }

        note.modifiedAt = .now

        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }

        scheduleSave()
    }

    func select(_ note: Note) {
        selectedNoteID = note.id
    }

    // MARK: - Persistence

    private func ensureWelcomeNoteIfNeeded() {
        guard notes.isEmpty else { return }
        let welcome = Note(
            title: "Welcome to My Notes",
            body: """
            A quiet place for your thoughts.

            Everything you write is saved locally on your Mac. Enable encryption in Settings to protect your notes with a password.

            Start typing to replace this note, or press ⌘N to create a new one.
            """
        )
        notes = [welcome]
        selectedNoteID = welcome.id
        persistImmediately()
    }

    private func recoverOrphanedNotes() {
        guard let files = try? fileManager.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        let indexedIDs = Set(notes.map(\.id))
        var recovered: [Note] = []

        for url in files where url.pathExtension == "txt" {
            let uuidString = url.deletingPathExtension().lastPathComponent
            guard let id = UUID(uuidString: uuidString), !indexedIDs.contains(id) else { continue }

            guard let body = try? readBody(at: url), !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            let modifiedAt = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .now
            recovered.append(Note(id: id, title: "", body: body, createdAt: modifiedAt, modifiedAt: modifiedAt))
        }

        guard !recovered.isEmpty else { return }

        notes.append(contentsOf: recovered)
        notes.sort { $0.modifiedAt > $1.modifiedAt }
        selectedNoteID = notes.first?.id
        persistImmediately()
    }

    private func readBody(for id: UUID) throws -> String {
        try readBody(at: contentURL(for: id))
    }

    private func readBody(at url: URL) throws -> String {
        guard fileManager.fileExists(atPath: url.path) else { return "" }
        let raw = try Data(contentsOf: url)
        let data = try revealStoredData(raw)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func revealStoredData(_ raw: Data) throws -> Data {
        guard vault.isEncryptionEnabled else { return raw }

        do {
            return try vault.reveal(raw)
        } catch {
            if isLikelyPlaintextJSON(raw) || isLikelyPlaintextUTF8(raw) {
                return raw
            }
            throw error
        }
    }

    private func isLikelyPlaintextJSON(_ data: Data) -> Bool {
        (try? JSONDecoder().decode([NoteMetadata].self, from: data)) != nil
    }

    private func isLikelyPlaintextUTF8(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8) else { return false }
        return !text.isEmpty && text.allSatisfy { $0.isASCII || $0.isNewline || $0.isWhitespace || $0.isLetter || $0.isNumber || $0.isPunctuation }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            persistImmediately()
        }
    }

    private func persistImmediately() {
        guard vault.canReadNotes else { return }

        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        for note in notes {
            if let bodyData = note.body.data(using: .utf8),
               let protected = try? vault.protect(bodyData) {
                try? protected.write(to: contentURL(for: note.id), options: .atomic)
            }
        }

        let metadata = notes.map {
            NoteMetadata(id: $0.id, title: $0.title, createdAt: $0.createdAt, modifiedAt: $0.modifiedAt)
        }

        if let data = try? JSONEncoder().encode(metadata),
           let protected = try? vault.protect(data) {
            try? protected.write(to: indexURL, options: .atomic)
        }
    }

    private func contentURL(for id: UUID) -> URL {
        storageURL.appendingPathComponent("\(id.uuidString).txt", isDirectory: false)
    }

    nonisolated static func defaultStorageDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MyNotes", isDirectory: true)
    }
}

private struct NoteMetadata: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let modifiedAt: Date
}
