//
//  DataList.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import ReactiveSwift
import ReactiveCocoa
import Result

protocol DataViewProtocol {

    associatedtype ItemType

    var state: Property<DataState> { get }
    var isEmptyAndLoading: Property<Bool> { get }
    var isEmpty: Property<Bool> { get }
    var isLoading: Property<Bool> { get }
    var updates: Signal<[DataUpdate], NoError> { get }
    var count: Int { get }

    var numberOfSections: Int { get }
    func numberOfItemsInSection(_ section: Int) -> Int

    func loadMore()

    var selectedItems: Property<[IndexPath]> { get }
    var allowsMultipleSelection: Bool { get }
    func selectItem(at index: IndexPath)
    func deselectItem(at index: IndexPath)
    func resetSelection()

    subscript(_ index: Int) -> ItemType { get }
    subscript(_ index: IndexPath) -> ItemType { get }

}

class DataView<T>: DataViewProtocol {

    var state: Property<DataState> { fatalError() }
    private(set) lazy var isEmptyAndLoading: Property<Bool> = {
        return state.map { [weak self] in
            $0 == .loading && self?.count == 0
        }.skipRepeats()
    }()
    private(set) lazy var isEmpty: Property<Bool> = {
        let isEmpty = updates.map { [weak self] _ -> Bool in
            guard let strongSelf = self else {
                return true
            }
            return self?.count == 0
        }
        return Property(initial: count == 0, then: isEmpty)
    }()
    private(set) lazy var isLoading: Property<Bool> = {
        return state.map { $0 == .loading }
    }()
    var updates: Signal<[DataUpdate], NoError> { fatalError() }
    var count: Int { fatalError() }

    var numberOfSections: Int { fatalError() }
    func numberOfItemsInSection(_ section: Int) -> Int { fatalError() }

    func loadMore() { fatalError() }

    subscript(_ index: Int) -> T { fatalError() }
    subscript(_ index: IndexPath) -> T { fatalError() }

    func map<U>(_ mapAction: @escaping (T) -> U) -> DataView<U> {
        return DataView_Map(map: mapAction, dataView: self)
    }

    private(set) lazy var selectedItems: Property<[IndexPath]> = {
        updates.take(duringLifetimeOf: self).observeValues { [weak self] updates in
            self?.resetSelection() // TODO: update selection based on new position of objects
        }
        return Property(_selectedItems)
    }()
    private let _selectedItems: MutableProperty<[IndexPath]> = MutableProperty([])
    var allowsMultipleSelection: Bool = false

    func selectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == false else {
            return
        }
        if allowsMultipleSelection {
            _selectedItems.value.append(index)
        } else {
            _selectedItems.value = [index]
        }
    }

    func deselectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == true else {
            return
        }
        _selectedItems.value.remove(index)
    }

    func resetSelection() {
        guard _selectedItems.value.count > 0 else {
            return
        }
        _selectedItems.value = []
    }

    static func create(data: DataResult<T>) -> DataView<T> {
        return DataView_Result(result: data)
    }

}

private class DataView_Map<T, U>: DataView<U> {

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

    override subscript(_ index: Int) -> U {
        return map(dataView[index])
    }

    override subscript(_ index: IndexPath) -> U {
        return map(dataView[index])
    }

}

private class DataView_Result<T>: DataView<T> {

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

    override subscript(_ index: Int) -> T {
        return result[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return result[index]
    }

}
