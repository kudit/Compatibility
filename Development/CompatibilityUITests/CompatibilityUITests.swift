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
        DemoScreen(name: "Backport", identifier: "demo.backport"),
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
        
        // Keep the first screen as setup for shared app state, then jump directly to the final two
        // interactive demos. This gives a fast focused path without pretending skipped screens ran.
        let selectedIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        //let selectedIndices = [0, 8] // sub set for faster debubging
        for (position, index) in selectedIndices.enumerated() {
            let screen = screens[index]
            let screenElement = app.descendants(matching: .any)[screen.identifier]
            let rendered = await waitForElement(screenElement, timeout: 10)
            XCTAssertTrue(rendered, "\(screen.name) should render its demo screen.")
            
            await exercise(screenAt: index, screenElement: screenElement, in: app)
            
            if position < selectedIndices.count - 1 {
                await navigate(to: screens[selectedIndices[position + 1]], in: app)
            }
        }
    }

    @MainActor
    private func exercise(screenAt index: Int, screenElement: XCUIElement, in app: XCUIApplication) async {
        switch index {
        case 0:
            await exerciseCompatibilityEnvironment(screenElement, in: app)

        case 1, 4:
            // These pages are primarily exercised by rendering. Keep the UI tour fast and avoid
            // synthetic scrolling where there is no behavior we specifically need to validate.
            break

        case 2:
            // Scroll only within the All Tests content. On macOS the app also contains a scrollable
            // sidebar, so querying from XCUIApplication would otherwise scroll the navigation sidebar.
            await scrollThroughAllTests(screenElement, in: app)

        case 3:
            // Open a real menu item and verify the binding changes. This covers both construction and
            // the action path rather than merely opening the menu and tapping an ambiguous label.
            let symbols = app.buttons["Symbols"]
            if await waitForElement(symbols, timeout: 2), symbols.isHittable {
                symbols.backport.tap()
                let starFill = app.buttons["star.fill"]
                let starFillFound = await waitForElement(starFill, timeout: 2)
                XCTAssertTrue(starFillFound, "Radial Layout Symbols menu should expose star.fill.")
                if starFillFound && starFill.isHittable {
                    starFill.backport.tap()
                    let selected = app.staticTexts["Selected symbol: star.fill"]
                    let selectedRendered = await waitForElement(selected, timeout: 2)
                    XCTAssertTrue(selectedRendered, "Selecting a radial menu symbol should update its binding.")
                }
            }

        case 5:
            // Exercise Binding.convert at roughly 75%, but jump directly to the coordinate instead of
            // using adjust(toNormalizedSliderPosition:), whose deliberately human-like drag is slow.
            let slider = app.sliders.firstMatch
            if await waitForElement(slider, timeout: 2) {
#if os(macOS)
                slider.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).click()
#elseif os(iOS)
                slider.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
#else
                slider.adjust(toNormalizedSliderPosition: 0.75)
#endif
            }

        case 6:
            await exerciseVisualShowcase(in: app)

        case 7:
            await exerciseBackport(screenElement, in: app)

        case 8:
            await exerciseMaterial(screenElement, in: app)

        default:
            XCTFail("Unexpected Compatibility demo screen index: \(index)")
        }
    }

    @MainActor
    private func exerciseCompatibilityEnvironment(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        // EnvironmentsView has substantially different compact and expanded bodies. Exercise both so
        // the compatibility page verifies the interactive disclosure instead of only rendering its icons.
        let environmentToggle = app.buttons["Expand environments"]
        if !environmentToggle.exists {
            // The compatibility page places the environment summary below the initial viewport. Scroll
            // its own content rather than the app/sidebar so the expansion control becomes discoverable.
            let scrollable = contentScrollable(in: screenElement)
            if scrollable.exists {
                scrollable.swipeUp(velocity: .fast)
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
        let toggleFound = await waitForElement(environmentToggle, timeout: 3)
        XCTAssertTrue(toggleFound, "Compatibility should expose the expandable environment summary.")
        guard toggleFound && environmentToggle.isHittable else { return }

        environmentToggle.backport.tap()
        let debugEnvironment = app.descendants(matching: .any)["environment.debug"]
        let expanded = await waitForElement(debugEnvironment, timeout: 2)
        XCTAssertTrue(expanded, "Expanding environments should render the labeled environment rows.")
        guard expanded else { return }

        // Collapse again so both sides of the state transition execute and the page ends in its compact form.
        environmentToggle.backport.tap()
    }

    @MainActor
    private func exerciseVisualShowcase(in app: XCUIApplication) async {
        for showcase in showcaseDestinations {
            // Work one section at a time. After returning from a destination, SwiftUI may rebuild the
            // NavigationStack and its ScrollView, so always reacquire the current screen before asking
            // whether the next section is visible. If it is not, advance exactly one page and check again.
            guard let link = await revealNextShowcaseSection(showcase.linkIdentifier, in: app) else {
                XCTFail("Visual Showcase should scroll to the next section: \(showcase.linkIdentifier).")
                return
            }

            link.backport.tap()
            let destination = app.descendants(matching: .any)[showcase.destinationIdentifier]
            let rendered = await waitForElement(destination, timeout: 4)
            XCTAssertTrue(rendered, "Visual Showcase destination \(showcase.destinationIdentifier) should render.")
            guard rendered else { return }

            // Leave the destination visible long enough for SwiftUI to execute its body/layout work before returning.
            try? await Task.sleep(nanoseconds: 350_000_000)
            let back = navigationBackButton(in: app)
            let canReturn = await waitForElement(back, timeout: 3)
            XCTAssertTrue(canReturn, "Each Visual Showcase destination should expose navigation back.")
            guard canReturn else { return }
            back.backport.tap()

            // Verify the app really returned to the showcase before beginning the search for the next section.
            let currentShowcase = app.descendants(matching: .any)["demo.visualShowcase"]
            let returned = await waitForElement(currentShowcase, timeout: 4)
            XCTAssertTrue(returned, "Visual Showcase should return after visiting a detail.")
            guard returned else { return }
        }
    }

    @MainActor
    private func exerciseBackport(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        // Exercise the selection-bound Backport.TabView from outside the tab content. This demonstrates
        // that the Binding supplied to Backport.TabView participates in normal SwiftUI state updates.
        guard let selectionToggle = await reveal(identifier: "backport.selection.toggle", in: screenElement, app: app) else {
            XCTFail("Selection-bound Backport.TabView control should be reachable.")
            return
        }
        selectionToggle.backport.tap()
        let selectionOne = app.staticTexts["Bound selection: 1"]
        let selectionChanged = await waitForElement(selectionOne, timeout: 3)
        XCTAssertTrue(selectionChanged, "Selection-bound Backport.TabView should change to tag 1.")

#if os(macOS) || os(iOS)
        guard await reveal(identifier: "backport.symbol.field", in: screenElement, app: app) != nil else {
            XCTFail("SF Symbol ClearableTextField should be reachable.")
            return
        }

        // ClearableTextField intentionally avoids publishing every keystroke. Commit each example with Return
        // so this exercises its explicit onSubmit path as well as Backport.Image with several real symbol names.
        for symbolName in ["star.fill", "heart.fill", "calendar"] {
            let symbolField = app.textFields["SF Symbol name"]
            let symbolFieldFound = await waitForElement(symbolField, timeout: 2)
            XCTAssertTrue(symbolFieldFound, "Backport should expose the SF Symbol text field.")
            guard symbolFieldFound else { return }

            symbolField.backport.tap()
            symbolField.typeText(symbolName)
            symbolField.typeText("\n")

            let symbolStatus = app.staticTexts["Current symbol: \(symbolName)"]
            let symbolChanged = await waitForElement(symbolStatus, timeout: 2)
            XCTAssertTrue(symbolChanged, "Committing \(symbolName) should update the Backport.Image example.")
            guard symbolChanged else { return }

            // Test the real clear control after every value. The clear button intentionally keeps focus in
            // the text field, so press Return afterward to commit the empty value to the optional binding.
            let clearButton = app.buttons["Clear SF Symbol name"]
            let clearFound = await waitForElement(clearButton, timeout: 2)
            XCTAssertTrue(clearFound, "ClearableTextField should expose its clear button after entering \(symbolName).")
            guard clearFound else { return }
            clearButton.backport.tap()
            symbolField.typeText("\n")

            let clearedStatus = app.staticTexts["Current symbol: <empty>"]
            let cleared = await waitForElement(clearedStatus, timeout: 2)
            XCTAssertTrue(cleared, "ClearableTextField should commit an empty value after its clear button is used.")
            guard cleared else { return }
        }
#endif

        guard await reveal(identifier: "backport.scroll.strip", in: screenElement, app: app) != nil else {
            XCTFail("scrollDisabled example should expose its horizontal strip.")
            return
        }
        let strip = app.scrollViews["backport.scroll.strip"]
        let stripFound = await waitForElement(strip, timeout: 2)
        XCTAssertTrue(stripFound, "Backport scrolling example should expose a horizontal ScrollView.")
        guard stripFound else { return }

        // Accessibility can keep clipped descendants in its hierarchy, so `exists`/`isHittable` is not a
        // reliable proxy for the scroll offset. Compare an item's actual frame before and after each gesture.
        let firstItem = app.descendants(matching: .any)["backport.scroll.item.0"]
        let firstItemFound = await waitForElement(firstItem, timeout: 2)
        XCTAssertTrue(firstItemFound, "Numbered strip should expose its first item.")
        guard firstItemFound else { return }

        let initialX = firstItem.frame.minX
        strip.swipeLeft()
        try? await Task.sleep(nanoseconds: 200_000_000)
        let scrolledX = firstItem.frame.minX
        XCTAssertLessThan(scrolledX, initialX - 5,
                          "Enabled numbered strip should move its content after a scroll gesture.")

        // Return all the way to the starting edge before disabling scrolling so the test also leaves the
        // final item off screen again after demonstrating normal scrolling behavior.
        strip.swipeRight()
        try? await Task.sleep(nanoseconds: 200_000_000)
        let restoredX = firstItem.frame.minX
        XCTAssertEqual(restoredX, initialX, accuracy: 5,
                       "Enabled numbered strip should return to its starting position before disabling scrolling.")

        guard let scrollToggle = await reveal(identifier: "backport.scroll.toggle", in: screenElement, app: app) else {
            XCTFail("scrollDisabled Backport toggle should be reachable.")
            return
        }
        scrollToggle.backport.tap()

        let disabledStartX = firstItem.frame.minX
        strip.swipeLeft()
        try? await Task.sleep(nanoseconds: 200_000_000)
        let disabledEndX = firstItem.frame.minX
        XCTAssertEqual(disabledEndX, disabledStartX, accuracy: 3,
                       "Disabled numbered strip should not move after the same scroll gesture.")

        // Restore the enabled state for anyone continuing to inspect the demo after the automated tour.
        scrollToggle.backport.tap()
    }

    @MainActor
    private func exerciseMaterial(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        // Query the stable Button identifier globally so the Material tab label cannot satisfy this lookup
        // when SwiftUI flattens the demo screen's accessibility hierarchy.
        let navigation = app.buttons["Material Navigation"]
        let navigationFound = await waitForElement(navigation, timeout: 3)
        XCTAssertTrue(navigationFound, "Material navigation trigger should be present.")
        guard navigationFound && navigation.isHittable else {
            XCTFail("Material navigation trigger should be hittable.")
            return
        }

        navigation.backport.tap()
        let destinationScreen = app.descendants(matching: .any)["material.navigation.destination"]
        let destinationRendered = await waitForElement(destinationScreen, timeout: 4)
        XCTAssertTrue(destinationRendered, "Material navigation should show its navigation destination.")
        guard destinationRendered else { return }

        // Exercise both branches of the conditional view modifier while the destination remains visible.
        guard let conditionalToggle = await reveal(identifier: "material.conditional.toggle", in: destinationScreen, app: app) else {
            XCTFail("Material navigation destination should expose the conditional modifier toggle.")
            return
        }
        conditionalToggle.backport.tap()
        let conditionalOff = app.staticTexts["Conditional modifier not applied"]
        let offRendered = await waitForElement(conditionalOff, timeout: 2)
        XCTAssertTrue(offRendered, "Conditional modifier example should visibly change when disabled.")
        conditionalToggle.backport.tap()
        let conditionalOn = app.staticTexts["Conditional modifier applied"]
        let onRendered = await waitForElement(conditionalOn, timeout: 2)
        XCTAssertTrue(onRendered, "Conditional modifier example should visibly change when re-enabled.")

        // Keep this visibly presented for a full second: besides executing the destination body, this makes
        // the navigation step observable when watching the UI test rather than appearing as an instant flicker.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let destination = app.buttons["Navigation Destination TestCase"]
        let dismissFound = await waitForElement(destination, timeout: 2)
        XCTAssertTrue(dismissFound, "Material navigation destination should expose its return control.")
        guard dismissFound else { return }
        destination.backport.tap()

        let materialScreen = app.descendants(matching: .any)["demo.material"]
        let materialReturned = await waitForElement(materialScreen, timeout: 4)
        XCTAssertTrue(materialReturned, "Material navigation destination should dismiss back to Material.")
        guard materialReturned else { return }
        // Wait for the destination node to leave the accessibility tree before querying the rebuilt
        // Material content; the view identity changes when navigation dismisses.
        let destinationGone = await waitForElementToDisappear(destinationScreen, timeout: 4)
        XCTAssertTrue(destinationGone, "Material navigation destination should finish dismissing before Glass is tested.")

        // Exercise the sheet last so the Material tab finishes on the visually distinct Glass presentation.
        let glass = app.buttons["Glass"]
        let glassFound = await waitForElement(glass, timeout: 4)
        XCTAssertTrue(glassFound, "Material should expose the Glass sheet control.")
        if glass.exists && glass.isHittable {
            glass.backport.tap()
            let close = app.buttons["Close"]
            let closeFound = await waitForElement(close, timeout: 3)
            XCTAssertTrue(closeFound, "Material sheet should expose Close.")
            if close.exists && close.isHittable {
                try? await Task.sleep(nanoseconds: 500_000_000)
                close.backport.tap()
            }
        }
    }

    /// Reveals the next Visual Showcase section by advancing one viewport at a time.
    ///
    /// A navigation round-trip can recreate the containing ScrollView. Re-query the current screen and
    /// scrollable hierarchy on every pass rather than retaining an element from the previous destination.
    @MainActor
    private func revealNextShowcaseSection(_ identifier: String, in app: XCUIApplication) async -> XCUIElement? {
        for _ in 0..<12 {
            let element = app.descendants(matching: .any)[identifier]
            if element.exists && element.isHittable {
                return element
            }

            let currentShowcase = app.descendants(matching: .any)["demo.visualShowcase"]
            guard currentShowcase.exists else {
                return nil
            }
            let scrollable = contentScrollable(in: currentShowcase)
            guard scrollable.exists else {
                return nil
            }

            // Move only one page before checking the requested next section again. This deliberately
            // mirrors how a person tours the showcase instead of flinging to an arbitrary far position.
            scrollable.swipeUp()
            try? await Task.sleep(nanoseconds: 180_000_000)
        }

        let element = app.descendants(matching: .any)[identifier]
        return element.exists && element.isHittable ? element : nil
    }

    /// Scrolls a current screen until an accessibility identifier is hittable.
    ///
    /// This helper is for long single-screen examples such as Backport and the Material destination.
    /// It reacquires the scroll view after each gesture so SwiftUI hierarchy rebuilds do not leave a stale element.
    @MainActor
    private func reveal(identifier: String, in screenElement: XCUIElement, app: XCUIApplication) async -> XCUIElement? {
        for _ in 0..<12 {
            let element = app.descendants(matching: .any)[identifier]
            if element.exists && element.isHittable {
                return element
            }

            let scrollable = contentScrollable(in: screenElement)
            guard scrollable.exists else {
                return nil
            }
            scrollable.swipeUp()
            try? await Task.sleep(nanoseconds: 140_000_000)
        }

        let element = app.descendants(matching: .any)[identifier]
        return element.exists && element.isHittable ? element : nil
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
        // sidebarAdaptable exposes destinations through the macOS sidebar. Later destinations can be
        // outside the visible portion of the sidebar, so scroll the sidebar while searching rather than
        // assuming every tab label already exists in the accessibility hierarchy.
        if let tab = await visibleSidebarTab(named: screen.name, in: app) {
            tab.backport.tap()
            // AppKit can acknowledge the sidebar click before SwiftUI has installed the destination
            // accessibility node. Re-tap the same resolved tab once if the destination is not observable.
            let destination = app.descendants(matching: .any)[screen.identifier]
            if !(await waitForElement(destination, timeout: 3)) {
                tab.backport.tap()
                _ = await waitForElement(destination, timeout: 5)
            }
        } else {
            XCTFail("macOS should expose the \(screen.name) tab in the sidebar.")
        }
#elseif os(tvOS)
        XCUIRemote.shared.press(.right)
#else
        // Prefer the named tab control when the platform publishes one; a blind page swipe can leave the
        // selection unchanged when the demo is hosted in a regular TabView rather than a page TabView.
        let namedTab = app.tabBars.buttons[screen.name]
        if await waitForElement(namedTab, timeout: 2), namedTab.isHittable {
            namedTab.backport.tap()
        } else {
            app.swipeLeft()
        }
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
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if !element.exists {
                return true
            }
            if Date() >= deadline {
                return false
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        } while true
    }

    @MainActor
    private func scrollThroughAllTests(_ screenElement: XCUIElement, in app: XCUIApplication) async {
        let scrollable = contentScrollable(in: screenElement)
        let bottom = app.descendants(matching: .any)["allTests.bottom"]

#if os(macOS)
        // A Mac scroll view responds to wheel/trackpad scrolling, not an iOS-style mouse drag. XCTest's
        // native pixel-scroll API sends that scrolling directly and can jump the long test list in one call.
        // Negative deltaY scrolls toward later content in the current AppKit hierarchy. If an OS reverses
        // that interpretation, the opposite-direction fallback immediately corrects it without repeated swipes.
        scrollable.scroll(byDeltaX: 0, deltaY: -10_000)
        try? await Task.sleep(nanoseconds: 50_000_000)
        if !(bottom.exists && bottom.isHittable) {
            scrollable.scroll(byDeltaX: 0, deltaY: 20_000)
        }
#else
        // Touch platforms keep their native swipe gesture. Stop as soon as the explicit bottom marker is visible.
        for _ in 0..<3 where !(bottom.exists && bottom.isHittable) {
            scrollable.swipeUp(velocity: .fast)
        }
#endif

        // Give accessibility a brief opportunity to publish the newly visible bottom marker without adding
        // more scrolling. The intentional three-second observation pause happens only after this succeeds.
        let deadline = Date().addingTimeInterval(0.5)
        while !(bottom.exists && bottom.isHittable) && Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertTrue(bottom.exists && bottom.isHittable, "All Tests should reach its bottom marker during the fast scroll.")

        // Hold only after reaching the end so a person watching can see the intentionally slow two- and
        // three-second tests transition to completion instead of spending that time watching more scrolling.
        try? await Task.sleep(nanoseconds: 3_000_000_000)
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
