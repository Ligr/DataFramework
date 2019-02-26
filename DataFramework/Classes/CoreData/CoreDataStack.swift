//
//  CoreDataStack.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/20/18.
//

import Foundation
import CoreData

public final class CoreDataStack {

    private let modelName: String

    public private(set) lazy var mainContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
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

    public init(modelName: String = "DataModel") {
        self.modelName = modelName
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChangeNotification(_:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func save() {
        mainContext.performAndWait {
            self.saveContext(self.mainContext)
        }
    }

    public func performInBackground(_ action: @escaping (NSManagedObjectContext) -> Void) {
        privateContext.perform { [weak self] in
            guard let context = self?.privateContext else {
                return
            }
            action(context)
            self?.saveContext(context)
        }
    }

    public func performInBackgroundAndWait(_ action: @escaping (NSManagedObjectContext) -> Void) {
        privateContext.performAndWait { [weak self] in
            guard let context = self?.privateContext else {
                return
            }
            action(context)
            self?.saveContext(context)
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

    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            let saveError = error as NSError
            print("Unable to Save Changes of Managed Object Context\n\(saveError), \(saveError.localizedDescription)")
        }
    }

    @objc private func managedObjectContextObjectsDidChangeNotification(_ notification: Notification) {
        // according to Apple docs (https://developer.apple.com/library/archive/releasenotes/General/WhatNewCoreData2016/ReleaseNotes.html)
        // > NSFetchedResultsController now correctly merges changes from other context for objects it hasn’t seen in its own context
        // so this hack may be not needed any more
        guard let sender = notification.object as? NSManagedObjectContext else {
            return
        }
        if sender === privateContext {
            if let updates = notification.userInfo?[NSUpdatedObjectsKey] as? [NSManagedObject] {
                for object in updates {
                    _ = try? mainContext.existingObject(with: object.objectID)
                }
            }
            mainContext.mergeChanges(fromContextDidSave: notification)
        } else if sender === mainContext {
            privateContext.mergeChanges(fromContextDidSave: notification)
        }
    }

}
