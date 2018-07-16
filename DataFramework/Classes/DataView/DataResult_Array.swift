//
//  DataResult_Array.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation

internal final class DataResult_Array<T>: DataResult<T> {

    private let data: [T]

    init(data: [T]) {
        self.data = data
        super.init()

        self._state.value = .idle
        updatesObserver.send(value: [.all])
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

    override func reload() {
        // do nothing
    }

    override func loadMore() {
        // do nothing
    }

    override subscript(_ index: Int) -> T {
        return data[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return data[index.item]
    }

}
