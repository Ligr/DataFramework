//
//  DataResult_Map.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import ReactiveSwift

internal class DataResult_Map<T, U>: DataResult<U> {

    private let map: (T) -> U
    private let dataResult: DataResult<T>
    private var disposable: ScopedDisposable<CompositeDisposable>?

    init(map: @escaping (T) -> U, dataResult: DataResult<T>) {
        self.map = map
        self.dataResult = dataResult
        super.init()

        let disposable = CompositeDisposable()
        self.disposable = ScopedDisposable(disposable)
        disposable += _state <~ dataResult.state
        disposable += dataResult.updates.observe(updatesObserver)
    }

    override var count: Int { return dataResult.count }
    override var numberOfSections: Int { return dataResult.numberOfSections }
    override func numberOfItemsInSection(_ section: Int) -> Int { return dataResult.numberOfItemsInSection(section) }

    override func reload() { dataResult.reload() }
    override func loadMore() { dataResult.loadMore() }

    override subscript(_ index: Int) -> U {
        return map(dataResult[index])
    }

    override subscript(_ index: IndexPath) -> U {
        return map(dataResult[index])
    }

}
