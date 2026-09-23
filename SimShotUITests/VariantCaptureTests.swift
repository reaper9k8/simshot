import XCTest

/// The same few screens, captured again after CI has changed the simulator's
/// appearance or text size with `xcrun simctl ui`.
///
/// Chapter 5 needs before and after pairs: normal text beside large text, and
/// light beside dark. If this works, those pairs come from the same runtime
/// with nothing faked, and the reader sees a true comparison.
///
/// CI sets SHOT_SUFFIX so each pass writes its own files.
final class VariantCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func test_variant_screens() {
        let settings = SettingsApp.open()
        capture("variant-settings-root", "Settings root under the current simulator state")

        guard settings.tapRow("Appearance") else {
            return missed("variant-appearance", "no Appearance row in the Settings list")
        }
        sleep(2)
        capture("variant-appearance", "Settings >> Appearance under the current state")

        guard settings.tapRow("Text Size") else {
            return missed("variant-text-size", "no Text Size row on the Appearance screen")
        }
        sleep(2)
        capture("variant-text-size", "Settings >> Appearance >> Text Size under the current state")
    }
}
