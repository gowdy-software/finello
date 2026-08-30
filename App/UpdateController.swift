import Sparkle
import SwiftUI

/// The only part of finello that knows Sparkle exists.
///
/// Updates are verified with an EdDSA key pair rather than a Developer ID
/// signature, which is what makes an unnotarized self-update safe to accept
/// (ADR 0004). The public key and feed URL live in Info.plist.
@MainActor
@Observable
final class UpdateController {
    private let controller: SPUStandardUpdaterController

    /// False until an EdDSA public key is in Info.plist. Without one an update
    /// cannot be verified, and an unnotarized app must never install something
    /// it cannot verify — so finello does not start the updater at all rather
    /// than greeting her with an update error on first launch.
    let isConfigured: Bool

    init() {
        let key = (Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        isConfigured = !key.isEmpty
        controller = SPUStandardUpdaterController(
            startingUpdater: isConfigured, updaterDelegate: nil, userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool { isConfigured && controller.updater.canCheckForUpdates }

    var automaticallyChecks: Bool {
        get { isConfigured && controller.updater.automaticallyChecksForUpdates }
        set { if isConfigured { controller.updater.automaticallyChecksForUpdates = newValue } }
    }

    func checkForUpdates() {
        guard isConfigured else { return }
        controller.updater.checkForUpdates()
    }
}
