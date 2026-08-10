import SwiftUI

/// Panel navigation state, observable so both SwiftUI (back button, open a
/// sub-screen) and the panel's owner (reset on dismiss) can drive it.
@MainActor
public final class PanelNavigation<Screen: Hashable>: ObservableObject {
    @Published public var screen: Screen

    public init(initial: Screen) {
        self.screen = initial
    }
}
