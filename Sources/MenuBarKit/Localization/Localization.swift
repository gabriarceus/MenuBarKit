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
            let localized = Bundle(path: path)
        {
            self.bundle = localized
        } else {
            self.bundle = bundle
        }
    }

    /// The localized value for [key], falling back to [key] itself when missing.
    /// [arguments] are substituted into `printf`-style format specifiers; a
    /// mismatch between arguments and specifiers returns the unformatted string
    /// instead of crashing.
    public func string(_ key: String, arguments: [CVarArg] = []) -> String {
        let format = bundle.localizedString(forKey: key, value: key, table: nil)
        guard !arguments.isEmpty else { return format }
        return (try? format.substituting(arguments)) ?? format
    }

    public func callAsFunction(_ key: String, _ arguments: CVarArg...) -> String {
        string(key, arguments: arguments)
    }
}

private struct LocalizerKey: EnvironmentKey {
    static let defaultValue = Localizer(bundle: .main, language: nil)
}

extension EnvironmentValues {
    /// The localizer used to resolve UI strings in the current view tree.
    public var localizer: Localizer {
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

extension Bundle {
    /// Language options for a picker: a leading system-follow entry (empty code)
    /// followed by each bundled localization in its own autonym, sorted by name.
    public func languageOptions(systemLabel: String) -> [AppLanguageOption] {
        let options =
            localizations
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

extension String {
    /// Substitutes `printf`-style specifiers, returning the receiver unchanged
    /// when the arguments do not match the format (instead of crashing).
    fileprivate func substituting(_ arguments: [CVarArg]) throws -> String {
        try String(format: self, locale: Locale.current, arguments: validated(arguments))
    }

    private func validated(_ arguments: [CVarArg]) throws -> [CVarArg] {
        let specifierCount = components(separatedBy: "%").count - 1
        guard specifierCount == arguments.count else {
            throw FormatMismatchError(expected: specifierCount, actual: arguments.count)
        }
        return arguments
    }
}

private struct FormatMismatchError: Error {
    let expected: Int
    let actual: Int
}
