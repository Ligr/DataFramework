import CoreData
import Foundation

public final class CoreDataStack {

    // MARK: - Properties
    // MARK: Public

    public var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: Private

    private let persistentContainer: NSPersistentContainer
    private let modelName: String

    // MARK: - Initializers

    public init(modelName: String = "DataModel") {
        self.modelName = modelName
        self.persistentContainer = Self.persistentContainer(modelName)
    }

    // MARK: - API

    public func performInBackground(_ action: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { [weak self] context in
            action(context)
            self?.saveContext(context)
        }
    }
}

private extension CoreDataStack {

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

    private static func persistentStoreURL(_ name: String) -> URL {
        let storeName = "\(name).sqlite"
        let fileManager = FileManager.default
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectoryURL.appendingPathComponent(storeName)
    }

    private static func managedObjectModel(_ name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError()
        }
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        return managedObjectModel!
    }

    private static func persistentContainer(_ name: String) -> NSPersistentContainer {
        let storeDescription = NSPersistentStoreDescription(url: persistentStoreURL(name))
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldMigrateStoreAutomatically = true

        let container = NSPersistentContainer(name: name, managedObjectModel: Self.managedObjectModel(name))
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }
}
