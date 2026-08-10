import Foundation

public extension Bundle {
    /// Resolves the SwiftPM resource bundle named `name` (without the `.bundle`
    /// extension) from the main bundle's Resources directory, falling back to
    /// `fallback` when it is not there (e.g. when running straight from the
    /// build directory). The fallback is evaluated lazily on purpose: SwiftPM's
    /// generated `Bundle.module` accessor probes the absolute build path baked
    /// into the binary, a filesystem read that must not happen in a bundled app.
    static func resourceBundle(named name: String, fallback: @autoclosure () -> Bundle) -> Bundle {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("\(name).bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return fallback()
    }
}
