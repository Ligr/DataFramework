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

public protocol DataViewProtocol: class {

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
    func setSelectedItems(indexes: [IndexPath])
    func deselectItem(at index: IndexPath)
    func resetSelection()

    var values: [ItemType] { get }
    subscript(_ index: Int) -> ItemType { get }
    subscript(_ index: IndexPath) -> ItemType { get }

}

public class DataView<T>: DataViewProtocol {

    public var state: Property<DataState> { fatalError() }
    public final private(set) lazy var isEmptyAndLoading: Property<Bool> = {
        return state.map { [weak self] in
            $0 == .loading && self?.count == 0
        }.skipRepeats()
    }()
    public final private(set) lazy var isEmpty: Property<Bool> = {
        let isEmpty = updates.map { [weak self] _ -> Bool in
            guard let strongSelf = self else {
                return true
            }
            return self?.count == 0
        }
        return Property(initial: count == 0, then: isEmpty)
    }()
    public final private(set) lazy var isLoading: Property<Bool> = {
        return state.map { $0 == .loading }
    }()
    public var updates: Signal<[DataUpdate], NoError> { fatalError() }
    public var count: Int { fatalError() }

    public var numberOfSections: Int { fatalError() }
    public func numberOfItemsInSection(_ section: Int) -> Int { fatalError() }

    public func loadMore() { fatalError() }

    public var values: [T] { fatalError() }
    public subscript(_ index: Int) -> T { fatalError() }
    public subscript(_ index: IndexPath) -> T { fatalError() }

    public final func map<U>(_ mapAction: @escaping (T) -> U) -> DataView<U> {
        return DataView_Map(map: mapAction, dataView: self)
    }

    internal init() {
        updates.take(duringLifetimeOf: self).observeValues { [weak self] updates in
            self?.syncSelectionsWithUpdates(updates)
        }
    }

    public final private(set) lazy var selectedItems: Property<[IndexPath]> = {
        return Property(_selectedItems)
    }()
    private final let _selectedItems: MutableProperty<[IndexPath]> = MutableProperty([])

    public final var allowsMultipleSelection: Bool = false

    public final func selectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == false else {
            return
        }
        if allowsMultipleSelection {
            _selectedItems.value.append(index)
        } else {
            _selectedItems.value = [index]
        }
    }

    public final func setSelectedItems(indexes: [IndexPath]) {
        guard allowsMultipleSelection || indexes.count == 1 else {
            return
        }
        _selectedItems.value = indexes
    }

    public final func deselectItem(at index: IndexPath) {
        guard _selectedItems.value.contains(index) == true else {
            return
        }
        _selectedItems.value.remove(index)
    }

    public final func resetSelection() {
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

private extension DataView {

    func syncSelectionsWithUpdates(_ updates: [DataUpdate]) {
        let oldSelectedItems = _selectedItems.value
        guard oldSelectedItems.count > 0 else {
            return
        }
        var newSelectedItems = _selectedItems.value

        let handleDelete: (IndexPath) -> Void = { index in
            newSelectedItems.remove(index)
            for selection in oldSelectedItems where selection.section == index.section {
                if selection.item > index.item {
                    newSelectedItems.remove(selection)
                    newSelectedItems.append(IndexPath(item: selection.item - 1, section: selection.section))
                }
            }
        }
        let handleInsert: (IndexPath) -> Void = { index in
            for selection in oldSelectedItems where selection.section == index.section {
                if selection.item >= index.item {
                    newSelectedItems.remove(selection)
                    newSelectedItems.append(IndexPath(item: selection.item + 1, section: selection.section))
                }
            }
        }
        for update in updates {
            switch update {
            case .all, .update:
                break
            case .delete(at: let index):
                handleDelete(index)
            case .insert(at: let index):
                handleInsert(index)
            case .move(from: let fromIndex, to: let toIndex):
                handleDelete(fromIndex)
                handleInsert(toIndex)
            }
        }

        _selectedItems.value = newSelectedItems
    }

}
