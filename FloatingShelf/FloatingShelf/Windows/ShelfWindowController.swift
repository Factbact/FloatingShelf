//
//  ShelfWindowController.swift
//  FloatingShelf
//

import Cocoa

class ShelfWindowController: NSWindowController {
    
    static let shared = ShelfWindowController()
    
    private var activeShelves: [UUID: NSWindowController] = [:]
    
    private init() {
        super.init(window: nil)
        loadPersistedShelves()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Shelf Creation
    
    func createNewShelf() {
        // Determine position for new shelf (cascade from last shelf or default)
        let position = determineNewShelfPosition()
        
        // Create shelf in database
        let shelf = ItemStore.shared.createShelf(position: position)
        
        // Create and show window
        showShelf(shelf)
    }
    
    func showShelf(_ shelf: Shelf) {
        // Check if already showing
        if activeShelves[shelf.id] != nil {
            activeShelves[shelf.id]?.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create window
        let window = ShelfWindow(shelf: shelf)
        let viewController = ShelfViewController(shelf: shelf)
        window.contentViewController = viewController
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        activeShelves[shelf.id] = windowController
        
        // Observe window close
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shelfWindowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }
    
    @objc private func shelfWindowWillClose(_ notification: Notification) {
        guard let window = notification.object as? ShelfWindow else { return }
        
        // Find and remove from active shelves
        if let shelfId = activeShelves.first(where: { $0.value.window === window })?.key {
            activeShelves.removeValue(forKey: shelfId)
            
            // Optionally delete shelf from database if not pinned
            if let shelf = ItemStore.shared.fetchShelf(by: shelfId), !shelf.isPinned {
                ItemStore.shared.deleteShelf(shelfId)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadPersistedShelves() {
        let shelves = ItemStore.shared.fetchAllShelves()
        for shelf in shelves where shelf.isPinned {
            showShelf(shelf)
        }
    }
    
    private func determineNewShelfPosition() -> CGPoint {
        guard let screen = NSScreen.main else {
            return CGPoint(x: 100, y: 100)
        }
        
        // Center of screen
        let screenRect = screen.visibleFrame
        let x = screenRect.midX - Constants.defaultShelfWidth / 2
        let y = screenRect.midY - Constants.defaultShelfHeight / 2
        
        return CGPoint(x: x, y: y)
    }
}
