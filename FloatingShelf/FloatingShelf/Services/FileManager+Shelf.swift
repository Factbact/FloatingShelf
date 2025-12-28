//
//  FileManager+Shelf.swift
//  FloatingShelf
//

import Foundation

extension FileManager {
    
    /// Get the main storage directory for shelf items
    func shelfStorageDirectory() throws -> URL {
        let appSupport = try url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.floatingshelf.app"
        let appDirectory = appSupport.appendingPathComponent(bundleID)
        let storageDirectory = appDirectory.appendingPathComponent(Constants.containerDirectoryName)
        
        try createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        return storageDirectory
    }
    
    /// Get the thumbnails directory
    func thumbnailsDirectory() throws -> URL {
        let storage = try shelfStorageDirectory()
        let thumbsDir = storage.appendingPathComponent(Constants.thumbnailsDirectoryName)
        try createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        return thumbsDir
    }
    
    /// Copy a file to shelf storage and return the new URL
    func copyToShelfStorage(_ sourceURL: URL) throws -> URL {
        let storageDir = try shelfStorageDirectory()
        let filename = sourceURL.lastPathComponent
        let destinationURL = uniqueFileURL(in: storageDir, preferredName: filename)
        
        try copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }
    
    /// Generate a unique file URL to avoid naming conflicts
    func uniqueFileURL(in directory: URL, preferredName: String) -> URL {
        var baseURL = directory.appendingPathComponent(preferredName)
        
        if !fileExists(atPath: baseURL.path) {
            return baseURL
        }
        
        // Extract name and extension
        let nameWithoutExtension = (preferredName as NSString).deletingPathExtension
        let fileExtension = (preferredName as NSString).pathExtension
        
        // Try numbered variants
        var counter = 1
        while true {
            let newName: String
            if fileExtension.isEmpty {
                newName = "\(nameWithoutExtension) \(counter)"
            } else {
                newName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            
            baseURL = directory.appendingPathComponent(newName)
            if !fileExists(atPath: baseURL.path) {
                return baseURL
            }
            counter += 1
        }
    }
    
    /// Calculate file size for a given URL
    func fileSize(at url: URL) -> Int64 {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else {
            return 0
        }
        return size.int64Value
    }
    
    /// Clean up orphaned files (files not referenced by any shelf item)
    func cleanupOrphanedFiles(referencedPaths: Set<String>) throws {
        let storageDir = try shelfStorageDirectory()
        let contents = try contentsOfDirectory(at: storageDir, includingPropertiesForKeys: nil)
        
        for fileURL in contents {
            let relativePath = fileURL.lastPathComponent
            if !referencedPaths.contains(relativePath) {
                try removeItem(at: fileURL)
            }
        }
    }
}
