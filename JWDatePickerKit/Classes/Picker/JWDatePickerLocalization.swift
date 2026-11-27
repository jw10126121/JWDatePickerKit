import Foundation

/// 组件与示例共用的文案，按指定语言环境查找资源，缺少翻译时回退到英文。
public enum JWDatePickerLocalization {
    public static func string(_ key: String, locale: Locale = .current) -> String {
#if SWIFT_PACKAGE
        let resources = Bundle.module
#else
        let framework = Bundle(for: JWDatePickerView.self)
        let resources = framework.url(forResource: "JWDatePickerKit", withExtension: "bundle")
            .flatMap(Bundle.init(url:)) ?? framework
#endif
        let language = Bundle.preferredLocalizations(from: resources.localizations, forPreferences: [locale.identifier]).first ?? "en"
        let localized = resources.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:))
        let english = resources.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:))
        let fallback = english?.localizedString(forKey: key, value: key, table: nil) ?? key
        return localized?.localizedString(forKey: key, value: fallback, table: nil) ?? fallback
    }
}
