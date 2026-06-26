import Foundation

struct Note: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        createdAt: Date = .now,
        modifiedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var preview: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "No additional text" }
        return String(trimmed.prefix(120))
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = body.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
        let fallback = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? "Untitled" : String(fallback.prefix(60))
    }

    var formattedDate: String {
        modifiedAt.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTime: String {
        modifiedAt.formatted(date: .omitted, time: .shortened)
    }
}

enum NoteSection: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case previousSevenDays = "Previous 7 Days"
    case earlier = "Earlier"

    static func section(for date: Date, calendar: Calendar = .current) -> NoteSection {
        if calendar.isDateInToday(date) { return .today }
        if calendar.isDateInYesterday(date) { return .yesterday }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now),
           date >= weekAgo {
            return .previousSevenDays
        }
        return .earlier
    }
}
