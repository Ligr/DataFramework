//
//  DataDiffCalculator.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import DeepDiff

private final class ListDiffableWrapper<T: Uniq & Equatable>: DiffAware {

    let item: T

    init(item: T) {
        self.item = item
    }

    var diffId: Int {
        return item.identifier.hashValue
    }

    static func compareContent(_ a: ListDiffableWrapper<T>, _ b: ListDiffableWrapper<T>) -> Bool {
        return a.item == b.item
    }

}

struct DataUpdatesCalculator {

    static func calculate<T: Uniq & Equatable>(old: [T], new: [T]) -> [DataUpdate] {
        let wagnerFischerDiff: WagnerFischer<ListDiffableWrapper<T>> = WagnerFischer(reduceMove: false)

        let changes = wagnerFischerDiff.diff(old: old.map(ListDiffableWrapper.init), new: new.map(ListDiffableWrapper.init))
        var updates = [DataUpdate]()
        updates += changes.compactMap { $0.insert }.map { DataUpdate.insert(at: IndexPath(item: $0.index, section: 0)) }
        updates += changes.compactMap { $0.delete }.map { DataUpdate.delete(at: IndexPath(item: $0.index, section: 0)) }
        updates += changes.compactMap { $0.replace }.map { DataUpdate.update(at: IndexPath(item: $0.index, section: 0)) }
        updates += changes.compactMap { $0.move }.map { DataUpdate.move(from: IndexPath(item: $0.fromIndex, section: 0), to: IndexPath(item: $0.toIndex, section: 0)) }

        return updates
    }

}
