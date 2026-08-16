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
/// The app launches once and the test advances through the real page-style `TabView` in declaration order.
/// This deliberately avoids numeric selection tags so inserting or rearranging demo tabs does not require
/// keeping a second set of tab indices synchronized.
final class CompatibilityUITests: XCTestCase {
    private struct DemoScreen {
        let name: String
        let identifier: String
    }

    private let screens = [
        DemoScreen(name: "Compatibility", identifier: "demo.compatibility"),
        DemoScreen(name: "DataStore", identifier: "demo.datastore"),
        DemoScreen(name: "All Tests", identifier: "demo.allTests"),
        DemoScreen(name: "Closure", identifier: "demo.closure"),
        DemoScreen(name: "Random Bytes", identifier: "demo.randomBytes"),
        DemoScreen(name: "Convert", identifier: "demo.convert"),
        DemoScreen(name: "Triangle Showcase", identifier: "demo.triangle"),
        DemoScreen(name: "Fill & Stroke", identifier: "demo.fillAndStroke"),
        DemoScreen(name: "Placard Showcase", identifier: "demo.placard"),
        DemoScreen(name: "Material", identifier: "demo.material"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveryDemoScreenAndRepresentativeInteractions() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launchEnvironment["TESTING"] = "1"
        app.launch()

        // `launch()` does not return until the application is running in the foreground, so an
        // additional blocking application-state wait is unnecessary and can trigger a performance diagnostic.
        for (index, screen) in screens.enumerated() {
            let screenElement = app.descendants(matching: .any)[screen.identifier]
            XCTAssertTrue(
                screenElement.waitForExistence(timeout: 10),
                "\(screen.name) should render its demo screen."
            )

            exercise(screenAt: index, in: app)

            if index < screens.count - 1 {
                advanceToNextPage(in: app)
            }
        }
    }

    @MainActor
    private func exercise(screenAt index: Int, in app: XCUIApplication) {
        switch index {
        case 0, 1, 4, 7, 8, 9:
            // These pages are primarily exercised by rendering. Keep the UI tour fast and avoid
            // synthetic scrolling where there is no behavior we specifically need to validate.
            break

        case 2:
            // The complete test list is deliberately long; traverse it so off-screen test rows are rendered.
            scrollThroughAllTests(in: app)

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

        default:
            XCTFail("Unexpected Compatibility demo screen index: \(index)")
        }
    }

    @MainActor
    private func advanceToNextPage(in app: XCUIApplication) {
#if os(tvOS)
        XCUIRemote.shared.press(.right)
#else
        app.swipeLeft()
#endif
    }

    @MainActor
    private func scrollThroughAllTests(in app: XCUIApplication) {
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

        for _ in 0..<12 {
            scrollable.swipeUp()
        }
        for _ in 0..<6 {
            scrollable.swipeDown()
        }
    }
}
#endif
