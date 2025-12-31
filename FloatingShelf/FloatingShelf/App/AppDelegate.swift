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
        
        // Set up main menu for keyboard shortcuts
        setupMainMenu()
        
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
    
    // MARK: - Main Menu (for keyboard shortcuts like Cmd+W)
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "FloatingShelf")
        appMenu.addItem(withTitle: "About FloatingShelf", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: L(.settings) + "...", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: L(.quit), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File menu (for Cmd+W, Cmd+N)
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: L(.newShelf), action: #selector(createNewShelf), keyEquivalent: "n")
        fileMenu.addItem(NSMenuItem.separator())
        // Use performClose: which uses responder chain - works with any window
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // Edit menu (for standard clipboard shortcuts)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func openSettings() {
        SettingsWindowController.shared.show()
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
        
        // Create new shelf in top-right corner
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let shelfSize = CGSize(width: Constants.defaultShelfWidth, height: Constants.defaultShelfHeight)
        let position = CGPoint(
            x: screen.visibleFrame.maxX - shelfSize.width - 20,
            y: screen.visibleFrame.maxY - shelfSize.height - 20
        )
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
