import XCTest

/// Settings screens. This is the area the second run proved the Simulator is
/// actually good at: Appearance, Display & Text Size, and Privacy & Security.
///
/// Screens the second run showed are not worth capturing are not attempted
/// again. The Settings root is captured once for the record only, because it
/// is missing Wi-Fi, Bluetooth, Cellular, Battery, Notifications, Sounds &
/// Haptics and Display & Brightness, and reads "Passcode" rather than
/// "Face ID & Passcode".
final class FigureCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - Appearance

    func test_05_01_appearance_and_text_size() {
        let settings = SettingsApp.open()
        capture("FIG-05-02a-settings-root", "Settings root. For the record only.")

        guard settings.tapRow("Appearance") else {
            return missed("appearance", "no Appearance row in the Settings list")
        }
        capture("FIG-05-02b-appearance", "Settings >> Appearance")

        guard settings.tapRow("Text Size") else {
            return missed("text-size", "no Text Size row on the Appearance screen")
        }
        capture("FIG-05-02c-text-size", "Settings >> Appearance >> Text Size")
    }

    /// Bold Text off and on, the pair the second run failed to produce because
    /// the switch carries no accessibility label of its own.
    func test_05_02_bold_text_pair() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Appearance") else {
            return missed("bold-text", "no Appearance row in the Settings list")
        }
        capture("FIG-05-05a-bold-text-off", "Appearance with Bold Text off")

        guard settings.setSwitch("Bold Text", on: true) else {
            return missed("FIG-05-05b", "could not switch Bold Text on")
        }
        sleep(3)
        capture("FIG-05-05b-bold-text-on", "Appearance with Bold Text on")

        _ = settings.setSwitch("Bold Text", on: false)
        sleep(3)
    }

    func test_05_03_display_zoom() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Appearance") else {
            return missed("display-zoom", "no Appearance row in the Settings list")
        }
        guard settings.tapRow("Display Zoom") else {
            return missed("display-zoom", "no Display Zoom row on the Appearance screen")
        }
        capture("FIG-05-06-display-zoom", "Settings >> Appearance >> Display Zoom")
    }

    // MARK: - Accessibility, Display & Text Size

    func test_05_04_display_and_text_size() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility") else {
            return missed("display-and-text-size", "no Accessibility row")
        }
        guard settings.tapRow("Display & Text Size") else {
            return missed("display-and-text-size", "no Display & Text Size row")
        }

        captureScrolling(settings, "FIG-05-03",
                         "Accessibility >> Display & Text Size")
        inventory("display-and-text-size", settings.visibleRowLabels())
    }

    /// Show Borders off and on. A reader cannot picture what borders look like
    /// from a sentence, and this is the one accessibility setting on this
    /// screen that changes the whole interface visibly.
    func test_05_05_show_borders_pair() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility"),
              settings.tapRow("Display & Text Size") else {
            return missed("show-borders", "could not reach Display & Text Size")
        }

        guard settings.scrollToRow("Show Borders") != nil else {
            claim("Show Borders row NOT found on Display & Text Size")
            return missed("show-borders", "no Show Borders row")
        }
        claim("Show Borders row found on Display & Text Size")
        capture("FIG-05-07a-show-borders-off", "Show Borders off")

        guard settings.setSwitch("Show Borders", on: true) else {
            return missed("FIG-05-07b", "could not switch Show Borders on")
        }
        sleep(3)
        capture("FIG-05-07b-show-borders-on", "Show Borders on, borders now drawn")

        _ = settings.setSwitch("Show Borders", on: false)
        sleep(2)
    }

    func test_05_06_larger_text() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility"),
              settings.tapRow("Display & Text Size") else {
            return missed("larger-text", "could not reach Display & Text Size")
        }
        guard settings.tapRow("Larger Text") else {
            return missed("larger-text", "no Larger Text row")
        }
        capture("FIG-05-08-larger-text",
                "Display & Text Size >> Larger Text, with the accessibility sizes switch")
    }

    // MARK: - Privacy & Security

    func test_22_01_privacy_and_security() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Privacy & Security") else {
            return missed("privacy-and-security", "no Privacy & Security row")
        }
        captureScrolling(settings, "FIG-22-02", "Settings >> Privacy & Security")
        inventory("privacy-and-security", settings.visibleRowLabels())
    }

    func test_22_02_location_services() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Privacy & Security") else {
            return missed("location-services", "no Privacy & Security row")
        }
        guard settings.tapRow("Location Services") else {
            return missed("location-services", "no Location Services row")
        }
        capture("FIG-22-03-location-services",
                "Privacy & Security >> Location Services, the main switch")
        inventory("location-services", settings.visibleRowLabels())
    }

    func test_22_03_tracking() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Privacy & Security") else {
            return missed("tracking", "no Privacy & Security row")
        }
        guard settings.tapRow("Tracking") else {
            return missed("tracking", "no Tracking row")
        }
        capture("FIG-22-04-tracking",
                "Privacy & Security >> Tracking, with Allow Apps to Request to Track")
    }

    // MARK: - Inventories

    /// The Settings root, and the two screens whose contents the book asserts.
    /// Each stops as soon as the list stops moving.
    func test_90_inventory_settings_root() {
        let settings = SettingsApp.open()
        captureScrolling(settings, "inventory-settings-root", "Settings root")
        inventory("settings-root", settings.visibleRowLabels())
    }

    func test_91_inventory_accessibility() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Accessibility") else {
            return missed("accessibility-inventory", "no Accessibility row")
        }
        captureScrolling(settings, "inventory-accessibility", "Settings >> Accessibility")
        inventory("accessibility", settings.visibleRowLabels())

        // Still open from the second run: the runtime shows Spoken Content
        // where the book says Read & Speak. Record it, change nothing.
        claim(settings.scrollToRow("Read & Speak") != nil
              ? "Read & Speak row FOUND"
              : "Read & Speak row NOT found")
        claim(settings.scrollToRow("Spoken Content") != nil
              ? "Spoken Content row FOUND"
              : "Spoken Content row NOT found")
    }

    /// General holds Software Update, iPhone Storage and About on a real
    /// iPhone. Whether it does here decides Chapter 25.
    func test_92_inventory_general() {
        let settings = SettingsApp.open()
        guard settings.tapRow("General") else {
            return missed("general-inventory", "no General row")
        }
        captureScrolling(settings, "inventory-general", "Settings >> General")
        inventory("general", settings.visibleRowLabels())

        for wanted in ["Software Update", "iPhone Storage", "About"] {
            claim(settings.scrollToRow(wanted) != nil
                  ? "General contains \(wanted)"
                  : "General does NOT contain \(wanted)")
        }
    }

    /// The book states that every app's own settings nest under Apps.
    func test_93_inventory_apps() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Apps") else {
            return missed("apps-inventory", "no Apps row")
        }
        captureScrolling(settings, "inventory-apps", "Settings >> Apps")
        inventory("apps", settings.visibleRowLabels())
    }
}
