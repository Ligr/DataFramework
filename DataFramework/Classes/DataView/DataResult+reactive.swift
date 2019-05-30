//
//  DataResult+reactive.swift
//  DataFramework
//
//  Created by Aliaksandr on 1/24/19.
//

import Foundation
import ReactiveSwift

extension DataResultType {

    public var valuesStream: Property<[ItemType]> {
        let items = self.updates.map { [weak self] _ -> [ItemType] in
            return self?.values ?? []
        }
        return Property(initial: self.values, then: items)
    }

}
