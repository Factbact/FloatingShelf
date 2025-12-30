//
//  DropReceiver.swift
//  FloatingShelf
//

import Cocoa
import UniformTypeIdentifiers

protocol DropReceiverDelegate: AnyObject {
    func dropReceiver(_ receiver: DropReceiver, didReceiveItems items: [ShelfItem])
    func dropReceiver(_ receiver: DropReceiver, didFailWithError error: Error)
}

class DropReceiver: NSObject {
    
    weak var delegate: DropReceiverDelegate?
    private let shelfId: UUID
    private var filePromiseHandler: FilePromiseHandler?
    
    var acceptedTypes: [NSPasteboard.PasteboardType] {
        return [
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png,
            NSPasteboard.PasteboardType("com.apple.NSFilePromiseReceiver")
        ]
    }
    
    init(shelfId: UUID) {
        self.shelfId = shelfId
        super.init()
        self.filePromiseHandler = FilePromiseHandler(shelfId: shelfId)
    }
    
    // MARK: - Dragging Destination
    
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(sender) {
            return .copy
        }
        return []
    }
    
    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return draggingEntered(sender)
    }
    
    func draggingExited(_ sender: NSDraggingInfo?) {
        // Optional cleanup if needed (e.g. notify delegate)
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        do {
            let items = try processPasteboard(pasteboard)
            
            // Add items to store
            for item in items {
                ItemStore.shared.addItem(item, to: shelfId)
            }
            
            delegate?.dropReceiver(self, didReceiveItems: items)
            return true
        } catch {
            delegate?.dropReceiver(self, didFailWithError: error)
            return false
        }
    }
    
    // MARK: - Processing
    
    private func canAcceptDrag(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        for type in acceptedTypes {
            if pasteboard.types?.contains(type) == true {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Pasteboard Processing
    
    /// Process pasteboard for clipboard paste support (public for ⌘+V)
    func processPasteboard(_ pasteboard: NSPasteboard) throws -> [ShelfItem] {
        var items: [ShelfItem] = []
        
        // Priority 1: File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls where url.isFileURL {
                let item = try processFileURL(url)
                items.append(item)
            }
        }
        
        // Priority 2: File Promises (handled separately via NSFilePromiseReceiver)
        if let filePromises = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] {
            for promise in filePromises {
                filePromiseHandler?.receivePromise(promise) { [weak self] item, error in
                    guard let self = self else { return }
                    if let item = item {
                        ItemStore.shared.addItem(item, to: self.shelfId)
                        self.delegate?.dropReceiver(self, didReceiveItems: [item])
                    } else if let error = error {
                        self.delegate?.dropReceiver(self, didFailWithError: error)
                    }
                }
            }
        }
        
        // Priority 3: Images
        if items.isEmpty, let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
            for image in images {
                let item = try processImage(image)
                items.append(item)
            }
        }
        
        // Priority 4: URLs (web links)
        if items.isEmpty, let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls where !url.isFileURL {
                let item = processURL(url)
                items.append(item)
            }
        }
        
        // Priority 5: Text
        if items.isEmpty, let text = pasteboard.string(forType: .string) {
            let item = processText(text)
            items.append(item)
        }
        
        return items
    }
    
    // MARK: - Item Processing
    
    func processFileURL(_ url: URL) throws -> ShelfItem {
        // Copy file to storage
        let copiedURL = try FileManager.default.copyToShelfStorage(url)
        let relativePath = copiedURL.lastPathComponent
        
        // Generate thumbnail
        var thumbnailPath: String?
        if let thumbnail = ThumbnailGenerator.shared.generateFileThumbnail(for: copiedURL) {
            let thumbnailURL = try ThumbnailGenerator.shared.saveThumbnail(thumbnail, identifier: UUID().uuidString)
            thumbnailPath = thumbnailURL.lastPathComponent
        }
        
        let fileSize = FileManager.default.fileSize(at: copiedURL)
        
        return ShelfItem(
            displayName: url.lastPathComponent,
            kind: .file,
            payloadPath: relativePath,
            thumbnailPath: thumbnailPath,
            fileSize: fileSize
        )
    }
    
    private func processImage(_ image: NSImage) throws -> ShelfItem {
        let imageId = UUID()
        
        // Save image to storage
        let storageDir = try FileManager.default.shelfStorageDirectory()
        let imageFilename = "\(imageId.uuidString).png"
        let imageURL = storageDir.appendingPathComponent(imageFilename)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "DropReceiver", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        try pngData.write(to: imageURL)
        
        // Generate thumbnail
        var thumbnailPath: String?
        if let thumbnail = ThumbnailGenerator.shared.generateImageThumbnail(from: image) {
            let thumbnailURL = try ThumbnailGenerator.shared.saveThumbnail(thumbnail, identifier: imageId.uuidString)
            thumbnailPath = thumbnailURL.lastPathComponent
        }
        
        let fileSize = FileManager.default.fileSize(at: imageURL)
        
        return ShelfItem(
            displayName: "Image \(Date().formatted())",
            kind: .image,
            payloadPath: imageFilename,
            thumbnailPath: thumbnailPath,
            fileSize: fileSize
        )
    }
    
    private func processURL(_ url: URL) -> ShelfItem {
        return ShelfItem(
            displayName: url.absoluteString,
            kind: .url,
            fileSize: Int64(url.absoluteString.utf8.count)
        )
    }
    
    private func processText(_ text: String) -> ShelfItem {
        return ShelfItem(
            displayName: text,
            kind: .text,
            fileSize: Int64(text.utf8.count)
        )
    }
}
