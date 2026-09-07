import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customizes the screen shown when a shielded app is opened.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func configuration(appName: String?) -> ShieldConfiguration {
        let strict = SharedStore.strictModeDefault
        let subtitle = strict
            ? "Strict mode is on. This app stays blocked until your session or schedule ends."
            : "Blocked by TimeControl. Get back to what matters."

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.09, blue: 0.15, alpha: 1.0),
            icon: UIImage(systemName: "hourglass"),
            title: ShieldConfiguration.Label(
                text: appName.map { "\($0) is paused" } ?? "Stay focused",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor(white: 0.75, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.36, green: 0.42, blue: 0.98, alpha: 1)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        configuration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configuration(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        configuration(appName: webDomain.domain)
    }
}
