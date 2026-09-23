import XCTest

/// A small representative set of figures, chosen to exercise every kind of
/// interaction the rest of the book would need: scrolling a long list, tapping
/// a row, going two and three levels deep, toggling a switch, and opening a
/// screen whose only control is a slider.
///
/// Several of these screens also settle an interface label the book asserts.
/// Those checks print a CLAIM line whether they pass or fail.
///
/// Nothing here decides whether a capture is usable. That is done by looking
/// at the images afterward.
final class FigureCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        // A missing row must not abandon the rest of the run.
        continueAfterFailure = true
    }

    // MARK: - FIG-02-04  Settings >> Action Button

    func test_FIG_02_04_action_button() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Action Button") else {
            return missed("FIG-02-04", "no Action Button row in the Settings list")
        }
        sleep(2)
        capture("FIG-02-04-action-button", "Settings >> Action Button, the list of choices")

        settings.swipeUp()
        sleep(1)
        capture("FIG-02-04-action-button-lower", "the same screen, scrolled down")
    }

    // MARK: - FIG-05-02  Settings >> Appearance >> Text Size

    func test_FIG_05_02_appearance_and_text_size() {
        let settings = SettingsApp.open()

        capture("FIG-05-02a-settings-root",
                "Settings root. Already known to be missing Wi-Fi, Bluetooth and Cellular.")

        guard settings.tapRow("Appearance") else {
            return missed("FIG-05-02b", "no Appearance row in the Settings list")
        }
        sleep(2)
        capture("FIG-05-02b-appearance", "Settings >> Appearance")

        guard settings.tapRow("Text Size") else {
            return missed("FIG-05-02c", "no Text Size row on the Appearance screen")
        }
        sleep(2)
        capture("FIG-05-02c-text-size", "Settings >> Appearance >> Text Size")
    }

    // MARK: - FIG-05-05  Bold Text and Liquid Glass

    func test_FIG_05_05_bold_text_and_liquid_glass() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Appearance") else {
            return missed("FIG-05-05", "no Appearance row in the Settings list")
        }
        sleep(2)
        capture("FIG-05-05-before-bold-text", "Appearance screen with Bold Text off")

        if settings.setSwitch("Bold Text", on: true) {
            sleep(3)
            capture("FIG-05-05a-bold-text-on", "Bold Text switched on")
            _ = settings.setSwitch("Bold Text", on: false)
            sleep(3)
        } else {
            missed("FIG-05-05a", "no Bold Text switch on the Appearance screen")
        }

        if settings.tapRow("Liquid Glass") {
            sleep(2)
            capture("FIG-05-05b-liquid-glass", "Settings >> Appearance >> Liquid Glass")
        } else {
            missed("FIG-05-05b", "no Liquid Glass row on the Appearance screen")
        }
    }

    // MARK: - FIG-05-03  Accessibility >> Display & Text Size

    func test_FIG_05_03_display_and_text_size() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility") else {
            return missed("FIG-05-03", "no Accessibility row in the Settings list")
        }
        sleep(2)
        guard settings.tapRow("Display & Text Size") else {
            return missed("FIG-05-03", "no Display & Text Size row under Accessibility")
        }
        sleep(2)

        capture("FIG-05-03a-display-and-text-size-top",
                "Accessibility >> Display & Text Size, top of the list")
        settings.swipeUp()
        sleep(1)
        capture("FIG-05-03b-display-and-text-size-middle", "the same screen, scrolled once")
        settings.swipeUp()
        sleep(1)
        capture("FIG-05-03c-display-and-text-size-lower", "the same screen, scrolled twice")

        // The book records that Show Borders replaced Button Shapes in iOS 27.
        if settings.scrollToRow("Show Borders") != nil {
            claim("Show Borders row found on Display & Text Size")
            capture("claim-show-borders", "the Show Borders row")
        } else {
            claim("Show Borders row NOT found on Display & Text Size")
        }

        if settings.scrollToRow("Button Shapes") != nil {
            claim("Button Shapes row STILL present. This contradicts the book")
            capture("claim-button-shapes-still-present", "an unexpected Button Shapes row")
        } else {
            claim("Button Shapes row absent, as the book expects")
        }
    }

    // MARK: - FIG-23-01  Settings >> Accessibility, the whole list

    func test_FIG_23_01_accessibility_list() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility") else {
            return missed("FIG-23-01", "no Accessibility row in the Settings list")
        }
        sleep(2)

        // Four passes, because the book asserts four section headings on this
        // screen: Vision, Hearing, Speech, and Physical and Motor.
        let letters = ["a", "b", "c", "d", "e"]
        for index in 0..<letters.count {
            capture("FIG-23-01\(letters[index])-accessibility-\(index + 1)",
                    "Settings >> Accessibility, screen \(index + 1)")
            settings.swipeUp()
            sleep(1)
        }
    }

    // MARK: - FIG-23-05  Accessibility >> Read & Speak

    func test_FIG_23_05_read_and_speak() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Accessibility") else {
            return missed("FIG-23-05", "no Accessibility row in the Settings list")
        }
        sleep(2)

        // The book records that Read & Speak replaced Spoken Content.
        if settings.scrollToRow("Spoken Content") != nil {
            claim("Spoken Content row STILL present. This contradicts the book")
            capture("claim-spoken-content-still-present", "an unexpected Spoken Content row")
        } else {
            claim("Spoken Content row absent, as the book expects")
        }

        guard settings.tapRow("Read & Speak") else {
            claim("Read & Speak row NOT found under Accessibility")
            return missed("FIG-23-05", "no Read & Speak row under Accessibility")
        }
        claim("Read & Speak row found under Accessibility")
        sleep(2)
        capture("FIG-23-05a-read-and-speak", "Settings >> Accessibility >> Read & Speak")

        if settings.setSwitch("Speak Screen", on: true) {
            sleep(3)
            capture("FIG-23-05b-speak-screen-on", "Speak Screen switched on")
            _ = settings.setSwitch("Speak Screen", on: false)
        } else {
            missed("FIG-23-05b", "no Speak Screen switch on the Read & Speak screen")
        }

        if settings.scrollToRow("Speaking Rate") != nil {
            capture("FIG-23-05c-speaking-rate", "the Speaking Rate control, in place on the screen")
        } else {
            missed("FIG-23-05c", "no Speaking Rate control on the Read & Speak screen")
        }
    }

    // MARK: - FIG-22-02  Settings >> Privacy & Security

    func test_FIG_22_02_privacy_and_security() {
        let settings = SettingsApp.open()

        guard settings.tapRow("Privacy & Security") else {
            return missed("FIG-22-02", "no Privacy & Security row in the Settings list")
        }
        sleep(2)
        capture("FIG-22-02a-privacy-and-security-top", "Settings >> Privacy & Security, top")
        settings.swipeUp()
        sleep(1)
        capture("FIG-22-02b-privacy-and-security-lower", "the same screen, scrolled down")
    }

    // MARK: - Inventory

    /// Walks the whole Settings root list and records every row label found.
    /// This answers, from evidence, which screens the runtime can show at all.
    func test_zz_settings_root_inventory() {
        let settings = SettingsApp.open()
        var seen: [String] = []

        for pass in 0..<7 {
            for label in settings.visibleRowLabels() where !seen.contains(label) {
                seen.append(label)
            }
            capture(String(format: "inventory-settings-root-%02d", pass),
                    "Settings root, screen \(pass + 1)")
            settings.swipeUp()
            sleep(1)
        }

        print("SETTINGS_ROOT_ROWS\t" + seen.joined(separator: " | "))

        let inventory = XCTAttachment(string: seen.joined(separator: "\n"))
        inventory.name = "settings-root-rows.txt"
        inventory.lifetime = .keepAlways
        add(inventory)
    }
}
