import XCTest

/// Only the figures that are still missing.
///
/// These are already captured, verified and saved, and are deliberately NOT
/// re-run: FIG-05-02 B and C, FIG-05-03, FIG-22-02, FIG-22-04 A, FIG-22-05,
/// FIG-04-04, and the dark and large text variants.
///
/// Figure IDs here are taken from `image-plan.md`. The third run invented IDs
/// that were already assigned to different content, which would have corrupted
/// `image-log.md` had the files been filed under them.
final class FigureCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - FIG-05-05  A Bold Text switched on.  B Liquid Glass slider.

    func test_05_05a_bold_text() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Appearance") else {
            return missed("FIG-05-05A", "no Appearance row")
        }
        captureSwitchPair(settings, row: "Bold Text",
                          "fig-05-05a-bold-text",
                          "Settings >> Appearance")
    }

    /// The whole Liquid Glass screen is unusable: it is dominated by an Apple
    /// promotional photograph of Apple Park, which the book bars. Captured
    /// anyway so the slider at the bottom can be cropped out of it.
    func test_05_05b_liquid_glass() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Appearance"),
              settings.tapRow("Liquid Glass") else {
            return missed("FIG-05-05B", "could not reach Liquid Glass")
        }
        capture("fig-05-05b-liquid-glass",
                "Liquid Glass. CROP TO THE SLIDER ONLY: the preview above it is an Apple photograph.")
    }

    // MARK: - FIG-05-06  A Display Zoom, Larger Text selected.  B the confirmation.

    func test_05_06_display_zoom_confirmation() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Appearance"),
              settings.tapRow("Display Zoom") else {
            return missed("FIG-05-06", "could not reach Display Zoom")
        }
        capture("fig-05-06a-display-zoom-default", "Display Zoom, Default selected")

        guard settings.tapRow("Larger Text") else {
            return missed("FIG-05-06A", "no Larger Text option on Display Zoom")
        }
        sleep(2)
        capture("fig-05-06a2-display-zoom-larger-text-selected",
                "Display Zoom with Larger Text selected")

        // The brief calls the next step the Use Zoomed confirmation. Confirm
        // what the control is actually called rather than assuming.
        for candidate in ["Use Zoomed", "Set", "Done", "Continue"] {
            if settings.buttons[candidate].exists {
                claim("Display Zoom confirm control is labelled \(candidate)")
                settings.buttons[candidate].tap()
                sleep(3)
                capture("fig-05-06b-display-zoom-confirmation",
                        "The confirmation after choosing Larger Text")
                return
            }
        }
        claim("Display Zoom confirm control: none of Use Zoomed, Set, Done or Continue found")
        capture("fig-05-06b-display-zoom-no-confirm",
                "Display Zoom after choosing Larger Text, no confirm button found")
    }

    // MARK: - FIG-05-08  A On/Off Labels off.  B the same switch with labels on.

    func test_05_08_on_off_labels() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Accessibility"),
              settings.tapRow("Display & Text Size") else {
            return missed("FIG-05-08", "could not reach Display & Text Size")
        }
        captureSwitchPair(settings, row: "On/Off Labels",
                          "fig-05-08-on-off-labels",
                          "Accessibility >> Display & Text Size")
    }

    /// Not a briefed figure yet, but Show Borders is the one setting on this
    /// screen whose effect a reader cannot picture from a sentence.
    func test_05_09_show_borders() {
        let settings = SettingsApp.open()
        guard settings.tapRow("Accessibility"),
              settings.tapRow("Display & Text Size") else {
            return missed("show-borders", "could not reach Display & Text Size")
        }
        captureSwitchPair(settings, row: "Show Borders",
                          "unassigned-show-borders",
                          "Accessibility >> Display & Text Size")
    }

    // MARK: - FIG-22-03  A camera. B microphone. C contacts. D photos.

    func test_22_03_permission_categories() {
        let categories = [
            ("Camera",     "a"),
            ("Microphone", "b"),
            ("Contacts",   "c"),
            ("Photos",     "d")
        ]

        for (category, letter) in categories {
            let settings = SettingsApp.open()
            guard settings.tapRow("Privacy & Security") else {
                missed("FIG-22-03\(letter.uppercased())", "no Privacy & Security row")
                continue
            }
            guard settings.tapRow(category) else {
                missed("FIG-22-03\(letter.uppercased())",
                       "no \(category) row under Privacy & Security")
                continue
            }
            capture("fig-22-03\(letter)-\(category.lowercased())",
                    "Privacy & Security >> \(category), the list of apps that asked")
            inventory("privacy-\(category.lowercased())", settings.visibleRowLabels())
        }
    }

    // MARK: - FIG-04-06  Search with the keyboard open

    func test_04_06_spotlight() {
        guard Launcher.goHome(terminating: [SimApp.settings, SimApp.safari,
                                            SimApp.photos, SimApp.contacts]) else {
            return missed("FIG-04-06", "the Home Screen never drew")
        }
        capture("probe-home-confirmed", "The Home Screen, confirmed drawn before the swipe")

        let springboard = XCUIApplication(bundleIdentifier: SimApp.springboard)
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40))
        let end   = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(3)
        capture("fig-04-06-spotlight", "Search, after a swipe down on the Home Screen")

        // The keyboard is what the brief actually asks for, so type into it.
        if springboard.searchFields.firstMatch.exists {
            springboard.searchFields.firstMatch.tap()
            sleep(2)
            capture("fig-04-06b-spotlight-keyboard", "Search with the keyboard open")
        } else {
            missed("FIG-04-06B", "no search field found after the swipe")
        }
    }
}
