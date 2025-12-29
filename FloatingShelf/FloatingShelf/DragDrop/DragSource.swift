//
//  DragSource.swift
//  FloatingShelf
//

import Cocoa

class DragSource: NSObject, NSDraggingSource, NSFilePromiseProviderDelegate {
    
    private let item: ShelfItem
    private var filePromiseProvider: NSFilePromiseProvider?
    
    init(item: ShelfItem) {
        self.item = item
        super.init()
    }
    
    // MARK: - File Promise
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return item.displayName
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            if let payloadPath = item.payloadPath {
                let storageDir = try FileManager.default.shelfStorageDirectory()
                let sourceURL = storageDir.appendingPathComponent(payloadPath)
                
                // Copy file to the promised location
                try FileManager.default.copyItem(at: sourceURL, to: url)
                completionHandler(nil)
            } else {
                completionHandler(NSError(domain: "FloatingShelf", code: 1, userInfo: [NSLocalizedDescriptionKey: "No payload path"]))
            }
        } catch {
            completionHandler(error)
        }
    }
    
    // MARK: - Helper to get dragging items
    
    func draggingItems(for image: NSImage) -> [NSDraggingItem] {
        var draggingItems: [NSDraggingItem] = []
        
        switch item.kind {
        case .file, .promisedFile, .image: // Use File Promise for files and images
            let provider = NSFilePromiseProvider(fileType: kUTTypeData as String, delegate: self)
            self.filePromiseProvider = provider
            
            // Also provide original URL if creating from existing file for better compat
            // But relying on promise is safer for "Drag out"
            
            let draggingItem = NSDraggingItem(pasteboardWriter: provider)
            draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), contents: image)
            draggingItems.append(draggingItem)
            
        case .text, .url:
            // Standard handling for non-files
            let pasteboardItem = NSPasteboardItem()
            if item.kind == .url {
                pasteboardItem.setString(item.displayName, forType: .URL)
                pasteboardItem.setString(item.displayName, forType: .string)
            } else {
                pasteboardItem.setString(item.displayName, forType: .string)
            }
            
            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), contents: image)
            draggingItems.append(draggingItem)
        }
        
        return draggingItems
    }

    // MARK: - NSDraggingSource
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
}
