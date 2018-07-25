//
//  CoreDataStack.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/20/18.
//

import Foundation
import CoreData

final class CoreDataStack {

    private let modelName: String

    public private(set) lazy var mainContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.parent = self.privateContext
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()

    private lazy var privateContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()

    private lazy var managedObjectModel: NSManagedObjectModel? = {
        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd") else {
            return nil
        }
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        return managedObjectModel
    }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let managedObjectModel = self.managedObjectModel else {
            return nil
        }
        let persistentStoreURL = self.persistentStoreURL
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: options)

        } catch {
            let addPersistentStoreError = error as NSError
            print("Unable to Add Persistent Store\n\(addPersistentStoreError.localizedDescription)")
        }

        return persistentStoreCoordinator
    }()

    init(modelName: String = "DataModel") {
        self.modelName = modelName
    }

    public func save() {
        mainContext.performAndWait {
            do {
                if self.mainContext.hasChanges {
                    try self.mainContext.save()
                }
            } catch {
                let saveError = error as NSError
                print("Unable to Save Changes of Main Managed Object Context\n\(saveError), \(saveError.localizedDescription)")
            }
        }

        privateContext.perform {
            do {
                if self.privateContext.hasChanges {
                    try self.privateContext.save()
                }
            } catch {
                let saveError = error as NSError
                print("Unable to Save Changes of Private Managed Object Context\n\(saveError), \(saveError.localizedDescription)")
            }
        }
    }

}

private extension CoreDataStack {

    private var persistentStoreURL: URL {
        let storeName = "\(modelName).sqlite"
        let fileManager = FileManager.default
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectoryURL.appendingPathComponent(storeName)
    }

}
