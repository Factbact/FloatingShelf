//
//  ShelfWindow.swift
//  FloatingShelf
//

import Cocoa

class ShelfWindow: NSPanel {
    
    private var shelf: Shelf
    
    init(shelf: Shelf) {
        self.shelf = shelf
        
        let contentRect = NSRect(
            x: CGFloat(shelf.positionX),
            y: CGFloat(shelf.positionY),
            width: Constants.defaultShelfWidth,
            height: Constants.defaultShelfHeight
        )
        
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Popup/Picture-in-Picture Style: Borderless floating panel
        styleMask = [.borderless, .nonactivatingPanel, .resizable]
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        
        // Standard background (not transparent)
        backgroundColor = NSColor.windowBackgroundColor
        
        // Shadow for depth
        hasShadow = true
        
        // Make movable by background
        isMovableByWindowBackground = true
        
        // Auto-save position
        setFrameAutosaveName("ShelfWindow_\(shelf.id.uuidString)")
    }
    
    override func performClose(_ sender: Any?) {
        // Save position before closing
        let frame = self.frame
        shelf.positionX = Float(frame.origin.x)
        shelf.positionY = Float(frame.origin.y)
        ItemStore.shared.updateShelf(shelf)
        
        super.performClose(sender)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
