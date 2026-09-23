import XCTest
import UIKit

/// Bundle identifiers, taken from `xcrun simctl listapps` on the iOS 27.0
/// runtime. Only identifiers confirmed present on that runtime appear here.
enum SimApp {
    static let settings    = "com.apple.Preferences"
    static let springboard = "com.apple.springboard"

    static let contacts  = "com.apple.MobileAddressBook"
    static let messages  = "com.apple.MobileSMS"
    static let passwords = "com.apple.Passwords"
    static let health    = "com.apple.Health"
    static let safari    = "com.apple.mobilesafari"
    static let maps      = "com.apple.Maps"
    static let photos    = "com.apple.mobileslideshow"
    static let wallet    = "com.apple.Passbook"
    static let calendar  = "com.apple.mobilecal"
    static let reminders = "com.apple.reminders"
    static let files     = "com.apple.DocumentsApp"
}

// MARK: - Alerts

/// A permission prompt raised by one app stays on screen and follows the user
/// into the next one. The second run lost seven captures that way, so alerts
/// are now cleared before every capture rather than hoped away.
enum Alerts {

    /// Buttons in order of preference. Declining comes first, because the book
    /// must never imply that granting a permission is the expected answer.
    private static let preferred = [
        "Don't Allow", "Don\u{2019}t Allow", "Not Now", "Later",
        "Cancel", "Dismiss", "OK", "Close", "Continue", "Allow Once"
    ]

    @discardableResult
    static func dismissAll(in app: XCUIApplication? = nil, rounds: Int = 6) -> Int {
        var dismissed = 0
        var owners = [XCUIApplication(bundleIdentifier: SimApp.springboard)]
        if let app = app { owners.append(app) }

        for _ in 0..<rounds {
            var actedThisRound = false

            for owner in owners {
                let alert = owner.alerts.firstMatch
                guard alert.exists else { continue }

                var tapped = false
                for title in preferred {
                    let button = alert.buttons[title]
                    if button.exists, button.isHittable {
                        button.tap()
                        tapped = true
                        break
                    }
                }

                if !tapped {
                    // Fall back to the last button, conventionally the least
                    // destructive default.
                    let count = alert.buttons.count
                    guard count > 0 else { continue }
                    let button = alert.buttons.element(boundBy: count - 1)
                    guard button.exists, button.isHittable else { continue }
                    button.tap()
                }

                dismissed += 1
                actedThisRound = true
                usleep(1_200_000)
            }

            if !actedThisRound { break }
        }

        if dismissed > 0 { print("ALERTS\tdismissed \(dismissed)") }
        return dismissed
    }
}

// MARK: - Finding and driving rows

extension XCUIApplication {

    private func exactMatch(_ type: XCUIElement.ElementType, _ label: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ OR label == %@", label, label)
        return descendants(matching: type).matching(predicate).firstMatch
    }

    /// Settings rows surface as different element types depending on the iOS
    /// release and on where the row sits, so try each type in turn. The final
    /// fallback is a prefix match, which catches rows whose label carries the
    /// current value after the title, such as "Text Size, Large".
    func row(_ label: String) -> XCUIElement? {
        let types: [XCUIElement.ElementType] = [.cell, .button, .staticText, .other]
        for type in types {
            let element = exactMatch(type, label)
            if element.exists { return element }
        }
        let prefix = NSPredicate(format: "label BEGINSWITH[c] %@", label)
        let loose = descendants(matching: .any).matching(prefix).firstMatch
        return loose.exists ? loose : nil
    }

    /// Scrolls until the named row is on screen and can be tapped. Searches
    /// downward first, then back upward, then gives up rather than looping.
    @discardableResult
    func scrollToRow(_ label: String, maxSwipes: Int = 14) -> XCUIElement? {
        if let found = row(label), found.isHittable { return found }

        for _ in 0..<maxSwipes {
            swipeUp()
            if let found = row(label), found.isHittable { return found }
        }
        for _ in 0..<(maxSwipes + 6) {
            swipeDown()
            if let found = row(label), found.isHittable { return found }
        }
        return nil
    }

    @discardableResult
    func tapRow(_ label: String) -> Bool {
        guard let element = scrollToRow(label) else { return false }
        element.tap()
        usleep(1_500_000)
        return true
    }

    /// Taps a button by its visible title, for screens whose controls are
    /// buttons inside a card rather than rows in a list. Health's Medical ID
    /// card and the Passwords welcome screen both need this.
    @discardableResult
    func tapButton(_ title: String, timeout: TimeInterval = 10) -> Bool {
        let button = buttons[title].firstMatch
        if button.waitForExistence(timeout: timeout), button.isHittable {
            button.tap()
            usleep(1_500_000)
            return true
        }
        guard let fallback = scrollToRow(title) else { return false }
        fallback.tap()
        usleep(1_500_000)
        return true
    }

    /// Taps the switch that belongs to a named row.
    ///
    /// Two earlier attempts failed. Looking the switch up by name fails
    /// because in iOS 27 Settings the row carries the accessibility label and
    /// the switch carries none. Enumerating every switch to find the aligned
    /// one crashed the third run outright, because the element list goes stale
    /// while the list is still settling:
    ///
    ///     Failed to get matching snapshot: No matches found for Element at
    ///     index 3
    ///
    /// So no enumeration. The row is found by name, and the tap lands across
    /// from it at the right hand end of the screen, where a Settings switch
    /// always sits. The vertical position comes from the row, so it follows
    /// the row when the row moves.
    @discardableResult
    func tapSwitch(besideRow label: String) -> Bool {
        guard let rowElement = scrollToRow(label) else {
            print("SWITCH\t\(label)\trow not found")
            return false
        }
        usleep(1_000_000)

        let rowFrame = rowElement.frame
        let screen = frame
        guard screen.height > 0, rowFrame.height > 0 else {
            print("SWITCH\t\(label)\tno usable frame")
            return false
        }

        let dy = rowFrame.midY / screen.height
        guard dy > 0.02, dy < 0.98 else {
            print("SWITCH\t\(label)\trow is too close to an edge to tap safely")
            return false
        }

        coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: dy)).tap()
        usleep(2_500_000)
        print("SWITCH\t\(label)\ttapped at dy \(String(format: "%.3f", dy))")
        return true
    }

    /// Walks back up the navigation stack until the root screen is showing.
    func popToRoot(rootTitle: String = "Settings") {
        for _ in 0..<8 {
            if navigationBars[rootTitle].exists { return }
            let back = navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.isHittable else { return }
            back.tap()
            usleep(500_000)
        }
    }

    /// Every distinct row label currently in the accessibility tree.
    ///
    /// The second run returned nothing here because it asked only for `cell`
    /// elements, and iOS 27 Settings does not use them. Ask for every type a
    /// row can be.
    func visibleRowLabels() -> [String] {
        var seen: [String] = []
        for type in [XCUIElement.ElementType.cell, .button, .staticText] {
            for element in descendants(matching: type).allElementsBoundByIndex {
                let label = element.label.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !label.isEmpty, !seen.contains(label) else { continue }
                seen.append(label)
            }
        }
        return seen
    }
}

// MARK: - Launching from a known state

enum SettingsApp {

    /// Terminates and relaunches Settings, clears any alert left behind by an
    /// earlier app, then pops to the root list.
    static func open() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: SimApp.settings)
        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 60)
        usleep(1_500_000)
        Alerts.dismissAll(in: app)
        app.popToRoot()
        return app
    }
}

enum Launcher {

    /// Launches an app and clears whatever prompt it or its predecessor put on
    /// screen. Returns nil when the app never reached the foreground.
    static func open(_ bundleID: String, settle: UInt32 = 4) -> XCUIApplication? {
        let app = XCUIApplication(bundleIdentifier: bundleID)
        app.terminate()
        app.launch()
        guard app.wait(for: .runningForeground, timeout: 45) else { return nil }
        sleep(settle)
        Alerts.dismissAll(in: app)
        sleep(1)
        return app
    }

    /// Returns to the Home Screen and waits until it has actually drawn.
    ///
    /// Terminating the apps first was not enough: the third run photographed a
    /// blank white screen here, because a fixed sleep expired before
    /// SpringBoard had rendered. Wait for the icons instead of trusting a
    /// clock.
    @discardableResult
    static func goHome(terminating bundleIDs: [String] = []) -> Bool {
        for id in bundleIDs {
            XCUIApplication(bundleIdentifier: id).terminate()
        }
        Alerts.dismissAll()

        let springboard = XCUIApplication(bundleIdentifier: SimApp.springboard)
        for attempt in 1...4 {
            XCUIDevice.shared.press(.home)
            sleep(3)
            if springboard.icons.count > 0 {
                sleep(2)
                print("HOME\treached after \(attempt) attempt(s), \(springboard.icons.count) icons")
                return true
            }
            print("HOME\tattempt \(attempt): no icons drawn yet")
        }
        print("HOME\tnever drew any icons")
        return false
    }
}

// MARK: - Capturing

extension XCTestCase {

    /// Captures the whole screen, attaches it under `name`, and prints the
    /// pixel dimensions so the CI log can prove nothing was downscaled.
    ///
    /// Any alert on screen is cleared first, unless `keepAlerts` is set,
    /// which is how the permission prompt figures are captured deliberately.
    @discardableResult
    func capture(_ name: String, _ note: String = "", keepAlerts: Bool = false) -> CGSize {
        if !keepAlerts { Alerts.dismissAll() }

        let shot = XCUIScreen.main.screenshot()

        let suffix = ProcessInfo.processInfo.environment["SHOT_SUFFIX"]
            .flatMap { $0.isEmpty ? nil : "__" + $0 } ?? ""
        let fullName = name + suffix

        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "SHOT__" + fullName
        attachment.lifetime = .keepAlways
        add(attachment)

        let image = shot.image
        let pixels = CGSize(width:  image.size.width  * image.scale,
                            height: image.size.height * image.scale)

        print("CAPTURE\t\(fullName)\t\(Int(pixels.width))x\(Int(pixels.height))\t\(note)")
        return pixels
    }

    /// Captures a scrolling list, stopping as soon as the screen stops
    /// changing.
    ///
    /// The third run still took six pictures of a two screen list. The reason
    /// was that it compared one screenshot and saved a different one taken a
    /// moment later, so a rubber band bounce made every comparison look like a
    /// change. One screenshot per pass now, compared and saved.
    @discardableResult
    func captureScrolling(_ app: XCUIApplication,
                          _ baseName: String,
                          _ note: String,
                          maxScreens: Int = 6) -> Int {
        let letters = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let suffix = ProcessInfo.processInfo.environment["SHOT_SUFFIX"]
            .flatMap { $0.isEmpty ? nil : "__" + $0 } ?? ""

        var previous: Data?
        var taken = 0

        for index in 0..<min(maxScreens, letters.count) {
            Alerts.dismissAll(in: app)
            sleep(2)                      // let any bounce settle before looking

            let shot = XCUIScreen.main.screenshot()
            let data = shot.pngRepresentation

            if let previous = previous, previous == data {
                print("SCROLL\t\(baseName)\tbottom reached after \(taken) screen(s)")
                break
            }
            previous = data

            let name = "\(baseName)\(letters[index])\(suffix)"
            let attachment = XCTAttachment(screenshot: shot)
            attachment.name = "SHOT__" + name
            attachment.lifetime = .keepAlways
            add(attachment)

            let image = shot.image
            print("CAPTURE\t\(name)\t\(Int(image.size.width * image.scale))x\(Int(image.size.height * image.scale))\t\(note), screen \(index + 1)")
            taken += 1

            app.swipeUp()
            sleep(2)
        }
        return taken
    }

    /// Photographs a switch row in both states.
    ///
    /// Reading a switch's value is unreliable in iOS 27 Settings, so nothing
    /// here depends on reading it. Both states are captured and the right one
    /// is chosen afterwards by looking at the two pictures.
    @discardableResult
    func captureSwitchPair(_ app: XCUIApplication,
                           row rowLabel: String,
                           _ baseName: String,
                           _ note: String) -> Bool {
        guard app.scrollToRow(rowLabel) != nil else {
            missed(baseName, "no \(rowLabel) row on this screen")
            return false
        }
        sleep(1)
        capture("\(baseName)-1", "\(note). \(rowLabel) before tapping.")

        guard app.tapSwitch(besideRow: rowLabel) else {
            missed(baseName, "could not tap the switch beside \(rowLabel)")
            return false
        }
        sleep(3)
        capture("\(baseName)-2", "\(note). \(rowLabel) after tapping.")

        // Put it back, re-finding the row because turning some of these on
        // relays the whole screen.
        _ = app.tapSwitch(besideRow: rowLabel)
        sleep(2)
        return true
    }

    /// Records a screen that could not be reached. The run carries on.
    func missed(_ name: String, _ reason: String) {
        print("MISSED\t\(name)\t\(reason)")
        XCTContext.runActivity(named: "MISSED \(name): \(reason)") { _ in }
    }

    /// Records a finding about an interface label that the book asserts.
    func claim(_ text: String) {
        print("CLAIM\t\(text)")
        XCTContext.runActivity(named: "CLAIM \(text)") { _ in }
    }

    /// Records a list of row labels found on a screen.
    func inventory(_ screen: String, _ labels: [String]) {
        print("INVENTORY\t\(screen)\t\(labels.joined(separator: " | "))")

        let attachment = XCTAttachment(string: labels.joined(separator: "\n"))
        attachment.name = "rows-\(screen).txt"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
