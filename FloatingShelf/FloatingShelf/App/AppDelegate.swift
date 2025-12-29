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
        
        // Create custom view for drag and drop support
        let menuBarView = MenuBarView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
        menuBarView.appDelegate = self
        statusItem?.view = menuBarView
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
    
    @objc func openShelf(_ shelfId: UUID) {
        guard let shelf = ItemStore.shared.fetchShelf(by: shelfId) else { return }
        shelfWindowController?.showShelf(shelf)
    }
    
    @objc func createNewShelfWithFiles(_ urls: [URL]) {
        print("📝 Creating new shelf with \(urls.count) files...")
        
        // Create new shelf with first file name
        let position = CGPoint(x: 200, y: 400)
        var shelf = ItemStore.shared.createShelf(position: position)
        
        // Set shelf name to first file name (without extension)
        if let firstFile = urls.first {
            shelf.name = firstFile.deletingPathExtension().lastPathComponent
            ItemStore.shared.updateShelf(shelf)
        }
        
        // Add files to the shelf
        let dropReceiver = DropReceiver(shelfId: shelf.id)
        
        for url in urls {
            do {
                let item = try dropReceiver.processFileURL(url)
                ItemStore.shared.addItem(item, to: shelf.id)
                print("✅ Added file: \(url.lastPathComponent)")
            } catch {
                print("❌ Error processing file: \(error)")
            }
        }
        
        // Show the shelf window (after files are added)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.shelfWindowController?.showShelf(shelf)
        }
    }
}

// MARK: - HotkeyManagerDelegate

extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed() {
        createNewShelf()
    }
}
