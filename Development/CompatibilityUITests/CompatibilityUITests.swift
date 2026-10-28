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

    private let allScreens = [
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

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveryDemoScreenAndRepresentativeInteractions() async {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launchEnvironment["TESTING"] = "1"
        app.launch()

        for index in allScreens.indices {
            let screen = allScreens[index]
            if index > 0 {
                await navigate(to: screen, in: app)
            }
            let screenElement = app.descendants(matching: .any)[screen.identifier]
            let rendered = await waitForElement(screenElement, timeout: 5)
            XCTAssertTrue(rendered, "\(screen.name) should render its demo screen.")
            guard rendered else { continue }

            switch index {
            case 0:
                await exerciseCompatibilityEnvironment(in: app)
            case 3:
                await exerciseRadialLayout(in: app)
            case 5:
                exerciseConvert(in: app)
            case 6:
                await exerciseVisualShowcase(in: app)
            case 7:
                await exerciseBackport(app.scrollViews[screen.identifier])
            case 8:
                await exerciseMaterial(in: app)
            default:
                break
            }
        }
    }

    @MainActor
    private func exerciseCompatibilityEnvironment(in app: XCUIApplication) async {
        let row = app.buttons["environments.toggle"]
        let found = await waitForElement(row, timeout: 3)
        XCTAssertTrue(found, "The Environment summary should expose its toggle button.")
        guard found else { return }

        let collapsedHeight = row.frame.height
        clickCenter(row)
        let expanded = await waitForLabel(row, equalTo: "Collapse environments", timeout: 2)
        XCTAssertTrue(expanded, "Tapping anywhere on the Environment row should expand it.")
        let expandedHeight = await waitForHeight(row, greaterThan: collapsedHeight + 1, timeout: 2)
        XCTAssertTrue(expandedHeight, "The Environment List row should grow with its animated content.")

        let value = String(describing: row.value)
        XCTAssertTrue(value.contains("Is App") && value.contains("Is Testing"),
                      "Expanded environment state should remain available to accessibility (value: \(value)).")

        row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).click()
        let collapsed = await waitForLabel(row, equalTo: "Expand environments", timeout: 2)
        XCTAssertTrue(collapsed, "Tapping the expanded Environment row's visible content area should collapse it again.")
        let restoredHeight = await waitForHeight(row, lessThan: collapsedHeight + 2, timeout: 2)
        XCTAssertTrue(restoredHeight, "The Environment List row should return to its compact height.")
    }

    @MainActor
    private func exerciseRadialLayout(in app: XCUIApplication) async {
        // Resolve the explicitly identified Menu instead of relying on macOS to classify it
        // consistently as a popup button across the supported Xcode versions.
        let inlineMenu = app.menuButtons["demo.radialLayout"]
        let inlineFound = await waitForElement(inlineMenu, timeout: 3)
        XCTAssertTrue(inlineFound, "Radial Layout should expose its inline Symbols menu.")
        if inlineFound {
            clickCenter(inlineMenu)
            let spade = app.menuItems["suit.spade.fill"]
            let spadeFound = await waitForElement(spade, timeout: 2)
            XCTAssertTrue(spadeFound, "The inline Symbols menu should expose suit.spade.fill.")
            if spadeFound { clickCenter(spade) }
        }

        let toolbarMenu = app.menuButtons["radial.toolbar.symbols.menu"]
        let toolbarFound = await waitForElement(toolbarMenu, timeout: 3)
        XCTAssertTrue(toolbarFound, "Radial Layout should expose its toolbar Symbols menu.")
        if toolbarFound {
            clickCenter(toolbarMenu)
            let star = app.menuItems["star.fill"]
            let starFound = await waitForElement(star, timeout: 2)
            XCTAssertTrue(starFound, "The toolbar Symbols menu should expose star.fill.")
            if starFound { clickCenter(star) }
        }
    }

    @MainActor
    private func exerciseConvert(in app: XCUIApplication) {
        let slider = app.sliders.firstMatch
        guard slider.exists else {
            XCTFail("Convert should expose its input slider.")
            return
        }
#if os(macOS)
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).click()
#elseif os(iOS)
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
#else
        slider.adjust(toNormalizedSliderPosition: 0.75)
#endif
    }

    @MainActor
    private func exerciseVisualShowcase(in app: XCUIApplication) async {
        let destinations = [
            ("showcase.triangles.link", "showcase.triangles.destination"),
            ("showcase.placards.link", "showcase.placards.destination"),
            ("showcase.fillStroke.link", "showcase.fillStroke.destination"),
            ("showcase.embossed.link", "showcase.embossed.destination"),
            ("showcase.overlapping.link", "showcase.overlapping.destination"),
            ("showcase.adaptive.link", "showcase.adaptive.destination"),
        ]
        let scroll = app.scrollViews["demo.visualShowcase"]
        for (linkID, destinationID) in destinations {
            guard let link = await revealShowcaseLink(linkID, in: scroll, app: app) else {
                XCTFail("Visual Showcase should reveal \(linkID).")
                return
            }
            if linkID == "showcase.adaptive.link" {
                // The adaptive preview fills the NavigationLink label with custom layout content;
                // use its title-side hit area rather than a center coordinate over that content.
                link.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.08)).click()
            } else {
                clickCenter(link)
            }
            let destination = app.descendants(matching: .any).matching(identifier: destinationID).firstMatch
            var rendered = await waitForElement(destination, timeout: 3)
            if !rendered {
                // Some visual-only destinations do not publish a root accessibility node.
                // Their native navigation-back control confirms the detail route is active.
                rendered = await waitForElement(navigationBackButton(in: app), timeout: 2)
            }
            XCTAssertTrue(rendered, "Visual Showcase destination \(destinationID) should render.")
            guard rendered else { return }

            let back = navigationBackButton(in: app)
            let backFound = await waitForElement(back, timeout: 2)
            XCTAssertTrue(backFound, "Showcase destination should provide navigation back.")
            guard backFound else { return }
            clickCenter(back)
            guard await waitForElement(scroll, timeout: 2) else {
                XCTFail("Visual Showcase should return after opening a detail view.")
                return
            }
        }
    }

    @MainActor
    private func exerciseBackport(_ screen: XCUIElement) async {
        let selection = screen.buttons["backport.selection.toggle"]
        guard await reveal(selection, in: screen) else {
            XCTFail("Backport.TabView selection control should be reachable.")
            return
        }
        clickCenter(selection)
        let selected = await waitForText(screen.staticTexts["backport.selection.status"], containing: "Bound selection: 1", timeout: 2)
        XCTAssertTrue(selected, "Backport.TabView should update its bound selection.")

#if os(macOS) || os(iOS)
        let field = screen.textFields["SF Symbol name"]
        guard await reveal(field, in: screen) else {
            XCTFail("Backport should reveal its SF Symbol input.")
            return
        }
        let clearButton = screen.buttons["Clear SF Symbol name"]
        let initiallyClearable = await waitForElement(clearButton, timeout: 2)
        XCTAssertTrue(initiallyClearable, "The initial SF Symbol value should be clearable before entering a replacement.")
        if initiallyClearable {
            clickCenter(clearButton)
            clickCenter(field)
            field.typeText("\n")
            let cleared = await waitForText(screen.staticTexts["backport.symbol.status"], containing: "<empty>", timeout: 2)
            XCTAssertTrue(cleared, "ClearableTextField should clear its initial SF Symbol value.")
        }
        clickCenter(field)
        field.typeText("star.fill\n")
        let symbolStatus = screen.staticTexts["backport.symbol.status"]
        let symbolUpdated = await waitForText(symbolStatus, containing: "star.fill", timeout: 2)
        XCTAssertTrue(symbolUpdated, "Submitting a symbol name should update the Backport.Image preview.")

        let clearFound = await waitForElement(clearButton, timeout: 2)
        XCTAssertTrue(clearFound, "ClearableTextField should reveal its clear control after input.")
        if clearFound {
            clickCenter(clearButton)
            field.typeText("\n")
            let cleared = await waitForText(symbolStatus, containing: "<empty>", timeout: 2)
            XCTAssertTrue(cleared, "ClearableTextField should commit its empty value.")

            field.typeText("calendar\n")
            let calendarUpdated = await waitForText(symbolStatus, containing: "calendar", timeout: 2)
            XCTAssertTrue(calendarUpdated, "Submitting another symbol should update the Backport.Image preview.")
        }
#endif

#if os(macOS)
        // Do not query the nested strip's hittability before scrolling the page. On macOS 27
        // that offscreen accessibility query can block for 10–16 seconds before returning.
        screen.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.55)).hover()
        screen.scroll(byDeltaX: 0, deltaY: -10_000)
#endif
        let strip = screen.scrollViews["backport.scroll.strip"]
        guard strip.exists else {
            XCTFail("Backport should reveal its numbered scrolling strip.")
            return
        }
        guard strip.isHittable else {
            XCTFail("Backport's numbered scrolling strip should be reachable after scrolling the page.")
            return
        }
        let firstItem = screen.staticTexts["backport.scroll.item.0"]
        let initialX = firstItem.frame.minX
#if os(macOS)
        strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
        strip.scroll(byDeltaX: -900, deltaY: 0)
#else
        strip.swipeLeft()
#endif
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertLessThan(firstItem.frame.minX, initialX - 5, "Enabled Backport scrolling should move the numbered strip.")

#if os(macOS)
        let toggle = screen.checkBoxes["backport.scroll.toggle"]
#else
        let toggle = screen.switches["backport.scroll.toggle"]
#endif
        guard await reveal(toggle, in: screen) else {
            XCTFail("Backport should reveal its scrollDisabled toggle.")
            return
        }
        clickCenter(toggle)
        let actionChanged = await waitForText(screen.staticTexts["backport.onChange.action"], containing: "scrolling disabled", timeout: 2)
        XCTAssertTrue(actionChanged, "The backported onChange action should receive the toggle update.")
        let transitionChanged = await waitForText(screen.staticTexts["backport.onChange.values"], containing: "false → true", timeout: 2)
        XCTAssertTrue(transitionChanged, "The old/new Backport.onChange overload should report the toggle transition.")

        let disabledStartX = firstItem.frame.minX
#if os(macOS)
        strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
        strip.scroll(byDeltaX: -900, deltaY: 0)
#else
        strip.swipeLeft()
#endif
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(firstItem.frame.minX, disabledStartX, accuracy: 3,
                       "The disabled numbered strip should not move after the same scroll gesture.")
        clickCenter(toggle)

        let galleryHeading = screen.staticTexts["backport.asyncImage"]
        guard await reveal(galleryHeading, in: screen) else {
            XCTFail("Backport should reveal the native and forced-legacy preview gallery.")
            return
        }
        XCTAssertTrue(screen.descendants(matching: .any).matching(identifier: "backport.nativeLegacy.gallery").firstMatch.exists)
        XCTAssertTrue(screen.descendants(matching: .any).matching(identifier: "backport.labeledContent.gallery").firstMatch.exists)
        XCTAssertTrue(screen.descendants(matching: .any).matching(identifier: "backport.groupBox.gallery").firstMatch.exists)
        XCTAssertTrue(screen.descendants(matching: .any).matching(identifier: "backport.legacyProgress.view").firstMatch.exists,
                      "The content-only legacy ProgressView fallback should render for coverage.")
        XCTAssertTrue(screen.descendants(matching: .any).matching(identifier: "backport.legacyAsyncImage.view").firstMatch.exists,
                      "The content-only legacy AsyncImage fallback should render for coverage.")

#if os(macOS)
        screen.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.55)).hover()
        screen.scroll(byDeltaX: 0, deltaY: -10_000)
#else
        for _ in 0..<4 { screen.swipeUp(velocity: .fast) }
#endif
    }

    @MainActor
    private func exerciseMaterial(in app: XCUIApplication) async {
        // On macOS the button's label is more stable than its nested identifier in XCTest.
        let navigation = app.buttons["Material Navigation"]
        let navigationFound = await waitForElement(navigation, timeout: 3)
        XCTAssertTrue(navigationFound, "Material should expose its navigation control. Snapshot: \(app.debugDescription)")
        guard navigationFound else { return }
        clickCenter(navigation)

        let destination = app.descendants(matching: .any).matching(identifier: "material.navigation.destination").firstMatch
        let destinationFound = await waitForElement(destination, timeout: 3)
        XCTAssertTrue(destinationFound, "Material navigation should show its destination.")
        guard destinationFound else { return }

#if os(macOS)
        let toggle = destination.checkBoxes["material.conditional.toggle"]
#else
        let toggle = destination.switches["material.conditional.toggle"]
#endif
        let toggleFound = await waitForElement(toggle, timeout: 2)
        XCTAssertTrue(toggleFound, "Material destination should expose the conditional modifier toggle.")
        guard toggleFound else { return }
        let conditionalResult = destination.staticTexts["material.conditional.result"]
        clickCenter(toggle)
        let offRendered = await waitForText(conditionalResult, containing: "not applied", timeout: 2)
        XCTAssertTrue(offRendered, "The conditional modifier should update when disabled.")
#if os(macOS)
        let restoredToggle = destination.checkBoxes["material.conditional.toggle"]
#else
        let restoredToggle = destination.switches["material.conditional.toggle"]
#endif
        clickCenter(restoredToggle)
        let onRendered = await waitForText(conditionalResult, containing: "applied", excluding: "not applied", timeout: 2)
        XCTAssertTrue(onRendered, "The conditional modifier should restore its applied state (label: \(conditionalResult.label), value: \(conditionalResult.value ?? "nil")).")

        let returnButton = destination.buttons["Navigation Destination TestCase"]
        guard await waitForElement(returnButton, timeout: 2) else {
            XCTFail("Material navigation should expose its return control.")
            return
        }
        clickCenter(returnButton)

        let glass = app.buttons["Glass"]
        guard await waitForElement(glass, timeout: 3) else {
            XCTFail("Material should expose its Glass presentation control after returning.")
            return
        }
        clickCenter(glass)
        let close = app.buttons["Close"]
        guard await waitForElement(close, timeout: 3) else {
            XCTFail("The Glass presentation should expose its Close control.")
            return
        }
        clickCenter(close)
    }

    @MainActor
    private func revealShowcaseLink(_ identifier: String, in scroll: XCUIElement, app: XCUIApplication) async -> XCUIElement? {
        let link = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        for _ in 0..<6 {
            if link.exists && link.isHittable { return link }
#if os(macOS)
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.55)).hover()
            scroll.scroll(byDeltaX: 0, deltaY: -650)
#else
            scroll.swipeUp(velocity: .fast)
#endif
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return link.exists && link.isHittable ? link : nil
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in scroll: XCUIElement) async -> Bool {
        for _ in 0..<5 {
            if element.exists && element.isHittable { return true }
#if os(macOS)
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.55)).hover()
            scroll.scroll(byDeltaX: 0, deltaY: -700)
#else
            scroll.swipeUp(velocity: .fast)
#endif
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return element.exists && element.isHittable
    }

    @MainActor
    private func clickCenter(_ element: XCUIElement) {
#if os(macOS)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
#else
        element.tap()
#endif
    }

    @MainActor
    private func navigationBackButton(in app: XCUIApplication) -> XCUIElement {
        let namedBack = app.buttons["Back"]
        if namedBack.exists { return namedBack }
        let navigationBarBack = app.navigationBars.buttons.firstMatch
        if navigationBarBack.exists { return navigationBarBack }
        return app.buttons["chevron.backward"]
    }

    @MainActor
    private func navigate(to screen: DemoScreen, in app: XCUIApplication) async {
#if os(macOS)
        // Match the visible outline row by its label. macOS 27 can mark SwiftUI sidebar rows disabled
        // in accessibility metadata even while their visible coordinates still select the destination.
        let outline = app.outlines.firstMatch
        // On macOS 27, OutlineRow has no label; its visible StaticText child exposes the title as value.
        let visibleLabel = outline.staticTexts.matching(NSPredicate(format: "value == %@", screen.name)).firstMatch
        guard visibleLabel.exists else {
            XCTFail("macOS should expose sidebar text for \(screen.name). Snapshot: \(app.debugDescription)")
            return
        }

        let labelCenter = CGPoint(x: visibleLabel.frame.midX, y: visibleLabel.frame.midY)
        let outlineRows = outline.children(matching: .any)
        var matchingRow: XCUIElement?
        for index in 0..<outlineRows.count {
            let candidate = outlineRows.element(boundBy: index)
            if candidate.frame.contains(labelCenter) {
                matchingRow = candidate
                break
            }
        }
        guard let row = matchingRow else {
            XCTFail("macOS should expose a sidebar outline row labeled \(screen.name). Snapshot: \(app.debugDescription)")
            return
        }

        let rowFrame = row.frame
        let windowFrame = app.windows.firstMatch.frame
        guard rowFrame.width > 0, rowFrame.height > 0, windowFrame.intersects(rowFrame) else {
            XCTFail("Sidebar row \(screen.name) has no visible bounds (row: \(rowFrame), window: \(windowFrame)). Snapshot: \(app.debugDescription)")
            return
        }

        if screen.name == "All Tests" {
            // XCTest's semantic tap waits for accessibility stabilization. A coordinate click keeps
            // navigation responsive so the scroll gesture can start in the same interaction turn.
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        } else if row.isEnabled && row.isHittable {
            row.backport.tap()
        } else {
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        if screen.name == "All Tests" {
            let list = app.outlines[screen.identifier]
            // The selected page swaps synchronously with the click. Send the pointer and wheel
            // gesture directly to its outline without waiting for accessibility existence.
            scrollThroughAllTests(list, in: app)
        }
        // A click can arrive while SwiftUI is changing screens even when XCTest reports the app idle.
        // Retry only this visible row, then verify its selected state directly before moving on.
        if !row.isSelected {
            try? await Task.sleep(nanoseconds: 100_000_000)
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        let selected = await waitForSelection(of: row, timeout: 1)
        XCTAssertTrue(
            selected,
            "Clicking the \(screen.name) sidebar row should select that visible row (enabled: \(row.isEnabled), row: \(rowFrame), window: \(windowFrame)). Snapshot: \(app.debugDescription)"
        )
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
            try? await Task.sleep(nanoseconds: 50_000_000) // 100_000_000 may have been too long
        } while true
    }

    @MainActor
    private func waitForSelection(of element: XCUIElement, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.isSelected { return true }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 50_000_000)
        } while true
    }

    @MainActor
    private func waitForLabel(_ element: XCUIElement, equalTo expected: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists && element.label == expected { return true }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 40_000_000)
        } while true
    }

    @MainActor
    private func waitForText(_ element: XCUIElement, containing expected: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let label = element.label
            let value = String(describing: element.value)
            if element.exists && (label.localizedCaseInsensitiveContains(expected) || value.localizedCaseInsensitiveContains(expected)) {
                return true
            }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 40_000_000)
        } while true
    }

    @MainActor
    private func waitForText(_ element: XCUIElement, containing expected: String, excluding excluded: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let text = element.label + " " + String(describing: element.value)
            if element.exists && text.localizedCaseInsensitiveContains(expected) && !text.localizedCaseInsensitiveContains(excluded) {
                return true
            }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 40_000_000)
        } while true
    }

    @MainActor
    private func waitForHeight(_ element: XCUIElement, greaterThan threshold: CGFloat, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists && element.frame.height > threshold { return true }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 40_000_000)
        } while true
    }

    @MainActor
    private func waitForHeight(_ element: XCUIElement, lessThan threshold: CGFloat, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists && element.frame.height < threshold { return true }
            if Date() >= deadline { return false }
            try? await Task.sleep(nanoseconds: 40_000_000)
        } while true
    }

    @MainActor
    private func scrollThroughAllTests(_ screenElement: XCUIElement, in app: XCUIApplication) {
#if os(macOS)
        // Move through the stable window geometry before querying the identified outline as a scroller.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.55)).hover()
        screenElement.scroll(byDeltaX: 0, deltaY: -10_000)
#else
        let scrollable = contentScrollable(in: screenElement)
        for _ in 0..<3 { scrollable.swipeUp(velocity: .fast) }
#endif

        // The UI tour should keep moving; module timing tests continue in the app independently.
    }

    @MainActor
    private func contentScrollable(in screenElement: XCUIElement) -> XCUIElement {
        if screenElement.elementType == .scrollView || screenElement.elementType == .table {
            return screenElement
        }
#if os(macOS)
        if screenElement.elementType == .outline {
            return screenElement
        }
#endif
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
