import XCTest

/// The app screens still missing after round 5.
///
/// Round 5 reached every app but photographed six welcome sheets instead of the
/// apps behind them. `Launcher.open` now taps through those, so each test here
/// starts on the app proper.
///
/// Already captured, verified and filed, so NOT repeated: the Contacts list and
/// contact card, Wallet before any card, and the Passwords first launch screen.
final class AppCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - FIG-16-01  A the Library tab.  B the Collections tab.

    func test_01_photos_library_and_collections() {
        guard let photos = Launcher.open(SimApp.photos, settle: 5) else {
            return missed("FIG-16-01", "Photos never reached the foreground")
        }
        capture("fig-16-01a-photos-library",
                "Photos, Library tab. Apple's sample landscapes, no people.")

        guard photos.tapRow("Collections") else {
            photos.terminate()
            return missed("FIG-16-01B", "could not reach the Collections tab")
        }
        capture("fig-16-01b-photos-collections",
                "Photos, Collections tab: Albums, Recent Days, People & Pets, Memories, Utilities")
        inventory("photos-collections", photos.visibleRowLabels())
        photos.terminate()
    }

    // MARK: - FIG-20-05 A  The Passwords list

    func test_02_passwords_list() {
        guard let passwords = Launcher.open(SimApp.passwords, settle: 5) else {
            return missed("FIG-20-05A", "Passwords never reached the foreground")
        }
        // The welcome sheets and the lock screen are behind Continue and
        // Unlock, which Launcher.open already taps. Anything left, take now.
        Launcher.dismissOnboarding(in: passwords)
        sleep(2)
        capture("fig-20-05a-passwords-list",
                "The Passwords list: All, Passkeys, Codes, Wi-Fi, Security, Deleted")
        inventory("passwords-list", passwords.visibleRowLabels())
        passwords.terminate()
    }

    // MARK: - FIG-10-01 and FIG-10-02  Safari on a real page

    /// The brief wants Safari on a plain page, not its start page. example.com
    /// is reserved by IANA for documentation, so it carries no company's
    /// branding and cannot change under us.
    func test_03_safari_on_a_page() {
        guard let safari = Launcher.open(SimApp.safari, settle: 5) else {
            return missed("FIG-10-01", "Safari never reached the foreground")
        }

        let field = safari.textFields.firstMatch
        guard field.waitForExistence(timeout: 10) else {
            safari.terminate()
            return missed("FIG-10-01", "no address field found")
        }
        field.tap()
        sleep(2)
        capture("fig-10-02a-safari-typing", "Typing a web address, with the keyboard open")

        field.typeText("example.com\n")
        sleep(8)
        capture("fig-10-01-safari-on-a-page",
                "Safari showing example.com, with the address bar and tabs button")
        safari.terminate()
    }

    // MARK: - Maps, once past the welcome sheet

    func test_04_maps() {
        guard let maps = Launcher.open(SimApp.maps, settle: 6) else {
            return missed("maps", "Maps never reached the foreground")
        }
        Launcher.dismissOnboarding(in: maps)
        sleep(4)
        capture("unassigned-maps-opening",
                "Maps after the welcome sheet and the location prompt are dismissed")
        maps.terminate()
    }

    // MARK: - FIG-24-01  Medical ID with invented details

    /// The brief asks for a Medical ID carrying invented details, with Show
    /// When Locked on and emergency contacts. Round 5 reached only the empty
    /// Edit Information sheet.
    ///
    /// The name typed here is invented, and the front matter already carries
    /// the notice that every detail shown in this book is invented.
    func test_05_medical_id() {
        guard let health = Launcher.open(SimApp.health, settle: 6) else {
            return missed("FIG-24-01", "Health never reached the foreground")
        }

        var reached = health.tapButton("Get Started", timeout: 10)
        if !reached { reached = health.tapRow("Medical ID") }
        guard reached else {
            health.terminate()
            return missed("FIG-24-01", "could not open Medical ID")
        }
        sleep(3)
        capture("fig-24-01a-medical-id-empty", "Medical ID, Edit Information, nothing filled in")

        // Type an invented name so the card is not blank.
        if health.tapRow("Name") {
            sleep(2)
            let field = health.textFields.firstMatch
            if field.waitForExistence(timeout: 8) {
                field.tap()
                field.typeText("Margaret Sample")
                sleep(2)
                capture("fig-24-01b-medical-id-name", "An invented name typed into Medical ID")
            } else {
                missed("FIG-24-01B", "no text field appeared for Name")
            }
        }

        // Confirm, then photograph the card itself.
        for title in ["Done", "Save"] {
            if health.buttons[title].firstMatch.exists {
                health.buttons[title].firstMatch.tap()
                sleep(3)
                break
            }
        }
        capture("fig-24-01c-medical-id-card", "The Medical ID card after saving")

        if health.scrollToRow("Show When Locked") != nil {
            capture("fig-24-01d-show-when-locked", "The Show When Locked switch on the Medical ID screen")
        } else {
            missed("FIG-24-01D", "no Show When Locked row found")
        }
        inventory("medical-id-final", health.visibleRowLabels())
        health.terminate()
    }
}
