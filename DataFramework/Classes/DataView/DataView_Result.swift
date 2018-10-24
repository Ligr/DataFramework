//
//  DataView_Result.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import ReactiveSwift
import Result

internal class DataView_Result<T>: DataView<T> {

    private let result: DataResult<T>

    init(result: DataResult<T>) {
        self.result = result
    }

    override var state: Property<DataState> {
        return result.state
    }

    override var updates: Signal<[DataUpdate], NoError> {
        return result.updates
    }

    override var count: Int {
        return result.count
    }

    override var numberOfSections: Int {
        return result.numberOfSections
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        return result.numberOfItemsInSection(section)
    }

    override func loadMore() {
        result.loadMore()
    }

    override var values: [T] {
        return result.values
    }

    override subscript(_ index: Int) -> T {
        return result[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return result[index]
    }

}
