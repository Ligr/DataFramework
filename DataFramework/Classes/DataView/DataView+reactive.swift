//
//  DataView+reactive.swift
//  DataFramework
//
//  Created by Alex on 1/19/19.
//

import Foundation
import ReactiveSwift

public extension Reactive where Base: DataViewProtocol {

    var values: Property<[Base.ItemType]> {
        let items = base.updates.map { [weak base] _ -> [Base.ItemType] in
            return base?.values ?? []
        }
        return Property(initial: base.values, then: items)
    }

}
