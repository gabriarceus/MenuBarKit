import SwiftUI

/// Resolves UI strings from the `.strings` tables of a bundle, honoring an
/// optional language override. With no override, the bundle's own resolution
/// (the user's preferred languages) is used.
public struct Localizer: @unchecked Sendable {
    private let bundle: Bundle

    /// - Parameters:
    ///   - bundle: bundle containing the `.lproj` localization folders.
    ///   - language: language code to force, or `nil`/empty to follow the system.
    public init(bundle: Bundle, language: String?) {
        if let language, !language.isEmpty,
           let path = bundle.path(forResource: language, ofType: "lproj"),
           let localized = Bundle(path: path) {
            self.bundle = localized
        } else {
            self.bundle = bundle
        }
    }

    /// The localized value for [key], falling back to [key] itself when missing.
    /// [arguments] are substituted into `printf`-style format specifiers.
    public func string(_ key: String, arguments: [CVarArg] = []) -> String {
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        return arguments.isEmpty ? format : String(format: format, arguments: arguments)
    }

    public func callAsFunction(_ key: String, _ arguments: CVarArg...) -> String {
        string(key, arguments: arguments)
    }
}

private struct LocalizerKey: EnvironmentKey {
    static let defaultValue = Localizer(bundle: .main, language: nil)
}

public extension EnvironmentValues {
    /// The localizer used to resolve UI strings in the current view tree.
    var localizer: Localizer {
        get { self[LocalizerKey.self] }
        set { self[LocalizerKey.self] = newValue }
    }
}

/// A selectable UI language: an empty [code] follows the system.
public struct AppLanguageOption: Identifiable, Sendable {
    public let code: String
    public let name: String

    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }

    public var id: String { code }
}

public extension Bundle {
    /// Language options for a picker: a leading system-follow entry (empty code)
    /// followed by each bundled localization in its own autonym, sorted by name.
    func languageOptions(systemLabel: String) -> [AppLanguageOption] {
        let options = localizations
            .filter { $0 != "Base" }
            .map { code -> AppLanguageOption in
                let locale = Locale(identifier: code)
                let raw = locale.localizedString(forLanguageCode: code) ?? code
                let name = raw.prefix(1).uppercased(with: locale) + raw.dropFirst()
                return AppLanguageOption(code: code, name: name)
            }
            .sorted { $0.name < $1.name }
        return [AppLanguageOption(code: "", name: systemLabel)] + options
    }
}
