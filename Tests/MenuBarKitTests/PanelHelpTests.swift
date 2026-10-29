import XCTest

@testable import MenuBarKit

final class PanelHelpTests: XCTestCase {
    @MainActor
    func testReleaseCancelsPendingPresentation() async {
        var presentation: HelpPresentation? = HelpPresentation()
        let released = { [weak presentation] in presentation }
        presentation?.schedule()
        let pending = presentation?.pendingTask
        presentation = nil
        await pending?.value
        XCTAssertNil(released())
    }

    @MainActor
    func testExitOrRemovalCancelsPendingPresentation() async {
        let presentation = HelpPresentation()
        presentation.schedule()
        let pending = presentation.pendingTask
        presentation.cancel()
        await pending?.value
        XCTAssertFalse(presentation.isPresented)
        XCTAssertNil(presentation.pendingTask)
    }

    @MainActor
    func testNewHoverReplacesPendingPresentation() async {
        let presentation = HelpPresentation()
        presentation.schedule()
        let previous = presentation.pendingTask
        presentation.schedule()
        let current = presentation.pendingTask
        await previous?.value
        XCTAssertFalse(presentation.isPresented)
        await current?.value
        XCTAssertTrue(presentation.isPresented)
        presentation.cancel()
        XCTAssertFalse(presentation.isPresented)
    }

    func testPlacementStaysInsideEveryEdge() {
        let container = CGSize(width: 340, height: 200)
        let bounds = CGRect(origin: .zero, size: container).insetBy(dx: 4, dy: 4)
        for target in [
            CGRect(x: 0, y: 0, width: 20, height: 20),
            CGRect(x: 320, y: 0, width: 20, height: 20),
            CGRect(x: 0, y: 180, width: 20, height: 20),
            CGRect(x: 320, y: 180, width: 20, height: 20),
        ] {
            let frame = HelpPlacement.frame(
                target: target, bubble: CGSize(width: 260, height: 80), container: container)
            XCTAssertTrue(bounds.contains(frame), "\(frame)")
        }
    }

    func testOversizedHelpFitsHostAndPrefersAboveWhenPossible() {
        let container = CGSize(width: 100, height: 60)
        let fitted = HelpPlacement.frame(
            target: CGRect(x: 80, y: 40, width: 20, height: 20),
            bubble: CGSize(width: 400, height: 200), container: container
        )
        XCTAssertEqual(fitted, CGRect(x: 4, y: 4, width: 92, height: 52))
        let above = HelpPlacement.frame(
            target: CGRect(x: 40, y: 40, width: 10, height: 10),
            bubble: CGSize(width: 30, height: 20), container: container
        )
        XCTAssertEqual(above.maxY, 36)
    }

    func testEmptyAndTinyHostsDoNotPlaceHelpOutsideBounds() {
        for container in [CGSize.zero, CGSize(width: 2, height: 6)] {
            let frame = HelpPlacement.frame(
                target: .zero, bubble: CGSize(width: 260, height: 80), container: container
            )
            XCTAssertGreaterThanOrEqual(frame.minX, 0)
            XCTAssertGreaterThanOrEqual(frame.minY, 0)
            XCTAssertLessThanOrEqual(frame.maxX, container.width)
            XCTAssertLessThanOrEqual(frame.maxY, container.height)
        }
    }
}
