// LocaleManager.swift

import SwiftUI

class LocaleManager: ObservableObject {
    @Published var currentLocale: String {
        didSet {
            UserDefaults.standard.set(currentLocale, forKey: "AppLanguage")
        }
    }

    init() {
        self.currentLocale = UserDefaults.standard.string(forKey: "AppLanguage") ?? "ja"
    }

    func toggleLocale() {
        currentLocale = (currentLocale == "ja") ? "en" : "ja"
    }
}
