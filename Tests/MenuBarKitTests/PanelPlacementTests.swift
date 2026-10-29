import AppKit
import SwiftUI
import XCTest

@testable import MenuBarKit

final class PanelPlacementTests: XCTestCase {
    private let screens = [
        ScreenBounds(
            frame: NSRect(x: -1200, y: 0, width: 1200, height: 900),
            visibleFrame: NSRect(x: -1200, y: 0, width: 1200, height: 875)),
        ScreenBounds(
            frame: NSRect(x: 0, y: 0, width: 1600, height: 1000),
            visibleFrame: NSRect(x: 0, y: 40, width: 1600, height: 935)),
    ]

    func testActualAnchorSelectsItsDisplayWithNegativeOrigin() throws {
        let result = try XCTUnwrap(
            PanelPlacement.resolve(
                anchor: NSRect(x: -1195, y: 878, width: 24, height: 22), screens: screens,
                mainIndex: 1,
                panelSize: NSSize(width: 340, height: 400)
            ))
        XCTAssertEqual(result.topLeft.x, -1192)
        XCTAssertEqual(result.topLeft.y, 867)
        XCTAssertEqual(result.bounds, screens[0].visibleFrame.insetBy(dx: 8, dy: 8))
    }

    func testMissingHiddenAndInvalidAnchorsUseLiveMainScreen() throws {
        for anchor in [nil, NSRect(x: 5000, y: 5000, width: 20, height: 20), .zero] {
            let result = try XCTUnwrap(
                PanelPlacement.resolve(
                    anchor: anchor, screens: screens, mainIndex: 1,
                    panelSize: NSSize(width: 340, height: 400)))
            XCTAssertEqual(result.topLeft, NSPoint(x: 1252, y: 967))
        }
        XCTAssertNil(
            PanelPlacement.resolve(anchor: nil, screens: [], mainIndex: nil, panelSize: .zero))
    }

    func testDisplayRemovalFallsBackToRemainingScreen() throws {
        let result = try XCTUnwrap(
            PanelPlacement.resolve(
                anchor: NSRect(x: -1100, y: 878, width: 24, height: 22), screens: [screens[1]],
                mainIndex: nil,
                panelSize: NSSize(width: 340, height: 400)
            ))
        XCTAssertEqual(result.bounds, screens[1].visibleFrame.insetBy(dx: 8, dy: 8))
    }

    func testGrowthFitsAndOversizedContentAlignsToAvailableTopLeft() {
        let bounds = NSRect(x: -500, y: 40, width: 400, height: 500)
        XCTAssertEqual(
            PanelPlacement.fit(
                NSPoint(x: -200, y: 100), size: NSSize(width: 340, height: 400), bounds: bounds),
            NSPoint(x: -440, y: 440))
        XCTAssertEqual(
            PanelPlacement.fit(.zero, size: NSSize(width: 800, height: 900), bounds: bounds),
            NSPoint(x: -500, y: 540))
    }

    @MainActor
    func testFittingAppliesDuringResizeAndExplicitPresentationClearsIt() {
        _ = NSApplication.shared
        let panel = MenuBarPanel(rootView: Text("Content"), width: 340)
        defer { panel.dismiss() }
        let bounds = NSRect(x: 100, y: 100, width: 400, height: 500)
        let point = NSPoint(x: 480, y: 200)
        panel.present(at: point, fittingWithin: bounds)
        panel.setContentSize(NSSize(width: 340, height: 400))
        let fitted = PanelPlacement.fit(point, size: panel.frame.size, bounds: bounds)
        XCTAssertEqual(NSPoint(x: panel.frame.minX, y: panel.frame.maxY), fitted)
        panel.present(at: point)
        XCTAssertEqual(NSPoint(x: panel.frame.minX, y: panel.frame.maxY), point)
    }
}
