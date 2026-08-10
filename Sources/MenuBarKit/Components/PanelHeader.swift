import SwiftUI

/// Panel header row: optional leading accessory, headline title, and trailing actions.
public struct PanelHeader<Leading: View, Trailing: View>: View {
    private let title: String
    private let leading: Leading
    private let trailing: Trailing

    public init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            leading
            Text(title)
                .font(.headline)
            Spacer()
            trailing
        }
    }
}
