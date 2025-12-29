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
        
        // Draw the tray icon
        if let image = NSImage(systemSymbolName: "tray.fill", accessibilityDescription: "FloatingShelf") {
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
        // Show menu on click
        showMenu()
    }
    
    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "New Shelf", action: #selector(AppDelegate.createNewShelf), keyEquivalent: "n")
        menu.addItem(NSMenuItem.separator())
        
        // Recent Shelves submenu
        let recentItem = NSMenuItem(title: "Recent Shelves", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu()
        
        let shelves = ItemStore.shared.fetchAllShelves()
        if shelves.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent shelves", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            recentMenu.addItem(emptyItem)
        } else {
            for (index, shelf) in shelves.prefix(5).enumerated() {
                let shelfItem = NSMenuItem(title: shelf.name, action: #selector(openRecentShelf(_:)), keyEquivalent: "")
                shelfItem.tag = index
                shelfItem.target = self
                shelfItem.representedObject = shelf.id
                recentMenu.addItem(shelfItem)
            }
        }
        
        recentItem.submenu = recentMenu
        menu.addItem(recentItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit FloatingShelf", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Position menu below the view
        let location = NSPoint(x: 0, y: 0)
        menu.popUp(positioning: nil, at: location, in: self)
    }
    
    @objc private func openRecentShelf(_ sender: NSMenuItem) {
        guard let shelfId = sender.representedObject as? UUID else { return }
        appDelegate?.openShelf(shelfId)
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
