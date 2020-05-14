import Foundation
import CoreData
import ReactiveSwift

internal final class DataResult_FetchedResultsController<T: NSManagedObject>: DataResult<T> {

    private let data: NSFetchedResultsController<T>
    private let delegate = FetchedResultsControllerDelegate()

    init(data: NSFetchedResultsController<T>) {
        self.data = data
        super.init()
        data.delegate = delegate
        updatesObserver <~ delegate.updates
        reload()
    }

    override func reload() {
        do {
            try data.performFetch()
        } catch let error {
            print("[DataResult] NSFetchedResultsController fetch failed: \(error)")
        }
    }

    override func loadMore() {

    }

    override var count: Int {
        return data.fetchedObjects?.count ?? 0
    }

    override var numberOfSections: Int {
        return data.sections?.count ?? 0
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        guard let dataSection = data.sections?[section] else {
            return 0
        }
        return dataSection.numberOfObjects
    }

    override var values: [T] {
        return data.fetchedObjects ?? []
    }

    override subscript(_ index: Int) -> T {
        guard let fetchedObjects = data.fetchedObjects else {
            fatalError("data is not fetched")
        }
        return fetchedObjects[index]
    }

    override subscript(_ index: IndexPath) -> T {
        guard let dataSection = data.sections?[index.section], let objects = dataSection.objects else {
            fatalError("section \(index.section) is not available or there is no objects")
        }
        guard let item = objects[index.item] as? T else {
            fatalError("object type is incorrect")
        }
        return item
    }

}

private final class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

    let updates: Signal<[DataUpdate], Never>
    private let updatesObserver: Signal<[DataUpdate], Never>.Observer

    private var _updates: [DataUpdate] = []

    override init() {
        (updates, updatesObserver) = Signal<[DataUpdate], Never>.pipe()
        super.init()
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _updates = []
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updatesObserver.send(value: _updates)
        _updates = []
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        // TODO: support sections changes
        _updates.append(.all)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            guard let indexPath = indexPath else {
                _updates.append(.all)
                return
            }
            _updates.append(.delete(at: indexPath))
        case .insert:
            guard let newIndexPath = newIndexPath else {
                _updates.append(.all)
                return
            }
            _updates.append(.insert(at: newIndexPath))
        case .update:
            guard let indexPath = indexPath else {
                _updates.append(.all)
                return
            }
            _updates.append(.update(at: indexPath))
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                _updates.append(.delete(at: indexPath))
                _updates.append(.insert(at: newIndexPath))
            } else {
                _updates.append(.all)
            }
        @unknown default:
            _updates.append(.all)
        }
    }

}
