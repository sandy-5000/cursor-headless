import Testing
@testable import my_notes

@Test func noteDisplayTitleUsesBodyWhenTitleEmpty() {
    let note = Note(title: "", body: "First line\nSecond line")
    #expect(note.displayTitle == "First line")
}

@Test func notePreviewTruncatesLongBody() {
    let longBody = String(repeating: "a", count: 200)
    let note = Note(body: longBody)
    #expect(note.preview.count == 120)
}

@Test func noteSectionGroupsByDate() {
    let calendar = Calendar.current
    let today = Date.now
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!

    #expect(NoteSection.section(for: today) == .today)
    #expect(NoteSection.section(for: yesterday) == .yesterday)
    #expect(NoteSection.section(for: twoWeeksAgo) == .earlier)
}
