import Combine
import XCTest

@testable import MenuBarKit

final class PanelNavigationTests: XCTestCase {
    private enum Screen: Hashable {
        case root, settings
    }

    @MainActor
    func testInitialScreenIsPublished() {
        let navigation = PanelNavigation(initial: Screen.root)
        XCTAssertEqual(navigation.screen, .root)
    }

    @MainActor
    func testScreenMutationPublishesNewValue() {
        let navigation = PanelNavigation(initial: Screen.root)
        var received: [Screen] = []
        var cancellables = Set<AnyCancellable>()

        navigation.$screen.sink { received.append($0) }.store(in: &cancellables)

        navigation.screen = .settings
        XCTAssertEqual(received, [.root, .settings])
    }
}
