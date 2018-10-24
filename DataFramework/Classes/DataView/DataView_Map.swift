//
//  DataView_Map.swift
//  DataFramework
//
//  Created by Aliaksandr on 7/16/18.
//

import Foundation
import ReactiveSwift
import Result

internal class DataView_Map<T, U>: DataView<U> {

    private let map: (T) -> U
    private let dataView: DataView<T>

    init(map: @escaping (T) -> U, dataView: DataView<T>) {
        self.map = map
        self.dataView = dataView
    }

    override var state: Property<DataState> { return dataView.state }
    override var updates: Signal<[DataUpdate], NoError> { return dataView.updates }
    override var count: Int { return dataView.count }
    override var numberOfSections: Int { return dataView.numberOfSections }
    override func numberOfItemsInSection(_ section: Int) -> Int { return dataView.numberOfItemsInSection(section) }

    override func loadMore() { dataView.loadMore() }

    override var values: [U] {
        return dataView.values.map(map)
    }

    override subscript(_ index: Int) -> U {
        return map(dataView[index])
    }

    override subscript(_ index: IndexPath) -> U {
        return map(dataView[index])
    }

}
