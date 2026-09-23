import XCTest

/// The apps the second run reached but could not photograph, because a
/// permission prompt raised by the previously launched app was still sitting
/// on screen. `Launcher.open` now clears prompts on the way in, and `capture`
/// clears them again before the shutter.
///
/// Each test also goes one screen deeper than the second run managed, because
/// the first screen of an empty app is rarely the screen the book needs.
final class AppCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - Contacts

    func test_01_contacts() {
        guard let contacts = Launcher.open(SimApp.contacts) else {
            return missed("contacts", "Contacts never reached the foreground")
        }
        capture("FIG-06-contacts-list",
                "Contacts. Apple's own invented sample names, no real personal data.")

        // A contact card is what Chapter 6 actually teaches.
        if contacts.tapRow("John Appleseed") {
            capture("FIG-06-contact-card", "A single contact card")
        } else {
            missed("contact-card", "could not open a contact")
        }
        contacts.terminate()
    }

    // MARK: - Passwords

    func test_02_passwords() {
        guard let passwords = Launcher.open(SimApp.passwords) else {
            return missed("passwords", "Passwords never reached the foreground")
        }
        capture("FIG-20-passwords-welcome", "The Passwords app on first launch")

        guard passwords.tapButton("Continue") else {
            passwords.terminate()
            return missed("passwords-list", "no Continue button on the welcome screen")
        }
        sleep(3)
        capture("FIG-20-passwords-list", "The Passwords list after Continue")
        inventory("passwords", passwords.visibleRowLabels())
        passwords.terminate()
    }

    // MARK: - Health and Medical ID

    /// The second run tapped a row that does not exist. Medical ID is offered
    /// as a Get Started button inside a card on the Summary screen.
    func test_03_medical_id() {
        guard let health = Launcher.open(SimApp.health, settle: 6) else {
            return missed("health", "Health never reached the foreground")
        }
        capture("FIG-24-health-summary",
                "Health on first launch, with the Set Up Your Medical ID card")

        var reached = false
        if health.tapButton("Get Started", timeout: 8) {
            reached = true
        } else if health.tapRow("Medical ID") {
            reached = true
        }

        if reached {
            sleep(3)
            capture("FIG-24-01-medical-id", "The Medical ID screen")
            inventory("medical-id", health.visibleRowLabels())
        } else {
            missed("FIG-24-01", "neither Get Started nor a Medical ID row could be tapped")
        }
        health.terminate()
    }

    // MARK: - Photos

    func test_04_photos() {
        guard let photos = Launcher.open(SimApp.photos, settle: 5) else {
            return missed("photos", "Photos never reached the foreground")
        }
        capture("FIG-16-photos-library",
                "Photos, Library tab. Apple's sample images, no people.")

        if photos.tapRow("Collections") {
            capture("FIG-16-photos-collections", "Photos, Collections tab")
        } else {
            missed("photos-collections", "could not reach the Collections tab")
        }
        photos.terminate()
    }

    // MARK: - Safari

    func test_05_safari() {
        guard let safari = Launcher.open(SimApp.safari, settle: 5) else {
            return missed("safari", "Safari never reached the foreground")
        }
        capture("FIG-10-safari-start-page",
                "Safari's start page, with the tab bar along the bottom")
        safari.terminate()
    }

    // MARK: - Wallet

    func test_06_wallet() {
        guard let wallet = Launcher.open(SimApp.wallet, settle: 5) else {
            return missed("wallet", "Wallet never reached the foreground")
        }
        capture("FIG-19-wallet-empty",
                "Wallet before any card is added. No card numbers appear anywhere.")
        wallet.terminate()
    }

    // MARK: - Maps

    func test_07_maps() {
        guard let maps = Launcher.open(SimApp.maps, settle: 6) else {
            return missed("maps", "Maps never reached the foreground")
        }
        capture("FIG-18-maps-opening", "Maps after the location prompt is declined")
        maps.terminate()
    }
}
