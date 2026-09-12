import Foundation
import FamilyControls

/// Wraps FamilyControls (Screen Time) authorization.
@MainActor
final class AuthorizationManager: ObservableObject {

    @Published private(set) var status: AuthorizationStatus = .notDetermined

    var isAuthorized: Bool { status == .approved }

    init() {
        refresh()
    }

    func refresh() {
        #if !FREE_TIER
        status = AuthorizationCenter.shared.authorizationStatus
        #endif
    }

    /// Prompts the user to grant Screen Time access. Must be called from the main app.
    func requestAuthorization() async -> Result<Void, Error> {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refresh()
            return .success(())
        } catch {
            refresh()
            return .failure(error)
        }
    }
}
