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
/// The app launches once and the test advances through the real `TabView` in declaration order.
/// This deliberately avoids numeric selection tags so inserting or rearranging demo tabs does not require
/// keeping a second set of tab indices synchronized. Navigation follows the native platform presentation:
/// sidebar selection on macOS, page gestures on touch platforms, and remote navigation on tvOS.
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
        DemoScreen(name: "Visual Showcase", identifier: "demo.visualShowcase"),
        DemoScreen(name: "Material", identifier: "demo.material"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveryDemoScreenAndRepresentativeInteractions() async throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launchEnvironment["TESTING"] = "1"
        app.launch()
        app.activate()

        for (index, screen) in screens.enumerated() {
            app.activate()

            let screenElement = app.descendants(matching: .any)[screen.identifier]
            let rendered = await waitForElement(screenElement, timeout: 10)
            XCTAssertTrue(rendered, "\(screen.name) should render its demo screen.")

            await exercise(screenAt: index, screenElement: screenElement, in: app)

            if index < screens.count - 1 {
                await navigate(to: screens[index + 1], in: app)
            }
        }
    }

    @MainActor
    private func exercise(screenAt index: Int, screenElement: XCUIElement, in app: XCUIApplication) async {
        switch index {
        case 0, 1, 4:
            // These pages are primarily exercised by rendering. Keep the UI tour fast and avoid
            // synthetic scrolling where there is no behavior we specifically need to validate.
            break

        case 2:
            // Scroll only within the All Tests content. On macOS the app also contains a scrollable
            // sidebar, so querying from XCUIApplication would otherwise scroll the navigation sidebar.
            scrollThroughAllTests(screenElement)

        case 3:
            // Open the real menu when exposed so Menu callbacks and menu-item construction are covered.
            let symbols = app.buttons["Symbols"]
            if await waitForElement(symbols, timeout: 2), symbols.isHittable {
                symbols.backport.tap()
                let star = app.buttons["star"]
                if await waitForElement(star, timeout: 2), star.isHittable {
                    star.backport.tap()
                }
            }

        case 5:
            // Exercise Binding.convert through the Convert screen's slider.
            let slider = app.sliders.firstMatch
            if await waitForElement(slider, timeout: 2) {
                slider.adjust(toNormalizedSliderPosition: 0.75)
            }

        case 6:
            // The visual showcase intentionally contains several layouts below the fold. A few passes
            // cause SwiftUI to lay out representative Embossed, OverlappingStack, AdaptiveLayout,
            // RadialStack, ClearableTextField, Placard, Triangle, and fill/stroke examples.
            scrollVisualShowcase(screenElement)

        case 7:
            // Material owns the navigation-destination test now. Also exercise its sheet so the material,
            // presentation-detent/background, toolbar, and dismissal paths are rendered during UI coverage.
            let glass = app.buttons["Glass"]
            if await waitForElement(glass, timeout: 2), glass.isHittable {
                glass.backport.tap()
                let close = app.buttons["Close"]
                if await waitForElement(close, timeout: 3), close.isHittable {
                    close.backport.tap()
                }
            }

            let navigation = app.buttons["Material"]
            if await waitForElement(navigation, timeout: 2), navigation.isHittable {
                navigation.backport.tap()
                let destination = app.buttons["Navigation Destination TestCase"]
                if await waitForElement(destination, timeout: 3), destination.isHittable {
                    destination.backport.tap()
                }
            }

        default:
            XCTFail("Unexpected Compatibility demo screen index: \(index)")
        }
    }

    @MainActor
    private func navigate(to screen: DemoScreen, in app: XCUIApplication) async {
#if os(macOS)
        app.activate()

        // sidebarAdaptable exposes destinations through the macOS sidebar. Later destinations can be
        // outside the visible portion of the sidebar, so scroll the sidebar while searching rather than
        // assuming every tab label already exists in the accessibility hierarchy.
        if let tab = await visibleSidebarTab(named: screen.name, in: app) {
            tab.backport.tap()
        } else {
            XCTFail("macOS should expose the \(screen.name) tab in the sidebar.")
        }
#elseif os(tvOS)
        XCUIRemote.shared.press(.right)
#else
        app.swipeLeft()
#endif
    }

#if os(macOS)
    @MainActor
    private func visibleSidebarTab(named name: String, in app: XCUIApplication) async -> XCUIElement? {
        func visibleMatch() -> XCUIElement? {
            // SwiftUI/AppKit may expose a sidebar destination as a button, static text, or generic
            // accessibility element depending on the OS version. Prefer actionable controls first.
            let candidates = [
                app.buttons[name],
                app.staticTexts[name],
                app.descendants(matching: .any)[name],
            ]
            return candidates.first { $0.exists && $0.isHittable }
        }

        if let match = visibleMatch() {
            return match
        }

        // sidebarAdaptable currently presents its navigation list as an outline on macOS. Fall back
        // to the first scrollable navigation container if accessibility exposes it differently.
        let outline = app.outlines.firstMatch
        let scrollArea = app.scrollViews.firstMatch
        let sidebar = outline.exists ? outline : scrollArea
        guard sidebar.exists else {
            return nil
        }

        // A few small passes are enough to reveal the demo destinations without sending the sidebar
        // all the way to an extreme and making the test unnecessarily slow.
        for _ in 0..<3 {
            sidebar.swipeUp()
            try? await Task.sleep(nanoseconds: 150_000_000)
            if let match = visibleMatch() {
                return match
            }
        }

        // Restore roughly toward the top so subsequent navigation remains predictable.
        for _ in 0..<3 {
            sidebar.swipeDown()
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let match = visibleMatch() {
                return match
            }
        }

        return nil
    }
#endif

    @MainActor
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists {
                return true
            }
            if Date() >= deadline {
                return false
            }
            // Yield the main actor instead of calling XCTest's synchronous waitForExistence(timeout:),
            // which the performance diagnostics correctly flag as blocking UI responsiveness.
            try? await Task.sleep(nanoseconds: 100_000_000)
        } while true
    }

    @MainActor
    private func scrollThroughAllTests(_ screenElement: XCUIElement) {
        let scrollable = contentScrollable(in: screenElement)
        // A couple of passes are enough to instantiate representative off-screen rows for coverage.
        scrollable.swipeUp()
        scrollable.swipeUp()
        scrollable.swipeDown()
    }

    @MainActor
    private func scrollVisualShowcase(_ screenElement: XCUIElement) {
        let scrollable = contentScrollable(in: screenElement)
        for _ in 0..<4 {
            scrollable.swipeUp()
        }
        scrollable.swipeDown()
    }

    @MainActor
    private func contentScrollable(in screenElement: XCUIElement) -> XCUIElement {
        let scrollView = screenElement.descendants(matching: .scrollView).firstMatch
        let table = screenElement.descendants(matching: .table).firstMatch
        let collection = screenElement.descendants(matching: .collectionView).firstMatch

        if scrollView.exists {
            return scrollView
        }
        if table.exists {
            return table
        }
        if collection.exists {
            return collection
        }
        return screenElement
    }
}
#endif
