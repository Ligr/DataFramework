//
//  DataDiffCalculator.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import IGListKit

private final class ListDiffableWrapper<T: Uniq & Equatable>: ListDiffable {

    let item: T

    init(item: T) {
        self.item = item
    }

    func diffIdentifier() -> NSObjectProtocol {
        return item.identifier as NSObjectProtocol
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ListDiffableWrapper<T> else {
            return false
        }
        return item == object.item
    }

}

struct DataUpdatesCalculator {

    static func calculate<T: Uniq & Equatable>(old: [T], new: [T]) -> [DataUpdate] {
        let diff = ListDiffPaths(fromSection: 0, toSection: 0, oldArray: old.map(ListDiffableWrapper.init), newArray: new.map(ListDiffableWrapper.init), option: .equality).forBatchUpdates()
        var updates = [DataUpdate]()
        updates += diff.inserts.map { DataUpdate.insert(at: $0) }
        updates += diff.deletes.map { DataUpdate.delete(at: $0) }
        updates += diff.updates.map { DataUpdate.update(at: $0) }
        updates += diff.moves.map { DataUpdate.move(from: $0.from, to: $0.to) }
        return updates
    }

}
