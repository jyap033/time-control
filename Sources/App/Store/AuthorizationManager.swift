import Foundation
import FamilyControls

/// Wraps FamilyControls (Screen Time) authorization.
@MainActor
final class AuthorizationManager: ObservableObject {

    @Published private(set) var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

    var isAuthorized: Bool { status == .approved }

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
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
