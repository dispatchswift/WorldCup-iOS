//
//  CoreDataStack.swift
//  World Cup
//
//  Created by Cleopatra on 9/24/21.
//

import Foundation
import CoreData

/*
 This object wraps an instance of NSPersistenceContainer, which in turn contains the cadre of Core Data
 objects known as the "stack"; the context, the model, the persistent store and the persistent store coordinator.

 Even though NSPersistentContainer has public accessors for its managed context,
 the managed model, the store coordinator and the persistent stores (via [NSPersistentStoreDescription]),
 CoreDataStack works a bit different.
 
 For instance, the only public accessible part of CoreDataStack is the NSManagedObjectContext
 because of the lazy property you just added. Everything else is marked private. Why is this?
 
 The managed context is the only entry point required to access the rest of the stack. The persistent
 store coordinator is a public property on the NSManagedObjectContext. Similarly, both the managed object
 model and the array of persistent stores are public properties on the NSPersistentStoreCoordinator.
 */
class CoreDataStack {
	
	private let modelName: String
	
	lazy var managedContext: NSManagedObjectContext = {
		return self.storeContainer.viewContext
	}()
	
	init(modelName: String) {
		self.modelName = modelName
	}
	
	private lazy var storeContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: self.modelName)
		container.loadPersistentStores { _, error in
			if let error = error as NSError? {
				print("Unresolved error \(error), \(error.userInfo)")
			}
		}
		return container
	}()
	
	// This is a convenience method to save the stack's managed object context and handle any resulting errors.
	func saveContext() {
		guard managedContext.hasChanges else { return }
		
		do {
			try managedContext.save()
		} catch let error as NSError {
			print("Unresolved error \(error), \(error.userInfo)")
		}
	}
	
}
