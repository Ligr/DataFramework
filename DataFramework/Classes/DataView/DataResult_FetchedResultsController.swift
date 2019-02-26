//
//  DataResult_FetchedResultsController.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import CoreData
import ReactiveSwift

internal final class DataResult_FetchedResultsController<T: NSFetchRequestResult, V, E: Error>: DataResult<T> {

    private let data: NSFetchedResultsController<T>
    private let loadMoreData: ((page: Int, pageSize: Int)) -> SignalProducer<[V], E>
    private var page: Int = 1
    private let pageSize: Int
    private var finished = false
    private var dataDisposable: Disposable?
    private var paginationSupported: Bool {
        return pageSize < Int.max
    }

    deinit {
        dataDisposable?.dispose()
    }

    init(data: NSFetchedResultsController<T>, pageSize: Int, loadMore: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<[V], E>) {
        self.data = data
        self.loadMoreData = loadMore
        self.pageSize = pageSize
        super.init()
        reload()
    }

    override func reload() {
        dataDisposable?.dispose()
        finished = false
        _state.value = .none
        page = 1

        do {
            try data.performFetch()
        } catch let error {
            print(error)
        }

        loadMore()
    }

    override func loadMore() {
        guard finished == false && state.value.isError == false && state.value != .loading else {
            return
        }
        self._state.value = .loading
        let data = loadMoreData((page: page, pageSize: pageSize))
        dataDisposable?.dispose()
        dataDisposable = data.startWithResult { [unowned self] result in
            switch result {
            case .failure(let error):
                self._state.value = .error(error)
            case .success(let items):
                self.finished = items.count != self.pageSize
                if self.paginationSupported {
                    self.page += 1
                }
            }
        }
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
