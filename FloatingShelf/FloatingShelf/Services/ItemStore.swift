//
//  ItemStore.swift
//  FloatingShelf
//

import Foundation
import CoreData

class ItemStore {
    
    static let shared = ItemStore()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FloatingShelf")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Shelf Operations
    
    func createShelf(position: CGPoint = CGPoint(x: 100, y: 100)) -> Shelf {
        let shelf = Shelf(positionX: Float(position.x), 
                         positionY: Float(position.y))
        let shelfMO = ShelfMO(context: viewContext, shelf: shelf)
        saveContext()
        return shelfMO.toShelf()
    }
    
    func fetchAllShelves() -> [Shelf] {
        let request: NSFetchRequest<ShelfMO> = ShelfMO.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let shelfMOs = try viewContext.fetch(request)
            return shelfMOs.map { $0.toShelf() }
        } catch {
            print("Error fetching shelves: \(error)")
            return []
        }
    }
    
    func fetchShelf(by id: UUID) -> Shelf? {
        let request: NSFetchRequest<ShelfMO> = ShelfMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first?.toShelf()
        } catch {
            print("Error fetching shelf: \(error)")
            return nil
        }
    }
    
    func updateShelf(_ shelf: Shelf) {
        let request: NSFetchRequest<ShelfMO> = ShelfMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", shelf.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let shelfMO = results.first {
                shelfMO.isPinned = shelf.isPinned
                shelfMO.isCollapsed = shelf.isCollapsed
                shelfMO.positionX = shelf.positionX
                shelfMO.positionY = shelf.positionY
                saveContext()
            }
        } catch {
            print("Error updating shelf: \(error)")
        }
    }
    
    func deleteShelf(_ shelfId: UUID) {
        let request: NSFetchRequest<ShelfMO> = ShelfMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", shelfId as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let shelfMO = results.first {
                viewContext.delete(shelfMO)
                saveContext()
            }
        } catch {
            print("Error deleting shelf: \(error)")
        }
    }
    
    // MARK: - Item Operations
    
    func addItem(_ item: ShelfItem, to shelfId: UUID) {
        let shelfRequest: NSFetchRequest<ShelfMO> = ShelfMO.fetchRequest()
        shelfRequest.predicate = NSPredicate(format: "id == %@", shelfId as CVarArg)
        
        do {
            let results = try viewContext.fetch(shelfRequest)
            if let shelfMO = results.first {
                let _ = ShelfItemMO(context: viewContext, item: item, shelf: shelfMO)
                saveContext()
            }
        } catch {
            print("Error adding item: \(error)")
        }
    }
    
    func fetchItems(for shelfId: UUID) -> [ShelfItem] {
        let request: NSFetchRequest<ShelfItemMO> = ShelfItemMO.fetchRequest()
        request.predicate = NSPredicate(format: "shelf.id == %@", shelfId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let itemMOs = try viewContext.fetch(request)
            return itemMOs.map { $0.toShelfItem() }
        } catch {
            print("Error fetching items: \(error)")
            return []
        }
    }
    
    func deleteItem(_ itemId: UUID) {
        let request: NSFetchRequest<ShelfItemMO> = ShelfItemMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let itemMO = results.first {
                viewContext.delete(itemMO)
                saveContext()
            }
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    func deleteItems(_ itemIds: [UUID]) {
        for itemId in itemIds {
            deleteItem(itemId)
        }
    }
}

// MARK: - NSManagedObject Fetch Requests

extension ShelfMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShelfMO> {
        return NSFetchRequest<ShelfMO>(entityName: "Shelf")
    }
}

extension ShelfItemMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShelfItemMO> {
        return NSFetchRequest<ShelfItemMO>(entityName: "ShelfItem")
    }
}
