import SwiftUI

/// Host application for the UI test runner.
///
/// XCUITest bundles need a host app even when every test drives a system app
/// by bundle identifier. This app does nothing else and is never captured.
@main
struct SimShotHostApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("simshot")
                    .font(.largeTitle)
                Text("Host application for the UI test runner.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}
