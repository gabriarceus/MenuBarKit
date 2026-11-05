import SwiftUI

/// Observable current screen of a panel, for its SwiftUI views and its owner.
@MainActor
public final class PanelNavigation<Screen: Hashable>: ObservableObject {
    @Published public var screen: Screen

    public init(initial: Screen) {
        self.screen = initial
    }
}
