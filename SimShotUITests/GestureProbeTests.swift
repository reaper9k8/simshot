import XCTest

/// Probes for the things the first run left unresolved. None of these is a
/// planned figure yet. The point is to find out what the runtime will and
/// will not do, so the answer comes from a screenshot rather than a guess.
///
/// This suite is run separately in CI and is allowed to fail without failing
/// the build.
final class GestureProbeTests: XCTestCase {

    private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: SimApp.springboard)
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func goHome() {
        XCUIDevice.shared.press(.home)
        sleep(3)
    }

    /// Drags between two points given as fractions of the screen, which keeps
    /// the gesture correct whichever model is booted.
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

    // MARK: - Home Screen

    func test_probe_01_home_screen() {
        goHome()
        capture("probe-home-screen",
                "Home Screen. Note that the test runner and host app now have icons here.")
    }

    // MARK: - Control Center, swipe down from the top right corner

    func test_probe_02_control_center() {
        goHome()
        drag(fromX: 0.93, y1: 0.004, toX: 0.93, y2: 0.55)
        capture("probe-control-center", "after a swipe down from the top right corner")
    }

    // MARK: - Notification Center, swipe down from the top left corner

    func test_probe_03_notification_center() {
        goHome()
        drag(fromX: 0.18, y1: 0.004, toX: 0.18, y2: 0.60)
        capture("probe-notification-center", "after a swipe down from the top left corner")
    }

    // MARK: - App Switcher, swipe up from the bottom edge and pause

    func test_probe_04_app_switcher() {
        _ = SettingsApp.open()
        sleep(2)
        drag(fromX: 0.5, y1: 0.999, toX: 0.5, y2: 0.55, hold: 1.2)
        capture("probe-app-switcher", "after a swipe up from the bottom edge with a pause")
    }

    // MARK: - Spotlight, swipe down on the middle of the Home Screen

    func test_probe_05_spotlight() {
        goHome()
        drag(fromX: 0.5, y1: 0.35, toX: 0.5, y2: 0.80)
        capture("probe-spotlight", "after a swipe down on the middle of the Home Screen")
    }

    // MARK: - App Library, swipe left past the last Home Screen page

    func test_probe_06_app_library() {
        goHome()
        for _ in 0..<3 {
            springboard.swipeLeft()
            sleep(1)
        }
        sleep(2)
        capture("probe-app-library", "after swiping left past the last Home Screen page")
    }

    // MARK: - Every app the runtime actually ships

    func test_probe_07_apps_that_exist() {
        let apps: [(id: String, name: String)] = [
            (SimApp.contacts,  "contacts"),
            (SimApp.messages,  "messages"),
            (SimApp.passwords, "passwords"),
            (SimApp.health,    "health"),
            (SimApp.safari,    "safari"),
            (SimApp.maps,      "maps"),
            (SimApp.photos,    "photos"),
            (SimApp.wallet,    "wallet"),
            (SimApp.calendar,  "calendar"),
            (SimApp.reminders, "reminders"),
            (SimApp.files,     "files")
        ]

        for app in apps {
            let target = XCUIApplication(bundleIdentifier: app.id)
            target.terminate()
            target.launch()
            let reached = target.wait(for: .runningForeground, timeout: 40)
            sleep(4)
            capture("probe-app-\(app.name)",
                    reached ? "launched \(app.id)"
                            : "did NOT reach the foreground: \(app.id)")
            target.terminate()
            sleep(1)
        }
    }

    // MARK: - Health, on the way to Medical ID

    /// Medical ID is FIG-24-01. Health is present on this runtime, so the
    /// question is only whether the screen can be reached without an account.
    func test_probe_08_medical_id() {
        let health = XCUIApplication(bundleIdentifier: SimApp.health)
        health.terminate()
        health.launch()
        _ = health.wait(for: .runningForeground, timeout: 40)
        sleep(5)
        capture("probe-health-launch", "Health on first launch")

        if health.scrollToRow("Medical ID") != nil {
            _ = health.tapRow("Medical ID")
            sleep(3)
            capture("probe-medical-id", "after tapping Medical ID")
        } else {
            missed("probe-medical-id", "no Medical ID row reachable from the first screen")
        }
    }
}
