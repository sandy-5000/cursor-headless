import Foundation
import Observation

@MainActor
@Observable
final class NotesStore {
    private(set) var notes: [Note] = []
    private(set) var selectedNoteID: UUID?
    var searchQuery = ""

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

    init(storageDirectory: URL? = nil) {
        let base = storageDirectory ?? NotesStore.defaultStorageDirectory()
        storageURL = base
        indexURL = base.appendingPathComponent("notes.json", isDirectory: false)
        loadNotes()
        if notes.isEmpty {
            let welcome = Note(
                title: "Welcome to My Notes",
                body: """
                A quiet place for your thoughts.

                Everything you write is saved locally as plain text on your Mac — private, simple, and always yours.

                Start typing to replace this note, or press ⌘N to create a new one.
                """
            )
            notes = [welcome]
            selectedNoteID = welcome.id
            persistImmediately()
        } else {
            selectedNoteID = notes.sorted { $0.modifiedAt > $1.modifiedAt }.first?.id
        }
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
        if let title { note.title = title }
        if let body { note.body = body }
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

    private func loadNotes() {
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        guard fileManager.fileExists(atPath: indexURL.path) else { return }

        do {
            let data = try Data(contentsOf: indexURL)
            let metadata = try JSONDecoder().decode([NoteMetadata].self, from: data)
            notes = metadata.map { item in
                let body = (try? String(contentsOf: contentURL(for: item.id), encoding: .utf8)) ?? ""
                return Note(
                    id: item.id,
                    title: item.title,
                    body: body,
                    createdAt: item.createdAt,
                    modifiedAt: item.modifiedAt
                )
            }
        } catch {
            notes = []
        }
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
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        for note in notes {
            try? note.body.write(to: contentURL(for: note.id), atomically: true, encoding: .utf8)
        }

        let metadata = notes.map {
            NoteMetadata(id: $0.id, title: $0.title, createdAt: $0.createdAt, modifiedAt: $0.modifiedAt)
        }

        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: indexURL, options: .atomic)
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
