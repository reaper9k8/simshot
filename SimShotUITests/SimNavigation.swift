import XCTest
import UIKit

/// Bundle identifiers, taken from `xcrun simctl listapps` on the iOS 27.0
/// runtime. Only identifiers confirmed present on that runtime appear here.
enum SimApp {
    static let settings    = "com.apple.Preferences"
    static let springboard = "com.apple.springboard"

    static let contacts = "com.apple.MobileAddressBook"
    static let messages = "com.apple.MobileSMS"
    static let passwords = "com.apple.Passwords"
    static let health   = "com.apple.Health"
    static let safari   = "com.apple.mobilesafari"
    static let maps     = "com.apple.Maps"
    static let photos   = "com.apple.mobileslideshow"
    static let wallet   = "com.apple.Passbook"
    static let calendar = "com.apple.mobilecal"
    static let reminders = "com.apple.reminders"
    static let files    = "com.apple.DocumentsApp"
}

// MARK: - Finding and driving rows

extension XCUIApplication {

    /// Matches an element of one type whose accessibility identifier or label
    /// is exactly `label`. `firstMatch` keeps the query unambiguous, which
    /// matters because Settings repeats labels inside nested containers.
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

    /// Scrolls to the named row and taps it. Returns false when the row is
    /// not present, which is itself a result worth recording.
    @discardableResult
    func tapRow(_ label: String) -> Bool {
        guard let element = scrollToRow(label) else { return false }
        element.tap()
        return true
    }

    /// Sets a switch to a wanted state. Returns false when no switch by that
    /// name exists, or when the tap did not change it.
    @discardableResult
    func setSwitch(_ label: String, on wanted: Bool) -> Bool {
        guard scrollToRow(label) != nil else { return false }

        let predicate = NSPredicate(format: "identifier == %@ OR label == %@", label, label)
        let toggle = switches.matching(predicate).firstMatch
        guard toggle.exists else { return false }

        if ((toggle.value as? String) == "1") != wanted {
            toggle.tap()
            usleep(800_000)
        }
        return ((toggle.value as? String) == "1") == wanted
    }

    /// Walks back up the navigation stack until the root screen is showing.
    /// Checks before tapping, so calling this at the root does nothing.
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
    func visibleRowLabels() -> [String] {
        descendants(matching: .cell)
            .allElementsBoundByIndex
            .map { $0.label }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Launching Settings from a known state

enum SettingsApp {

    /// Terminates and relaunches Settings, then pops to the root list, so
    /// every test starts from the same place regardless of what ran before.
    static func open() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: SimApp.settings)
        app.terminate()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 60)
        usleep(1_500_000)
        app.popToRoot()
        return app
    }
}

// MARK: - Capturing

extension XCTestCase {

    /// Captures the whole screen, attaches it under `name`, and prints the
    /// pixel dimensions so the CI log can prove nothing was downscaled.
    ///
    /// The `SHOT__` prefix is what the extraction script filters on, which
    /// keeps our deliberate captures apart from the automatic ones XCTest
    /// adds when a step fails.
    /// `SHOT_SUFFIX` is set by CI when the same screens are captured again
    /// under a different simulator state, such as dark mode or a large text
    /// size, so the two sets of files do not collide.
    @discardableResult
    func capture(_ name: String, _ note: String = "") -> CGSize {
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

    /// Records a screen that could not be reached. The run carries on, because
    /// a missing row is information rather than a build failure.
    func missed(_ name: String, _ reason: String) {
        print("MISSED\t\(name)\t\(reason)")
        XCTContext.runActivity(named: "MISSED \(name): \(reason)") { _ in }
    }

    /// Records a finding about an interface label that the book asserts.
    func claim(_ text: String) {
        print("CLAIM\t\(text)")
        XCTContext.runActivity(named: "CLAIM \(text)") { _ in }
    }
}
