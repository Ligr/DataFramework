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

    public subscript(_ index: Int) -> T { fatalError() }
    public subscript(_ index: IndexPath) -> T { fatalError() }

    fileprivate let _state: MutableProperty<DataState> = MutableProperty(.none)
    fileprivate let updatesObserver: Signal<[DataUpdate], NoError>.Observer

    fileprivate init() {
        let (updatesSignal, updatesObserver) = Signal<[DataUpdate], NoError>.pipe()
        self.updates = updatesSignal
        self.updatesObserver = updatesObserver
        state = Property(_state.skipRepeats())
    }

    public static func create(data: [T]) -> DataResult<T> {
        return DataResult_Array(data: data)
    }

    public func map<U>(_ mapAction: @escaping (T) -> U) -> DataResult<U> {
        return DataResult_Map(map: mapAction, dataResult: self)
    }

    public static var empty: DataResult<T> {
        return create(data: [])
    }

}

public extension DataResult where T: Uniq & Equatable {

    static func create<E: Error>(data: SignalProducer<[T], E>) -> DataResult<T> {
        return DataResult_SignalProducer(data: data)
    }

    static func create<E: Error>(pageSize: Int, data: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>) -> DataResult<T> {
        return DataResult_PagingSignalProducer(pageSize: pageSize, data: data)
    }

}

private class DataResult_Map<T, U>: DataResult<U> {

    private let map: (T) -> U
    private let dataResult: DataResult<T>
    private var disposable: ScopedDisposable<CompositeDisposable>?

    init(map: @escaping (T) -> U, dataResult: DataResult<T>) {
        self.map = map
        self.dataResult = dataResult
        super.init()

        let disposable = CompositeDisposable()
        self.disposable = ScopedDisposable(disposable)
        disposable += _state <~ dataResult.state
        disposable += dataResult.updates.observe(updatesObserver)
    }

    override var count: Int { return dataResult.count }
    override var numberOfSections: Int { return dataResult.numberOfSections }
    override func numberOfItemsInSection(_ section: Int) -> Int { return dataResult.numberOfItemsInSection(section) }

    override func reload() { dataResult.reload() }
    override func loadMore() { dataResult.loadMore() }

    override subscript(_ index: Int) -> U {
        return map(dataResult[index])
    }

    override subscript(_ index: IndexPath) -> U {
        return map(dataResult[index])
    }

}

private final class DataResult_Array<T>: DataResult<T> {

    private let data: [T]

    init(data: [T]) {
        self.data = data
        super.init()

        self._state.value = .idle
        updatesObserver.send(value: [.all])
    }

    override var count: Int {
        return data.count
    }

    override var numberOfSections: Int {
        return 1
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        return data.count
    }

    override func reload() {
        // do nothing
    }

    override func loadMore() {
        // do nothing
    }

    override subscript(_ index: Int) -> T {
        return data[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return data[index.item]
    }

}

private final class DataResult_SignalProducer<T: Uniq & Equatable, E: Error>: DataResult<T> {

    private var data: [T] = []
    private var dataDisposable: Disposable?
    private let dataProducer: SignalProducer<[T], E>

    init(data: SignalProducer<[T], E>) {
        self.dataProducer = data
        super.init()

        reload()
    }

    deinit {
        dataDisposable?.dispose()
    }

    override var count: Int {
        return data.count
    }

    override var numberOfSections: Int {
        return 1
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        return data.count
    }

    override func reload() {
        dataDisposable?.dispose()
        self._state.value = .loading
        if data.isEmpty == false {
            data = []
            updatesObserver.send(value: [.all])
        }
        dataDisposable = dataProducer.startWithResult { [unowned self] result in
            switch result {
            case .failure(let error):
                self._state.value = .error(error)
            case .success(let items):
                let updates = DataUpdatesCalculator.calculate(old: self.data, new: items)
                self.data = items
                self._state.value = .idle
                if updates.count > 0 {
                    self.updatesObserver.send(value: updates)
                }
            }
        }
    }

    override func loadMore() {
        // do nothing
    }

    override subscript(_ index: Int) -> T {
        return data[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return data[index.item]
    }

}

private final class DataResult_PagingSignalProducer<T: Uniq & Equatable, E: Error>: DataResult<T> {

    private var data: [T] = []
    private var dataDisposable: Disposable?
    private var loadData: ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>
    private var page: Int = 1
    private let pageSize: Int
    private var finished = false

    init(pageSize: Int, data: @escaping ((page: Int, pageSize: Int)) -> SignalProducer<[T], E>) {
        self.loadData = data
        self.pageSize = pageSize
        super.init()

        reload()
    }

    override func reload() {
        dataDisposable?.dispose()
        if data.isEmpty == false {
            data = []
            updatesObserver.send(value: [.all])
        }
        finished = false
        _state.value = .none
        page = 1
        
        loadMore()
    }

    override func loadMore() {
        guard finished == false && state.value.isError == false && state.value != .loading else {
            return
        }
        self._state.value = .loading
        let data = loadData((page: page, pageSize: pageSize))
        dataDisposable?.dispose()
        dataDisposable = data.startWithResult { [unowned self] result in
            switch result {
            case .failure(let error):
                self._state.value = .error(error)
            case .success(let items):
                self.page += 1
                self.finished = items.count != self.pageSize
                let newItems = self.data + items
                let updates = DataUpdatesCalculator.calculate(old: self.data, new: newItems)
                self.data = newItems
                self._state.value = .idle
                if updates.count > 0 {
                    self.updatesObserver.send(value: updates)
                }
            }
        }
    }

    deinit {
        dataDisposable?.dispose()
    }

    override var count: Int {
        return data.count
    }

    override var numberOfSections: Int {
        return 1
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        return data.count
    }

    override subscript(_ index: Int) -> T {
        return data[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return data[index.item]
    }

}
