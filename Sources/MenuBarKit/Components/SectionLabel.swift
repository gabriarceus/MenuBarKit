import SwiftUI

/// Small uppercase-style field label used above form inputs.
public struct SectionLabel: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(Theme.Typography.fieldLabel)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}
