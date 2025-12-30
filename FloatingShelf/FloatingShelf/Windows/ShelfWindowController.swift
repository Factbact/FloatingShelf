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
        
        let screenRect = screen.visibleFrame
        let cascadeOffset: CGFloat = 40
        
        // Default position: top-right corner
        var x = screenRect.maxX - Constants.defaultShelfWidth - 20
        var y = screenRect.maxY - Constants.defaultShelfHeight - 20
        
        // Find the most recently created active shelf
        // Iterate over keys (Shelf IDs) to find the latest shelf
        let sortedActiveShelves = activeShelves.keys.compactMap { id -> (Date, NSWindow)? in
            guard let shelf = ItemStore.shared.fetchShelf(by: id),
                  let window = activeShelves[id]?.window else { return nil }
            return (shelf.createdAt, window)
        }.sorted { $0.0 < $1.0 } // Sort by date ascending
        
        if let (_, lastWindow) = sortedActiveShelves.last {
            let lastFrame = lastWindow.frame
            
            // Offset down and to the left
            x = lastFrame.origin.x - cascadeOffset
            y = lastFrame.origin.y - cascadeOffset
            
            // Reset if off-screen (left edge)
            if x < screenRect.minX + 50 {
                x = screenRect.maxX - Constants.defaultShelfWidth - 20
            }
            
            // Reset if off-screen (bottom edge)
            if y < screenRect.minY + 50 {
                y = screenRect.maxY - Constants.defaultShelfHeight - 20
            }
        }
        
        return CGPoint(x: x, y: y)
    }
}
