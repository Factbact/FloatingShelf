//
//  ShelfItem.swift
//  FloatingShelf
//

import Foundation
import CoreData

/// Swift wrapper around ShelfItemMO (Core Data managed object)
struct ShelfItem {
    let id: UUID
    var createdAt: Date
    var displayName: String
    var kind: ItemKind
    var payloadPath: String?  // Path to file in container storage
    var thumbnailPath: String?  // Path to thumbnail image
    var fileSize: Int64
    var sourceApp: String?
    
    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         displayName: String,
         kind: ItemKind,
         payloadPath: String? = nil,
         thumbnailPath: String? = nil,
         fileSize: Int64 = 0,
         sourceApp: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.displayName = displayName
        self.kind = kind
        self.payloadPath = payloadPath
        self.thumbnailPath = thumbnailPath
        self.fileSize = fileSize
        self.sourceApp = sourceApp
    }
}

@objc(ShelfItemMO)
class ShelfItemMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var displayName: String
    @NSManaged var kind: String
    @NSManaged var payloadPath: String?
    @NSManaged var thumbnailPath: String?
    @NSManaged var fileSize: Int64
    @NSManaged var sourceApp: String?
    @NSManaged var shelf: ShelfMO?
    
    convenience init(context: NSManagedObjectContext, item: ShelfItem, shelf: ShelfMO?) {
        self.init(context: context)
        self.id = item.id
        self.createdAt = item.createdAt
        self.displayName = item.displayName
        self.kind = item.kind.rawValue
        self.payloadPath = item.payloadPath
        self.thumbnailPath = item.thumbnailPath
        self.fileSize = item.fileSize
        self.sourceApp = item.sourceApp
        self.shelf = shelf
    }
    
    func toShelfItem() -> ShelfItem {
        return ShelfItem(id: id,
                        createdAt: createdAt,
                        displayName: displayName,
                        kind: ItemKind(rawValue: kind) ?? .file,
                        payloadPath: payloadPath,
                        thumbnailPath: thumbnailPath,
                        fileSize: fileSize,
                        sourceApp: sourceApp)
    }
}
