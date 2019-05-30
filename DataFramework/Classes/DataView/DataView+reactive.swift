//
//  DataView+reactive.swift
//  DataFramework
//
//  Created by Alex on 1/19/19.
//

import Foundation
import ReactiveSwift

extension DataViewProtocol {

    public var valuesStream: Property<[ItemType]> {
        let items = self.updates.map { [weak self] _ -> [ItemType] in
            return self?.values ?? []
        }
        return Property(initial: self.values, then: items)
    }

}
