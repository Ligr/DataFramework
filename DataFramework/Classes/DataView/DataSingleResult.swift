//
//  DataSingleResult.swift
//  DataFramework
//
//  Created by Alex on 5/14/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import ReactiveSwift

public protocol DataSingleResultType {

    associatedtype ItemType

    var item: Property<ItemType?> { get }
    var state: Property<DataState> { get }
    var isLoading: Property<Bool> { get }

    func reload()
    func flatMap<U>(_ transform: @escaping (ItemType) -> DataResult<U>) -> DataResult<U>

}

public class DataSingleResult<T>: DataSingleResultType {

    public let item: Property<T?>
    public let state: Property<DataState>

    public private(set) lazy var isLoading: Property<Bool> = {
        return state.map { $0 == .loading }
    }()

    fileprivate let _item: MutableProperty<T?>
    fileprivate let _state: MutableProperty<DataState> = MutableProperty(.none)

    fileprivate init(initial: T? = nil) {
        _item = MutableProperty(initial)
        item = Property(_item)
        state = Property(_state)
    }

    public func reload() { }

    public static func create<E: Error>(initial: T? = nil, data: SignalProducer<T, E>) -> DataSingleResult<T> {
        return DataSingleResult_SignalProducer(initial: initial, data: data)
    }

    public static func create(constant: T?) -> DataSingleResult<T> {
        let result = DataSingleResult(initial: constant)
        result._state.value = .idle
        return result
    }

    public static var empty: DataSingleResult<T> {
        return self.create(constant: nil)
    }

}

private final class DataSingleResult_SignalProducer<T, E: Error>: DataSingleResult<T> {

    private var dataDisposable: Disposable?
    private let data: SignalProducer<T, E>

    init(initial: T? = nil, data: SignalProducer<T, E>) {
        self.data = data
        super.init(initial: initial)
        reload()
    }

    deinit {
        dataDisposable?.dispose()
    }

    override func reload() {
        guard _state.value != .loading else {
            return
        }
        _state.value = .loading
        dataDisposable = data.startWithResult { [weak self] result in
            DispatchQueue.doOnMain {
                switch result {
                case .failure(let error):
                    self?._state.value = .error(error)
                    self?._item.value = nil
                case .success(let value):
                    self?._state.value = .idle
                    self?._item.value = value
                }
            }
        }
    }

}
