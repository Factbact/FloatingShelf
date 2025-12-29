//
//  ThumbnailGenerator.swift
//  FloatingShelf
//

import Cocoa
import QuickLookThumbnailing

class ThumbnailGenerator {
    
    static let shared = ThumbnailGenerator()
    
    private init() {}
    
    /// Generate a thumbnail for an image
    func generateImageThumbnail(from image: NSImage, size: CGFloat = Constants.itemThumbnailSize) -> NSImage? {
        let targetSize = NSSize(width: size, height: size)
        
        guard let resized = image.resized(to: targetSize) else {
            return nil
        }
        
        return resized
    }
    
    /// Generate a thumbnail for a file URL
    func generateFileThumbnail(for url: URL, size: CGFloat = Constants.itemThumbnailSize) -> NSImage? {
        // Try to get Quick Look thumbnail first
        if let qlImage = quickLookThumbnail(for: url, size: size) {
            return qlImage
        }
        
        // Fall back to workspace icon
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    
    /// Save thumbnail to disk and return the file URL
    func saveThumbnail(_ image: NSImage, identifier: String) throws -> URL {
        let thumbnailsDir = try FileManager.default.thumbnailsDirectory()
        let filename = "\(identifier).png"
        let fileURL = thumbnailsDir.appendingPathComponent(filename)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ThumbnailGenerator", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG data"])
        }
        
        try pngData.write(to: fileURL)
        return fileURL
    }
    
    /// Load thumbnail from disk
    func loadThumbnail(at url: URL) -> NSImage? {
        return NSImage(contentsOf: url)
    }
    
    // MARK: - Private Helpers
    
    private func quickLookThumbnail(for url: URL, size: CGFloat) -> NSImage? {
        // Use QuickLook to generate thumbnail (macOS 10.15+)
        if #available(macOS 10.15, *) {
            let targetSize = CGSize(width: size * 2, height: size * 2) // Retina
            let request = QLThumbnailGenerator.Request(fileAt: url, 
                                                       size: targetSize,
                                                       scale: 2.0,
                                                       representationTypes: .thumbnail)
            
            var thumbnailImage: NSImage?
            let semaphore = DispatchSemaphore(value: 0)
            
            QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
                if let thumbnail = thumbnail {
                    thumbnailImage = thumbnail.nsImage
                }
                semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 2.0)
            return thumbnailImage
        }
        
        return nil
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage? {
        let sourceSize = self.size
        guard sourceSize.width > 0 && sourceSize.height > 0 else { return nil }
        
        // Calculate aspect-fit dimensions
        let aspectRatio = sourceSize.width / sourceSize.height
        var newSize = targetSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize.height = targetSize.width / aspectRatio
        } else {
            // Portrait or square
            newSize.width = targetSize.height * aspectRatio
        }
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high
        
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: sourceSize),
                  operation: .copy,
                  fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
}

@available(macOS 10.15, *)
extension QLThumbnailRepresentation {
    var nsImage: NSImage {
        return NSImage(cgImage: self.cgImage, size: self.contentRect.size)
    }
}
