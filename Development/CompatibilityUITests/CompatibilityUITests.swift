//
//  CompatibilityUITests.swift
//  CompatibilityUITests
//
//  Created by Codex on 7/7/26.
//
#if canImport(XCTest)
import XCTest

/// Smoke tests for the Compatibility demo application.
///
/// These tests intentionally launch the real demo app instead of constructing
/// views directly so Xcode coverage sees the SwiftUI app, scene, tab container,
/// and first visible content path as user-facing code.
final class CompatibilityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoAppLaunchesAndShowsCompatibilityContent() throws {
        let app = XCUIApplication()

        // Ignore saved state so the smoke test starts from the same first tab
        // even when Xcode or a previous manual run restored another demo page.
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "CompatibilityTest app should launch into the foreground.")

        // The first tab renders environment/application sections, which proves
        // the app scene and core Compatibility SwiftUI demo path are visible.
        XCTAssertTrue(waitForAnyText(["Application", "Compatibility", "iCloud"], in: app), "The Compatibility demo should show its first-page sections.")

        // Tapping exposed tab labels exercises additional demo pages on
        // platforms where SwiftUI exposes the page/tab controls to UI testing.
        for tabName in ["DataStore", "All Tests", "Closure", "Random Bytes", "Convert"] {
            tapIfPresent(tabName, in: app)
        }
    }

    @MainActor
    private func waitForAnyText(_ labels: [String], in app: XCUIApplication, timeout: TimeInterval = 10) -> Bool {
        for label in labels {
            if app.staticTexts[label].waitForExistence(timeout: timeout) {
                return true
            }
        }
        return false
    }

    @MainActor
    private func tapIfPresent(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 1) {
            button.tap()
            return
        }

        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 1) {
            text.tap()
        }
    }
}
#endif
