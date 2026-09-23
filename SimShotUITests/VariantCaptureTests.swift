import XCTest

/// The three screens the second run proved are worth printing, captured again
/// after CI has changed the simulator's appearance or text size with
/// `xcrun simctl ui`.
///
/// Chapter 5 needs before and after pairs: normal text beside large text, and
/// light beside dark. Those pairs come from the same runtime with nothing
/// faked, which is the strongest thing the Simulator can give this book.
///
/// The Settings root is not captured here. It is missing Wi-Fi, Bluetooth and
/// Cellular, so it is unusable in every appearance.
///
/// CI sets SHOT_SUFFIX so each pass writes its own files.
final class VariantCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func test_variant_appearance() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Appearance") else {
            return missed("variant-appearance", "no Appearance row in the Settings list")
        }
        capture("variant-appearance", "Settings >> Appearance under the current state")

        guard settings.tapRow("Text Size") else {
            return missed("variant-text-size", "no Text Size row on the Appearance screen")
        }
        capture("variant-text-size", "Settings >> Appearance >> Text Size under the current state")
    }

    func test_variant_display_and_text_size() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility"),
              settings.tapRow("Display & Text Size") else {
            return missed("variant-display-and-text-size",
                          "could not reach Accessibility >> Display & Text Size")
        }
        capture("variant-display-and-text-size",
                "Accessibility >> Display & Text Size under the current state")
    }
}
