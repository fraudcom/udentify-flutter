import Foundation

/// The language the app asked the SDKs to use, and the bundle that serves it.
///
/// iOS resolves a bundle's `.lproj` by device language, so the SDKs take a `bundle:` from the host
/// and use whatever they are given. This picks the language-specific sub-bundle, so the language
/// the app chose (via `instantiateServerBasedLocalization`) also decides the static strings. It only
/// covers keys the server-hosted language pack does not already answer.
public final class UdentifyLanguagePreference {

    /// The last language passed to `instantiateServerBasedLocalization`, as the `LocalizationLanguage`
    /// raw value (`"TR"`, `"EN"`, ...). `nil` means the app never chose one, and every bundle then
    /// resolves by device language exactly as it did before this existed.
    public private(set) static var selected: String?

    public static func select(_ language: String?) {
        selected = language?.uppercased()
    }

    /// The bundle to hand an SDK for `resourceBundle`, narrowed to the selected language when that
    /// language is actually present in it. Falls back to `resourceBundle` untouched when no language
    /// is selected or the bundle has no table for it, so a missing translation degrades to the
    /// device-language behaviour rather than to nothing.
    public static func localizedBundle(for resourceBundle: Bundle) -> Bundle {
        guard let language = selected else { return resourceBundle }
        // .lproj directories are lowercase two-letter codes; the SDK enum is uppercase.
        guard let path = resourceBundle.path(forResource: language.lowercased(), ofType: "lproj"),
              let localized = Bundle(path: path) else {
            return resourceBundle
        }
        return localized
    }
}
