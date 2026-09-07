import SwiftUI
import FamilyControls

/// Presents Apple's `FamilyActivityPicker`. The chosen apps/categories come back
/// as opaque, privacy-preserving tokens — we never see app names or bundle ids.
struct AppPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Choose apps to block")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

extension FamilyActivitySelection {
    /// Total number of apps + categories + web domains selected.
    var itemCount: Int {
        applicationTokens.count + categoryTokens.count + webDomainTokens.count
    }

    var summaryText: String {
        itemCount == 0 ? "No apps selected" : "\(itemCount) item\(itemCount == 1 ? "" : "s") selected"
    }
}
