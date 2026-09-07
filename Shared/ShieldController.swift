import Foundation
import FamilyControls
import ManagedSettings

/// Applies and removes app shields via `ManagedSettings`.
/// Shared by the app (instant on/off) and the monitor extension (scheduled on/off).
enum ShieldController {

    /// Shield the apps/categories in `selection` on the given named store.
    static func apply(_ selection: FamilyActivitySelection, storeName: ManagedSettingsStore.Name) {
        let store = ManagedSettingsStore(named: storeName)

        // Individually-selected apps.
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens

        // Whole categories.
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)

        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)

        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil
            : selection.webDomainTokens
    }

    /// Remove all shields for the given named store.
    static func clear(storeName: ManagedSettingsStore.Name) {
        let store = ManagedSettingsStore(named: storeName)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        store.clearAllSettings()
    }
}
