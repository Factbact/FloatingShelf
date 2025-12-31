import Foundation
import ServiceManagement

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let autoHideEnabled = "autoHideEnabled"
        static let autoHideDelay = "autoHideDelay"
        static let defaultShelfColor = "defaultShelfColor"
        static let launchAtLogin = "launchAtLogin"
        static let zipSaveLocation = "zipSaveLocation"
    }
    
    // MARK: - Auto-Hide Settings
    
    /// Whether auto-hide is enabled (default: false)
    var autoHideEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoHideEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoHideEnabled) }
    }
    
    /// Auto-hide delay in seconds (default: 5)
    var autoHideDelay: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.autoHideDelay)
            return value > 0 ? value : 5.0
        }
        set { defaults.set(newValue, forKey: Keys.autoHideDelay) }
    }
    
    // MARK: - Appearance Settings
    
    /// Default shelf color hex (default: blue)
    var defaultShelfColor: String {
        get { defaults.string(forKey: Keys.defaultShelfColor) ?? "#4A90D9" }
        set { defaults.set(newValue, forKey: Keys.defaultShelfColor) }
    }
    
    // MARK: - Startup Settings
    
    /// Launch at login (default: false)
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLoginItem(enabled: newValue)
        }
    }
    
    /// Check if login item is currently enabled
    var isLaunchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return defaults.bool(forKey: Keys.launchAtLogin)
        }
    }
    
    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }
    
    // MARK: - ZIP Settings
    
    /// ZIP save location: "downloads", "desktop", or "ask"
    var zipSaveLocation: String {
        get { defaults.string(forKey: Keys.zipSaveLocation) ?? "downloads" }
        set { defaults.set(newValue, forKey: Keys.zipSaveLocation) }
    }
    
    // MARK: - Action Bar Settings
    
    /// Available button identifiers
    static let allButtonIds = ["selectAll", "sort", "share", "airdrop", "copy", "paste", "save", "zip", "delete"]
    
    /// Visible action bar buttons (default: selectAll, sort, share, paste, delete)
    var visibleActionButtons: [String] {
        get { defaults.stringArray(forKey: "visibleActionButtons") ?? ["selectAll", "sort", "share", "paste", "delete"] }
        set { defaults.set(newValue, forKey: "visibleActionButtons") }
    }
    
    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.autoHideEnabled: false,
            Keys.autoHideDelay: 5.0,
            Keys.defaultShelfColor: "#4A90D9",
            Keys.launchAtLogin: false,
            Keys.zipSaveLocation: "downloads",
            "visibleActionButtons": ["selectAll", "sort", "share", "paste", "delete"]
        ])
    }
}
