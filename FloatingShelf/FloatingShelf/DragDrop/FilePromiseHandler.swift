//
//  FilePromiseHandler.swift
//  FloatingShelf
//

import Cocoa

class FilePromiseHandler {
    
    private let shelfId: UUID
    private let operationQueue = OperationQueue()
    
    init(shelfId: UUID) {
        self.shelfId = shelfId
        operationQueue.qualityOfService = .userInitiated
    }
    
    func receivePromise(_ receiver: NSFilePromiseReceiver, completion: @escaping (ShelfItem?, Error?) -> Void) {
        operationQueue.addOperation {
            do {
                let item = try self.syncReceivePromise(receiver)
                DispatchQueue.main.async {
                    completion(item, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    private func syncReceivePromise(_ receiver: NSFilePromiseReceiver) throws -> ShelfItem {
        // Create temporary directory for receiving
        let tempDir = try FileManager.default.shelfStorageDirectory()
            .appendingPathComponent("Temp")
        
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var receivedURL: URL?
        var receiveError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        
        // Receive the file promise
        receiver.receivePromisedFiles(atDestination: tempDir, options: [:], operationQueue: OperationQueue.main) { url, error in
            receivedURL = url
            receiveError = error
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = receiveError {
            throw error
        }
        
        guard let tempURL = receivedURL else {
            throw NSError(domain: "FilePromiseHandler", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "No file received"])
        }
        
        // Move from temp to permanent storage
        let storageDir = try FileManager.default.shelfStorageDirectory()
        let filename = tempURL.lastPathComponent
        let destinationURL = FileManager.default.uniqueFileURL(in: storageDir, preferredName: filename)
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        // Generate thumbnail
        var thumbnailPath: String?
        if let thumbnail = ThumbnailGenerator.shared.generateFileThumbnail(for: destinationURL) {
            let thumbnailURL = try ThumbnailGenerator.shared.saveThumbnail(thumbnail, identifier: UUID().uuidString)
            thumbnailPath = thumbnailURL.lastPathComponent
        }
        
        let fileSize = FileManager.default.fileSize(at: destinationURL)
        
        return ShelfItem(
            displayName: filename,
            kind: .promisedFile,
            payloadPath: destinationURL.lastPathComponent,
            thumbnailPath: thumbnailPath,
            fileSize: fileSize,
            sourceApp: receiver.fileNames.first
        )
    }
}
