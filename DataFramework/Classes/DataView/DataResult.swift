//
//  DataResult.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public protocol Uniq {
    var identifier: String { get }
}

public enum DataState: Equatable {
    case none
    case idle
    case loading
    case error(Error)

    public static func == (lhs: DataState, rhs: DataState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.idle, .idle),
             (.loading, .loading),
             (.error, .error):
            return true
        case (.none, _),
             (.idle, _),
             (.loading, _),
             (.error, _):
            return false
        }
    }

    var isError: Bool {
        switch self {
        case .idle, .loading, .none:
            return false
        case .error:
            return true
        }
    }

}

public enum DataUpdate: Equatable {
    case all
    case insert(at: IndexPath)
    case delete(at: IndexPath)
    case update(at: IndexPath)
    case move(from: IndexPath, to: IndexPath)
}

public protocol DataResultType {

    associatedtype ItemType

    var state: Property<DataState> { get }

    var updates: Signal<[DataUpdate], NoError> { get }
    var count: Int { get }

    var numberOfSections: Int { get }
    func numberOfItemsInSection(_ section: Int) -> Int

    func reload()
    func loadMore()
    func map<U>(_ mapAction: @escaping (ItemType) -> U) -> DataResult<U>

    var values: [ItemType] { get }
    subscript(_ index: Int) -> ItemType { get }
    subscript(_ index: IndexPath) -> ItemType { get }

}

public class DataResult<T>: DataResultType {

    public let state: Property<DataState>
    public let updates: Signal<[DataUpdate], NoError>
    public var count: Int { fatalError() }

    public var numberOfSections: Int { fatalError() }
    public func numberOfItemsInSection(_ section: Int) -> Int { fatalError() }

    public func reload() { fatalError() }
    public func loadMore() { fatalError() }

    public var values: [T] { fatalError() }
    public subscript(_ index: Int) -> T { fatalError() }
    public subscript(_ index: IndexPath) -> T { fatalError() }

    internal let _state: MutableProperty<DataState> = MutableProperty(.none)
    internal let updatesObserver: Signal<[DataUpdate], NoError>.Observer

    internal init() {
        let (updatesSignal, updatesObserver) = Signal<[DataUpdate], NoError>.pipe()
        self.updates = updatesSignal
        self.updatesObserver = updatesObserver
        state = Property(_state.skipRepeats())
    }

    public func map<U>(_ mapAction: @escaping (T) -> U) -> DataResult<U> {
        return DataResult_Map(map: mapAction, dataResult: self)
    }

    public static func create(data: [T]) -> DataResult<T> {
        return DataResult_Array(data: data)
    }

    public static func combine(data: [DataResult<T>]) -> DataResult<T> {
        return DataResult_Combine(results: data)
    }

    public static var empty: DataResult<T> {
        return DataResult_Array(data: [])
    }

}

public extension DataResult where T: Uniq & Equatable {

    static func create<E: Error>(data: SignalProducer<[T], E>) -> DataResult<T> {
        return DataResult_SignalProducer(data: data)
    }

    static func create<E: Error>(pageSize: Int, data: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>) -> DataResult<T> {
        return DataResult_SignalProducer(pageSize: pageSize, data: data)
    }

}
