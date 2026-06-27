import SwiftUI

struct SidebarView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var store: NotesStore
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            Divider().opacity(0.35)
            notesList
        }
        .background(AppTheme.sidebarGradient)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        store.createNote()
                    }
                } label: {
                    Label("New Note", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Create a new note (⌘N)")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(settings.accent.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "note.text")
                    .font(settings.font(size: settings.contentFontSize, weight: .semibold))
                    .foregroundStyle(settings.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("My Notes")
                    .font(settings.sidebarHeaderFont())
                Text("\(store.notes.count) note\(store.notes.count == 1 ? "" : "s")")
                    .font(settings.sidebarCaptionFont())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            AccentDot()
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(settings.font(size: settings.contentFontSize - 1, weight: .medium))

            TextField("Search notes", text: $store.searchQuery)
                .font(settings.bodyFont())
                .textFieldStyle(.plain)
                .focused($searchFocused)

            if !store.searchQuery.isEmpty {
                Button {
                    store.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            GlassBackground(cornerRadius: 12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
                if store.filteredNotes.isEmpty {
                    emptySearchState
                } else {
                    ForEach(store.groupedNotes, id: \.section) { group in
                        Section {
                            ForEach(group.notes) { note in
                                NoteRowView(
                                    note: note,
                                    isSelected: store.selectedNoteID == note.id
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                        store.select(note)
                                    }
                                }
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        withAnimation {
                                            store.deleteNote(note)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text(group.section.rawValue.uppercased())
                                .font(settings.sidebarCaptionFont())
                                .foregroundStyle(.secondary)
                                .tracking(0.8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                                .padding(.top, 8)
                                .padding(.bottom, 12)
                                .background {
                                    PinnedSectionHeaderBackground()
                                        .padding(.horizontal, -16)
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(settings.font(size: settings.contentFontSize + 4))
                .foregroundStyle(.tertiary)
            Text("No matching notes")
                .font(settings.bodyFont())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}
