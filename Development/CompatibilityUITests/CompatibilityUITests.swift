//
//  CompatibilityUITests.swift
//  CompatibilityUITests
//
//  Created by Codex on 7/7/26.
//
#if canImport(XCTest)
import XCTest

/// Adds Compatibility-style backports to XCTest elements without making the shipping library depend on XCTest.
private struct XCUIElementBackport {
    let element: XCUIElement

    /// Activates the element on pointer-driven platforms and selects the focused item on tvOS.
    @MainActor
    func tap() {
#if os(tvOS)
        // XCUIElement.tap() is unavailable on tvOS; remote Select is the platform's equivalent activation gesture.
        if element.hasFocus {
            XCUIRemote.shared.press(.select)
        }
#else
        element.tap()
#endif
    }
}

private extension XCUIElement {
    /// Compatibility namespace for XCTest APIs whose availability differs by platform.
    var backport: XCUIElementBackport { XCUIElementBackport(element: self) }
}

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
        // UI tests run out of process, so explicitly pass the generic testing environment to the app under test.
        app.launchEnvironment["TESTING"] = "1"
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
            button.backport.tap()
            return
        }

        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 1) {
            text.backport.tap()
        }
    }
}
#endif
