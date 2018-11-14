//
//  Indexable.swift
//  DataFramework
//
//  Created by Aliaksandr on 11/14/18.
//

import Foundation

public protocol IndexSupportable {

    associatedtype IntexType

    var index: IntexType { get }

}
