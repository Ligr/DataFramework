//
//  DataView_Cache.swift
//  DataFramework
//
//  Created by Aliaksandr on 2/26/19.
//

import Foundation
import ReactiveSwift

extension DataView {

    public var cached: DataView {
        return DataView_Cache(dataView: self)
    }

}

final class DataView_Cache<T>: DataView<T> {

    private let innerDataView: DataView<T>
    private var cache: [IndexPath: T] = [:]

    init(dataView: DataView<T>) {
        self.innerDataView = dataView
        super.init()
        setup()
    }

    override var state: Property<DataState> { return innerDataView.state }
    override var updates: Signal<[DataUpdate], Never> { return innerDataView.updates }
    override var count: Int { return innerDataView.count }
    override var numberOfSections: Int { return innerDataView.numberOfSections }
    override func numberOfItemsInSection(_ section: Int) -> Int { return innerDataView.numberOfItemsInSection(section) }

    override func loadMore() { innerDataView.loadMore() }

    override var values: [T] { return innerDataView.values }

    override subscript(_ index: Int) -> T {
        let index = IndexPath(item: index, section: 0)
        return self[index]
    }

    override subscript(_ index: IndexPath) -> T {
        guard let cachedItem = cache[index] else {
            let item = innerDataView[index]
            cache[index] = item
            return item
        }
        return cachedItem
    }

}

private extension DataView_Cache {

    func setup() {
        innerDataView.updates.take(duringLifetimeOf: self).observeValues { [unowned self] updates in
            func moveLeft(in section: Int, startIndex: Int, endIndex: Int? = nil) {
                let affectedItems = self.cache.filter {
                    $0.key.section == section && $0.key.item >= startIndex && (endIndex == nil || $0.key.item <= endIndex!)
                }.sorted { itm0, itm1 in
                    itm0.key.item < itm1.key.item
                }
                affectedItems.forEach { item in
                    let newIndex = IndexPath(item: item.key.item - 1, section: item.key.section)
                    self.cache[newIndex] = item.value
                    self.cache.removeValue(forKey: item.key)
                }
            }
            func moveRight(in section: Int, startIndex: Int, endIndex: Int? = nil) {
                let affectedItems = self.cache.filter {
                    $0.key.section == section && $0.key.item >= startIndex && (endIndex == nil || $0.key.item <= endIndex!)
                }.sorted { itm0, itm1 in
                    itm0.key.item > itm1.key.item
                }
                affectedItems.forEach { item in
                    let newIndex = IndexPath(item: item.key.item + 1, section: item.key.section)
                    self.cache[newIndex] = item.value
                    self.cache.removeValue(forKey: item.key)
                }
            }

            for update in updates {
                switch update {
                case .all:
                    self.cache.removeAll()
                case .delete(at: let index):
                    self.cache.removeValue(forKey: index)
                    moveLeft(in: index.section, startIndex: index.item + 1)
                case .insert(at: let index):
                    moveRight(in: index.section, startIndex: index.item)
                case .update(at: let index):
                    self.cache.removeValue(forKey: index)
                case .move(from: let fromIndex, to: let toIndex):
                    if let item = self.cache[fromIndex], fromIndex.item != toIndex.item {
                        self.cache.removeValue(forKey: fromIndex)
                        if fromIndex.section != toIndex.section {
                            moveLeft(in: fromIndex.section, startIndex: fromIndex.item + 1)
                            moveRight(in: toIndex.section, startIndex: toIndex.item)
                        } else {
                            if fromIndex.item < toIndex.item {
                                moveLeft(in: fromIndex.section, startIndex: fromIndex.item + 1, endIndex: toIndex.item)
                            } else {
                                moveRight(in: fromIndex.section, startIndex: toIndex.item, endIndex: fromIndex.item - 1)
                            }
                        }
                        self.cache[toIndex] = item
                    }
                }
            }
        }
    }

}
