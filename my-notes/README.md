# My Notes

A native macOS notes app built with SwiftUI. Private, local-first, and plain text on disk.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)

## Features

- **Split-view UI** — sidebar note list + editor
- **Local storage** — notes saved as plain `.txt` files on your Mac
- **Search** — filter notes by title or body
- **Auto-save** — changes persist automatically (~350ms debounce)
- **Settings** — base color, title font size, content font size (`⌘,`)
- **Date grouping** — Today, Yesterday, Previous 7 Days, Earlier
- **No network** — everything stays on your machine

## Requirements

- macOS 14 (Sonoma) or later
- [Swift Command Line Tools](https://developer.apple.com/xcode/resources/) (`swift --version`)

Xcode is **not** required.

## Quick start (development)

```bash
cd my-notes
swift run
```

## Build & install

Create a release `.app` bundle:

```bash
./build-app.sh
```

Install to Applications:

```bash
cp -R "dist/My Notes.app" /Applications/
```

Open from **Applications** or Spotlight (`My Notes`).

> **First launch:** If macOS blocks the app, right-click it → **Open** → **Open**.

## Uninstall

Remove the app (keeps your notes):

```bash
./uninstall-app.sh
```

Remove the app **and** all saved notes:

```bash
./uninstall-app.sh --purge
```

## Where notes are stored

```
~/Library/Application Support/MyNotes/
├── notes.json          # index (titles, dates)
└── {uuid}.txt          # plain text content per note
```

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘N` | New note |
| `⌘,` | Settings |
| `⌘⌫` | Delete selected note |

## Settings

Open **My Notes → Settings…** to customize:

- **Appearance** — Light, Dark, or System (follows Mac)
- **Base color** — accent theme (Blue, Teal, Amber, Rose, Green, Violet)
- **Title font size** — 24–48 pt
- **Content font size** — 12–24 pt

Preferences are saved in `UserDefaults`.

## Project structure

```
my-notes/
├── build-app.sh              # Build release .app bundle
├── uninstall-app.sh          # Remove app from Applications
├── Package.swift
├── Resources/
│   ├── AppIcon.icns
│   ├── Info.plist
│   └── ICON_CREDITS.txt
├── Sources/my-notes/
│   ├── MyNotesApp.swift
│   ├── Models/
│   ├── Services/
│   ├── Theme/
│   └── Views/
└── Tests/
```

## Tests

```bash
swift test
```

## App icon

Icon from [IconScout](https://iconscout.com/free-icon/notes-app-6512416_5415945) (free license). See `Resources/ICON_CREDITS.txt`.

## License

This project source is available for personal use. Check third-party asset licenses in `Resources/ICON_CREDITS.txt`.
