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

    private struct ShowcaseDestination {
        let linkIdentifier: String
        let destinationIdentifier: String
    }

    private let screens = [
        DemoScreen(name: "Compatibility", identifier: "demo.compatibility"),
        DemoScreen(name: "DataStore", identifier: "demo.datastore"),
        DemoScreen(name: "All Tests", identifier: "demo.allTests"),
        DemoScreen(name: "Radial Layout", identifier: "demo.radialLayout"),
        DemoScreen(name: "Random Bytes", identifier: "demo.randomBytes"),
        DemoScreen(name: "Convert", identifier: "demo.convert"),
        DemoScreen(name: "Visual Showcase", identifier: "demo.visualShowcase"),
        DemoScreen(name: "Material", identifier: "demo.material"),
    ]

    private let showcaseDestinations = [
        ShowcaseDestination(linkIdentifier: "showcase.triangles.link", destinationIdentifier: "showcase.triangles.destination"),
        ShowcaseDestination(linkIdentifier: "showcase.placards.link", destinationIdentifier: "showcase.placards.destination"),
        ShowcaseDestination(linkIdentifier: "showcase.fillStroke.link", destinationIdentifier: "showcase.fillStroke.destination"),
        ShowcaseDestination(linkIdentifier: "showcase.embossed.link", destinationIdentifier: "showcase.embossed.destination"),
        ShowcaseDestination(linkIdentifier: "showcase.overlapping.link", destinationIdentifier: "showcase.overlapping.destination"),
        ShowcaseDestination(linkIdentifier: "showcase.adaptive.link", destinationIdentifier: "showcase.adaptive.destination"),
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
            await exerciseVisualShowcase(screenElement, in: app)

        case 7:
            await exerciseMaterial(screenElement, in: app)

        default:
            XCTFail("Unexpected Compatibility demo screen index: \(index)")
        }
    }

    @MainActor
    private func exerciseVisualShowcase(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        let scrollable = contentScrollable(in: screenElement)

        for showcase in showcaseDestinations {
            let link = app.descendants(matching: .any)[showcase.linkIdentifier]
            let found = await reveal(link, byScrolling: scrollable)
            XCTAssertTrue(found, "Visual Showcase should expose \(showcase.linkIdentifier).")
            guard found else { return }

            link.backport.tap()
            let destination = app.descendants(matching: .any)[showcase.destinationIdentifier]
            let rendered = await waitForElement(destination, timeout: 4)
            XCTAssertTrue(rendered, "Visual Showcase destination \(showcase.destinationIdentifier) should render.")
            guard rendered else { return }

            // Leave the destination visible long enough for SwiftUI to execute its body/layout work before returning.
            try? await Task.sleep(nanoseconds: 250_000_000)
            let back = navigationBackButton(in: app)
            let canReturn = await waitForElement(back, timeout: 3)
            XCTAssertTrue(canReturn, "Each Visual Showcase destination should expose navigation back.")
            guard canReturn else { return }
            back.backport.tap()
            let returned = await waitForElement(screenElement, timeout: 4)
            XCTAssertTrue(returned, "Visual Showcase should return after visiting a detail.")
        }

        let backportSection = app.descendants(matching: .any)["showcase.backport"]
        let backportRendered = await reveal(backportSection, byScrolling: scrollable)
        XCTAssertTrue(backportRendered, "Backport API examples should render in Visual Showcase.")

        let conditionalToggle = app.descendants(matching: .any)["showcase.conditional.toggle"]
        let toggleReachable = await reveal(conditionalToggle, byScrolling: scrollable)
        XCTAssertTrue(toggleReachable, "Conditional modifier toggle should be reachable.")
        guard conditionalToggle.exists else { return }

        // Start on, turn it off to execute the original-view path, then turn it back on to execute the transform path again.
        conditionalToggle.backport.tap()
        try? await Task.sleep(nanoseconds: 150_000_000)
        conditionalToggle.backport.tap()
    }

    @MainActor
    private func exerciseMaterial(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        // Exercise the sheet so material, presentation-detent/background, toolbar, and dismissal paths render.
        let glass = app.buttons["Glass"]
        let glassFound = await waitForElement(glass, timeout: 2)
        XCTAssertTrue(glassFound, "Material should expose the Glass sheet control.")
        if glass.exists && glass.isHittable {
            glass.backport.tap()
            let close = app.buttons["Close"]
            let closeFound = await waitForElement(close, timeout: 3)
            XCTAssertTrue(closeFound, "Material sheet should expose Close.")
            if close.exists && close.isHittable {
                close.backport.tap()
            }
        }

        // Material's navigation trigger is intentionally a tappable Text rather than a Button.
        let navigation = screenElement.staticTexts["Material"]
        let navigationFound = await waitForElement(navigation, timeout: 2)
        XCTAssertTrue(navigationFound, "Material navigation trigger should be present.")
        guard navigation.exists && navigation.isHittable else {
            XCTFail("Material navigation trigger should be hittable.")
            return
        }

        navigation.backport.tap()
        let destination = app.buttons["Navigation Destination TestCase"]
        let destinationRendered = await waitForElement(destination, timeout: 4)
        XCTAssertTrue(destinationRendered, "Material navigation should show Navigation Destination TestCase.")
        guard destinationRendered else { return }

        // Keep the destination visibly presented briefly so the test proves the navigation actually happened.
        try? await Task.sleep(nanoseconds: 400_000_000)
        destination.backport.tap()
        let materialReturned = await waitForElement(navigation, timeout: 4)
        XCTAssertTrue(materialReturned, "Material navigation destination should dismiss back to Material.")
    }

    @MainActor
    private func reveal(_ element: XCUIElement, byScrolling scrollable: XCUIElement) async -> Bool {
        if element.exists && element.isHittable {
            return true
        }
        for _ in 0..<5 {
            scrollable.swipeUp()
            try? await Task.sleep(nanoseconds: 120_000_000)
            if element.exists && element.isHittable {
                return true
            }
        }
        return element.exists && element.isHittable
    }

    @MainActor
    private func navigationBackButton(in app: XCUIApplication) -> XCUIElement {
        let namedBack = app.buttons["Back"]
        if namedBack.exists {
            return namedBack
        }
        let navigationBarButton = app.navigationBars.buttons.firstMatch
        if navigationBarButton.exists {
            return navigationBarButton
        }
        return app.buttons.firstMatch
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
