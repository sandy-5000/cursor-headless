import SwiftUI

struct NoteEditorView: View {
    @Environment(AppSettings.self) private var settings
    @Bindable var store: NotesStore
    @State private var localTitle = ""
    @State private var localBody = ""
    @FocusState private var focusedField: EditorField?

    private enum EditorField {
        case title
        case body
    }

    var body: some View {
        Group {
            if let note = store.selectedNote {
                editor(for: note)
                    .id(note.id)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            } else {
                EmptyEditorView(onCreateNote: store.createNote)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: store.selectedNoteID)
        .background(AppTheme.editorGradient)
        .toolbar {
            if store.selectedNote != nil {
                ToolbarItem(placement: .destructiveAction) {
                    if let note = store.selectedNote {
                        Button(role: .destructive) {
                            withAnimation {
                                store.deleteNote(note)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .keyboardShortcut(.delete, modifiers: .command)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func editor(for note: Note) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Title", text: $localTitle, axis: .vertical)
                    .font(settings.titleFont())
                    .lineSpacing(2)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .title)
                    .onSubmit { focusedField = .body }
                    .onChange(of: localTitle) { _, newValue in
                        store.updateSelectedNote(title: newValue)
                    }

                metadataRow(for: note)

                Divider()
                    .padding(.vertical, 22)
                    .opacity(0.25)

                LineSpacedTextEditor(
                    text: $localBody,
                    fontSize: settings.contentFontSize,
                    lineSpacing: 2
                )
                    .focused($focusedField, equals: .body)
                    .frame(minHeight: 420)
                    .onChange(of: localBody) { _, newValue in
                        store.updateSelectedNote(body: newValue)
                    }
            }
            .padding(.horizontal, 56)
            .padding(.top, 36)
            .padding(.bottom, 60)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            syncLocalState(from: note)
            focusEmptyNoteIfNeeded(note)
        }
        .onChange(of: store.selectedNoteID) { _, _ in
            if let selected = store.selectedNote {
                syncLocalState(from: selected)
                focusEmptyNoteIfNeeded(selected)
            }
        }
    }

    private func focusEmptyNoteIfNeeded(_ note: Note) {
        guard note.title.isEmpty, note.body.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedField = .body
        }
    }

    private func metadataRow(for note: Note) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NoteDateStampView(note: note)

            HStack(spacing: 14) {
                Label {
                    Text("\(note.body.split(separator: "\n").count) lines")
                } icon: {
                    Image(systemName: "text.alignleft")
                }

                Label {
                    Text("\(note.body.count) characters")
                } icon: {
                    Image(systemName: "character.cursor.ibeam")
                }

                Spacer()

                Label("Saved locally", systemImage: "lock.shield")
                    .foregroundStyle(settings.accent.opacity(0.85))
            }
        }
        .font(AppTheme.captionFont())
        .foregroundStyle(.secondary)
        .padding(.top, 10)
    }

    private func syncLocalState(from note: Note) {
        localTitle = note.title
        localBody = note.body
    }
}

private struct EmptyEditorView: View {
    @Environment(AppSettings.self) private var settings
    let onCreateNote: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(settings.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(settings.accent.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(settings.accent)
            }

            VStack(spacing: 8) {
                Text("Your canvas awaits")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                Text("Select a note from the sidebar or create something new.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Button(action: onCreateNote) {
                Label("New Note", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(settings.accent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
