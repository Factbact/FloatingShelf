//
//  Shelf.swift
//  FloatingShelf
//

import Foundation
import CoreData

/// Swift wrapper around ShelfMO (Core Data managed object)
struct Shelf {
    let id: UUID
    var createdAt: Date
    var isPinned: Bool
    var isCollapsed: Bool
    var positionX: Float
    var positionY: Float
    var items: [ShelfItem]
    
    init(id: UUID = UUID(),
         createdAt: Date = Date(),
         isPinned: Bool = false,
         isCollapsed: Bool = false,
         positionX: Float = 100,
         positionY: Float = 100,
         items: [ShelfItem] = []) {
        self.id = id
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.isCollapsed = isCollapsed
        self.positionX = positionX
        self.positionY = positionY
        self.items = items
    }
}

@objc(ShelfMO)
class ShelfMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var isPinned: Bool
    @NSManaged var isCollapsed: Bool
    @NSManaged var positionX: Float
    @NSManaged var positionY: Float
    @NSManaged var items: NSSet?
    
    convenience init(context: NSManagedObjectContext, shelf: Shelf) {
        self.init(context: context)
        self.id = shelf.id
        self.createdAt = shelf.createdAt
        self.isPinned = shelf.isPinned
        self.isCollapsed = shelf.isCollapsed
        self.positionX = shelf.positionX
        self.positionY = shelf.positionY
    }
    
    func toShelf() -> Shelf {
        let itemsArray = (items as? Set<ShelfItemMO>)?.map { $0.toShelfItem() } ?? []
        return Shelf(id: id,
                    createdAt: createdAt,
                    isPinned: isPinned,
                    isCollapsed: isCollapsed,
                    positionX: positionX,
                    positionY: positionY,
                    items: itemsArray)
    }
}
