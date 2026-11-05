import Foundation

public extension Bundle {
    /// The SwiftPM resource bundle `name` (without `.bundle`) in the main bundle's Resources
    /// directory, or `fallback` when it is missing there, as in a run from the build directory.
    /// `fallback` is evaluated only in that case.
    static func resourceBundle(named name: String, fallback: @autoclosure () -> Bundle) -> Bundle {
        // SwiftPM's generated `Bundle.module` probes the absolute build path baked into the binary;
        // a shipped app must not read it.
        if let url = Bundle.main.resourceURL?.appendingPathComponent("\(name).bundle"),
            let bundle = Bundle(url: url)
        {
            return bundle
        }
        return fallback()
    }
}
