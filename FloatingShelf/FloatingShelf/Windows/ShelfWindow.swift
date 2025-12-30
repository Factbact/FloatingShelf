//
//  ShelfWindow.swift
//  FloatingShelf
//

import Cocoa
import Quartz

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
        becomesKeyOnlyIfNeeded = false  // Allow keyboard events
        
        // Transparent window background for rounded corners
        backgroundColor = .clear
        isOpaque = false
        
        // Shadow for depth
        hasShadow = true
        
        // Apply rounded corners to content view
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 20
            contentView.layer?.cornerCurve = .continuous
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
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
    
    // MARK: - Quick Look Support
    
    private var localEventMonitor: Any?
    
    override func sendEvent(_ event: NSEvent) {
        // Intercept space bar before it reaches first responder
        if event.type == .keyDown && event.keyCode == 49 {
            toggleQuickLook()
            return  // Don't forward to responder chain
        }
        super.sendEvent(event)
    }
    
    func setupQuickLookMonitor() {
        // Remove existing monitors first
        removeQuickLookMonitor()
        
        // LOCAL monitor for when this app is active
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Space bar
                if let panel = QLPreviewPanel.shared(), panel.isVisible {
                    panel.orderOut(nil)
                    return nil  // Consume event
                }
            }
            return event
        }
        
        // GLOBAL monitor for when another app/window has focus
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Space bar
                if let panel = QLPreviewPanel.shared(), panel.isVisible {
                    DispatchQueue.main.async {
                        panel.orderOut(nil)
                    }
                }
            }
        }
    }
    
    private var globalEventMonitor: Any?
    
    func removeQuickLookMonitor() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    private func toggleQuickLook() {
        guard let panel = QLPreviewPanel.shared() else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
            removeQuickLookMonitor()
        } else {
            setupQuickLookMonitor()
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    deinit {
        removeQuickLookMonitor()
    }
}
