//
//  DataResult_FetchedResultsController.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import CoreData
import ReactiveSwift

internal final class DataResult_FetchedResultsController<T: Uniq & Equatable & NSFetchRequestResult, E: Error>: DataResult<T> {

    private let data: NSFetchedResultsController<T>
    private let loadMoreData: ((page: Int, pageSize: Int)) -> SignalProducer<Void, E>
    private var page: Int = 1
    private let pageSize: Int
    private var finished = false

    init(data: NSFetchedResultsController<T>, pageSize: Int, loadMore: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<Void, E>) {
        self.data = data
        self.loadMoreData = loadMore
        self.pageSize = pageSize
        super.init()
        reload()
    }

    override func reload() {
        do {
            try data.performFetch()
        } catch let error {
            print(error)
        }
    }

    override func loadMore() {
        // do nothing
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
