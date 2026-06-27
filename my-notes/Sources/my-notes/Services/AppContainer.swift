import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let vault: VaultManager
    let store: NotesStore

    init() {
        vault = VaultManager()
        vault.configureOnLaunch()
        store = NotesStore(vault: vault)
    }
}
