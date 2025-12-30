//
//  MenuBarView.swift
//  FloatingShelf
//

import Cocoa

class MenuBarView: NSView {
    weak var appDelegate: AppDelegate?
    private var isHighlighted = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Register for drag types
        registerForDraggedTypes([.fileURL, .URL])
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw background when highlighted (during drag)
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).setFill()
            dirtyRect.fill()
        }
        
        // Draw menu bar icon (custom or fallback to system)
        let image: NSImage?
        if let customIcon = NSImage(named: "MenuBarIcon") {
            image = customIcon
        } else {
            image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "FloatingShelf")
        }
        
        if let image = image {
            image.isTemplate = true
            
            let imageSize = NSSize(width: 18, height: 18)
            let imageRect = NSRect(
                x: (bounds.width - imageSize.width) / 2,
                y: (bounds.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
            
            image.draw(in: imageRect)
        }
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        // Left click -> Show Recent Shelves (Dropover style)
        showRecentShelvesPopover()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        // Right click -> Show context menu
        showMenu()
    }
    
    private var popover: NSPopover?
    
    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "New Shelf", action: #selector(AppDelegate.createNewShelf), keyEquivalent: "n")
        menu.addItem(NSMenuItem.separator())
        
        // Recent Shelves - opens popover
        let recentItem = NSMenuItem(title: "Recent Shelves...", action: #selector(showRecentShelvesPopover), keyEquivalent: "")
        recentItem.target = self
        menu.addItem(recentItem)
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit FloatingShelf", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Position menu below the view
        let location = NSPoint(x: 0, y: 0)
        menu.popUp(positioning: nil, at: location, in: self)
    }
    
    @objc private func showRecentShelvesPopover() {
        // Close existing popover
        popover?.close()
        
        // Create popover
        let newPopover = NSPopover()
        newPopover.behavior = .transient
        newPopover.contentSize = NSSize(width: 280, height: 300)
        
        let popoverVC = RecentShelvesPopover()
        popoverVC.appDelegate = appDelegate
        newPopover.contentViewController = popoverVC
        
        // Show below the menu bar view
        newPopover.show(relativeTo: bounds, of: self, preferredEdge: .minY)
        popover = newPopover
    }
    
    @objc private func showSettings() {
        SettingsWindowController.shared.show()
    }
    
    // MARK: - Drag and Drop
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Check if we have file URLs
        if sender.draggingPasteboard.types?.contains(.fileURL) == true {
            isHighlighted = true
            needsDisplay = true
            return .copy
        }
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
        needsDisplay = true
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isHighlighted = false
        needsDisplay = true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isHighlighted = false
        needsDisplay = true
        
        let pasteboard = sender.draggingPasteboard
        
        // Get file URLs from pasteboard
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              !urls.isEmpty else {
            return false
        }
        
        // Create new shelf with the dropped files
        DispatchQueue.main.async { [weak self] in
            self?.appDelegate?.createNewShelfWithFiles(urls)
        }
        
        return true
    }
}
