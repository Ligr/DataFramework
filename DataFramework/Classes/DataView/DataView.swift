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

public protocol DataViewProtocol {

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
    func map<U>(_ mapAction: @escaping (ItemType) -> U) -> DataView<U>

    var selectedItems: Property<[IndexPath]> { get }
    var allowsMultipleSelection: Bool { get }
    func selectItem(at index: IndexPath)
    func selectItems(at indexes: [IndexPath])
    func deselectItem(at index: IndexPath)
    func resetSelection()

    subscript(_ index: Int) -> ItemType { get }
    subscript(_ index: IndexPath) -> ItemType { get }

}

public class DataView<T>: DataViewProtocol {

    public var state: Property<DataState> { fatalError() }
    public private(set) lazy var isEmptyAndLoading: Property<Bool> = {
        return state.map { [weak self] in
            $0 == .loading && self?.count == 0
        }.skipRepeats()
    }()
    public private(set) lazy var isEmpty: Property<Bool> = {
        let isEmpty = updates.map { [weak self] _ -> Bool in
            guard let strongSelf = self else {
                return true
            }
            return self?.count == 0
        }
        return Property(initial: count == 0, then: isEmpty)
    }()
    public private(set) lazy var isLoading: Property<Bool> = {
        return state.map { $0 == .loading }
    }()
    public var updates: Signal<[DataUpdate], NoError> { fatalError() }
    public var count: Int { fatalError() }

    public var numberOfSections: Int { fatalError() }
    public func numberOfItemsInSection(_ section: Int) -> Int { fatalError() }

    public func loadMore() { fatalError() }

    public subscript(_ index: Int) -> T { fatalError() }
    public subscript(_ index: IndexPath) -> T { fatalError() }

    public func map<U>(_ mapAction: @escaping (T) -> U) -> DataView<U> {
        return DataView_Map(map: mapAction, dataView: self)
    }

    public private(set) lazy var selectedItems: Property<[IndexPath]> = {
        updates.take(duringLifetimeOf: self).observeValues { [weak self] updates in
            self?.resetSelection() // TODO: update selection based on new position of objects
        }
        return Property(_selectedItems)
    }()
    private let _selectedItems: MutableProperty<[IndexPath]> = MutableProperty([])
    public var allowsMultipleSelection: Bool = false

    public func selectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == false else {
            return
        }
        if allowsMultipleSelection {
            _selectedItems.value.append(index)
        } else {
            _selectedItems.value = [index]
        }
    }

    public func selectItems(at indexes: [IndexPath]) {
        let existingIndexes = _selectedItems.value
        let newIndexes = indexes.filter {
            existingIndexes.contains($0) == false
        }
        guard newIndexes.count > 0 else {
            return
        }
        guard allowsMultipleSelection || newIndexes.count == 1 else {
            return
        }
        if allowsMultipleSelection {
            _selectedItems.value.append(contentsOf: newIndexes)
        } else {
            _selectedItems.value = newIndexes
        }
    }

    public func deselectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == true else {
            return
        }
        _selectedItems.value.remove(index)
    }

    public func resetSelection() {
        guard _selectedItems.value.count > 0 else {
            return
        }
        _selectedItems.value = []
    }

    public static func create(data: DataResult<T>) -> DataView<T> {
        return DataView_Result(result: data)
    }

    public static var empty: DataView<T> {
        return create(data: .empty)
    }

}
