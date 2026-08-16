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

/// UI coverage for the Compatibility demo application.
///
/// Each launch renders one real demo page so coverage does not depend on how a platform exposes
/// page-style TabView controls to XCTest. Interactive pages also exercise representative controls.
final class CompatibilityUITests: XCTestCase {
    private struct DemoScreen {
        let index: Int
        let name: String
        let identifier: String
    }

    private let screens = [
        DemoScreen(index: 0, name: "Compatibility", identifier: "demo.compatibility"),
        DemoScreen(index: 1, name: "DataStore", identifier: "demo.datastore"),
        DemoScreen(index: 2, name: "All Tests", identifier: "demo.allTests"),
        DemoScreen(index: 3, name: "Closure", identifier: "demo.closure"),
        DemoScreen(index: 4, name: "Random Bytes", identifier: "demo.randomBytes"),
        DemoScreen(index: 5, name: "Convert", identifier: "demo.convert"),
        DemoScreen(index: 6, name: "Triangle Showcase", identifier: "demo.triangle"),
        DemoScreen(index: 7, name: "Fill & Stroke", identifier: "demo.fillAndStroke"),
        DemoScreen(index: 8, name: "Placard Showcase", identifier: "demo.placard"),
        DemoScreen(index: 9, name: "Material", identifier: "demo.material"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveryDemoScreenAndRepresentativeInteractions() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launchEnvironment["TESTING"] = "1"

        for screen in screens {
            app.launchEnvironment["COMPATIBILITY_DEMO_TAB"] = String(screen.index)
            app.launch()

            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "\(screen.name) should launch into the foreground.")
            XCTAssertTrue(
                app.descendants(matching: .any)[screen.identifier].waitForExistence(timeout: 10),
                "\(screen.name) should render its demo screen."
            )

            exercise(screen: screen, in: app)
            app.terminate()
        }
    }

    @MainActor
    private func exercise(screen: DemoScreen, in app: XCUIApplication) {
        switch screen.index {
        case 0:
            // Rendering the environment page exercises its application/module fields and environment presentation.
            break

        case 1:
            // DataStore is a long form. Scrolling forces lazy rows and their bindings to render.
            scrollThroughCurrentScreen(in: app, passes: 5)

        case 2:
            // The complete test list is deliberately long; traverse it so off-screen test rows are rendered.
            scrollThroughCurrentScreen(in: app, passes: 12)

        case 3:
            // Open the real menu when exposed so Menu callbacks and menu-item construction are covered.
            let symbols = app.buttons["Symbols"]
            if symbols.waitForExistence(timeout: 2) && symbols.isHittable {
                symbols.backport.tap()
                let star = app.buttons["star"]
                if star.waitForExistence(timeout: 2) && star.isHittable {
                    star.backport.tap()
                }
            }

        case 4:
            // Random Bytes is a List, so scrolling renders the full range of BytesView rows.
            scrollThroughCurrentScreen(in: app, passes: 6)

        case 5:
            // Exercise Binding.convert through the Convert screen's slider.
            let slider = app.sliders.firstMatch
            if slider.waitForExistence(timeout: 2) {
                slider.adjust(toNormalizedSliderPosition: 0.75)
            }

        case 6:
            // Exercise Triangle drawing and navigationDestination, then return to the showcase.
            let button = app.buttons.firstMatch
            if button.waitForExistence(timeout: 2) && button.isHittable {
                button.backport.tap()
                let destination = app.buttons["Navigation Destination TestCase"]
                if destination.waitForExistence(timeout: 2) {
                    destination.backport.tap()
                }
            }

        case 7, 8, 9:
            // These pages are primarily visual; rendering them is the behavior under test.
            break

        default:
            XCTFail("Unexpected Compatibility demo screen index: \(screen.index)")
        }
    }

    @MainActor
    private func scrollThroughCurrentScreen(in app: XCUIApplication, passes: Int) {
        let scrollView = app.scrollViews.firstMatch
        let table = app.tables.firstMatch
        let collection = app.collectionViews.firstMatch

        let scrollable: XCUIElement
        if scrollView.exists {
            scrollable = scrollView
        } else if table.exists {
            scrollable = table
        } else if collection.exists {
            scrollable = collection
        } else {
            scrollable = app
        }

        for _ in 0..<passes {
            scrollable.swipeUp()
        }
        for _ in 0..<(passes / 2) {
            scrollable.swipeDown()
        }
    }
}
#endif
