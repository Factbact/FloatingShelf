//
//  AppDelegate.swift
//  FloatingShelf
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?
    private var shelfWindowController: ShelfWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 FloatingShelf アプリケーション起動開始")
        
        // Set up menu bar icon
        print("📍 メニューバーのセットアップ開始...")
        setupMenuBar()
        print("📍 メニューバーのセットアップ完了")
        
        // Set up global hotkey
        print("⌨️ ホットキーのセットアップ開始...")
        setupHotkey()
        print("⌨️ ホットキーのセットアップ完了")
        
        // Initialize window controller
        print("🪟 ウィンドウコントローラーの初期化開始...")
        shelfWindowController = ShelfWindowController.shared
        print("🪟 ウィンドウコントローラーの初期化完了")
        
        print("✅ FloatingShelf アプリケーション起動完了！")
        
        // デバッグ用: 起動時にシェルフを自動表示
        print("🔍 デバッグ: シェルフを自動表示します")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.createNewShelf()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        hotkeyManager?.unregisterHotkey()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Menu Bar
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "Floating Shelf") {
                button.image = image
                button.image?.isTemplate = true
            } else {
                button.title = "📦"
                button.toolTip = "FloatingShelf"
            }
        }
        
        let menu = NSMenu()
        menu.addItem(withTitle: "New Shelf", action: #selector(createNewShelf), keyEquivalent: "n")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit FloatingShelf", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        statusItem?.menu = menu
    }
    
    // MARK: - Hotkey
    
    private func setupHotkey() {
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey(keyCode: Constants.defaultHotkeyKeyCode,
                                     modifiers: Constants.defaultHotkeyModifiers)
    }
    
    // MARK: - Actions
    
    @objc func createNewShelf() {
        shelfWindowController?.createNewShelf()
    }
    
    @objc func createNewShelfWithFiles(_ urls: [URL]) {
        print("📝 Creating new shelf with \(urls.count) files...")
        
        // Create new shelf
        let position = CGPoint(x: 200, y: 400)
        let shelf = ItemStore.shared.createShelf(position: position)
        
        // Show the shelf window
        shelfWindowController?.showShelf(shelf)
        
        // Add files to the new shelf
        let dropReceiver = DropReceiver(shelfId: shelf.id)
        
        // Process file URLs
        for url in urls {
            do {
                try dropReceiver.processFileURL(url)
            } catch {
                print("Error processing file: \(error)")
            }
        }
    }
}

// MARK: - HotkeyManagerDelegate

extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed() {
        createNewShelf()
    }
}
