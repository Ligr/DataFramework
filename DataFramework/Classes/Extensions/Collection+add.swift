//
//  Collection+add.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

public func += <T> (lhs: inout Array<T>, rhs: T) {
    lhs.append(rhs)
}

public extension Array where Element: Equatable {

    @discardableResult
    mutating func remove(_ element: Element) -> Element? {
        guard let index = self.firstIndex(of: element) else {
            return nil
        }
        return self.remove(at: index)
    }

}
