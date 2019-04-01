//
//  DataResult_PagingSignalProducer.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import ReactiveSwift
import Result

internal final class DataResult_SignalProducer<T: Uniq & Equatable, E: Error>: DataResult<T> {

    private var data: [T] = []
    private var dataDisposable: Disposable?
    private let loadData: ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>
    private var page: Int = 1
    private let pageSize: Int
    private var finished = false
    private var paginationSupported: Bool {
        return pageSize < Int.max
    }

    init(pageSize: Int, data: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>) {
        self.loadData = data
        self.pageSize = pageSize
        super.init()

        reload()
    }

    convenience init(data: SignalProducer<[T], E>) {
        self.init(pageSize: Int.max, data: { _ in return data })
    }

    override func reload() {
        dataDisposable?.dispose()
        finished = false
        _state.value = .none
        page = 1

        loadMore()
    }

    override func loadMore() {
        guard finished == false && state.value.isError == false && state.value != .loading else {
            return
        }
        self._state.value = .loading
        let data = loadData((page: page, pageSize: pageSize))
        dataDisposable?.dispose()
        dataDisposable = data.startWithResult { [unowned self] result in
            switch result {
            case .failure(let error):
                self._state.value = .error(error)
            case .success(let items):
                self.finished = items.count != self.pageSize
                let newItems: [T]
                if self.paginationSupported {
                    // if we loaded first page then we have to ignore old data (it may be not empty because user initiated reload)
                    if self.page == 1 {
                        newItems = items
                    } else {
                        newItems = self.data + items
                    }
                    self.page += 1
                } else {
                    newItems = items
                }
                let updates = DataUpdatesCalculator.calculate(old: self.data, new: newItems)

                // send updates on main thread so that data will not be changed in bg while it is processed on main thread
                DispatchQueue.doOnMain { [weak self] in
                    // notify about state change only AFTER new state was applied
                    // WARNING! however this fix does not work with skeleton view because when dataSources are switched they already have NEW items count but then UPDATES arrive ;(
                    self?.data = newItems
                    self?._state.value = .idle
                    if updates.count > 0 {
                        self?.updatesObserver.send(value: updates)
                    }
                }
            }
        }
    }

    deinit {
        dataDisposable?.dispose()
    }

    override var count: Int {
        return data.count
    }

    override var numberOfSections: Int {
        return 1
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        return data.count
    }

    override var values: [T] {
        return data
    }

    override subscript(_ index: Int) -> T {
        return data[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return data[index.item]
    }

}
