import XCTest

/// Gestures, and the two permission prompts the second run captured by
/// accident. Those prompts turned out to be worth having on purpose: Apple
/// publishes no list of the per app location choices, and the prompt shows
/// them.
///
/// Screens the second run settled are not repeated. The Home Screen, Control
/// Center and App Library are all too sparse to print and no change to this
/// script would fix that.
final class GestureProbeTests: XCTestCase {

    private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: SimApp.springboard)
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        // Never leave a prompt on screen for the next test to inherit.
        Alerts.dismissAll()
    }

    private func drag(fromX x1: CGFloat, y1: CGFloat,
                      toX x2: CGFloat, y2: CGFloat,
                      hold: TimeInterval = 0) {
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: x1, dy: y1))
        let end   = springboard.coordinate(withNormalizedOffset: CGVector(dx: x2, dy: y2))
        if hold > 0 {
            start.press(forDuration: 0.12,
                        thenDragTo: end,
                        withVelocity: .slow,
                        thenHoldForDuration: hold)
        } else {
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        sleep(3)
    }

    // MARK: - App Switcher, with enough cards to be worth looking at

    /// The second run produced an App Switcher holding one card, which teaches
    /// a reader nothing about switching between apps. Open several first.
    func test_probe_01_app_switcher_with_several_apps() {
        let sequence = [SimApp.contacts, SimApp.photos, SimApp.safari, SimApp.settings]
        for bundleID in sequence {
            _ = Launcher.open(bundleID, settle: 3)
        }

        drag(fromX: 0.5, y1: 0.999, toX: 0.5, y2: 0.55, hold: 1.2)
        capture("FIG-04-app-switcher",
                "The App Switcher after opening four apps in turn")
    }

    // MARK: - Spotlight, with the Home press made deterministic

    /// The second run captured the Settings list here, because pressing Home
    /// did not take while an app held the foreground.
    func test_probe_02_spotlight() {
        Launcher.goHome(terminating: [SimApp.settings, SimApp.safari,
                                      SimApp.photos, SimApp.contacts])
        capture("probe-home-before-spotlight",
                "Confirms the Home Screen really is showing before the swipe")

        drag(fromX: 0.5, y1: 0.35, toX: 0.5, y2: 0.80)
        capture("FIG-04-spotlight", "After a swipe down on the middle of the Home Screen")
    }

    // MARK: - The permission prompts, captured on purpose

    /// Apple publishes no list of the per app location choices, and the book
    /// is currently barred from naming them. The prompt names them.
    func test_probe_08_location_permission_prompt() {
        let maps = XCUIApplication(bundleIdentifier: SimApp.maps)
        maps.terminate()
        maps.launch()
        _ = maps.wait(for: .runningForeground, timeout: 45)
        sleep(5)

        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 15) else {
            maps.terminate()
            return missed("location-prompt", "no location prompt appeared")
        }

        capture("FIG-22-05-location-prompt",
                "The location permission prompt, with all three choices",
                keepAlerts: true)
        inventory("location-prompt", alert.buttons.allElementsBoundByIndex.map { $0.label })

        Alerts.dismissAll(in: maps)
        maps.terminate()
    }

    func test_probe_09_notification_permission_prompt() {
        let health = XCUIApplication(bundleIdentifier: SimApp.health)
        health.terminate()
        health.launch()
        _ = health.wait(for: .runningForeground, timeout: 45)
        sleep(6)

        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 15) else {
            health.terminate()
            return missed("notification-prompt", "no notification prompt appeared")
        }

        capture("FIG-22-06-notification-prompt",
                "The notification permission prompt",
                keepAlerts: true)
        inventory("notification-prompt", alert.buttons.allElementsBoundByIndex.map { $0.label })

        Alerts.dismissAll(in: health)
        health.terminate()
    }
}
