//
//  DataSingleResult.swift
//  D99
//
//  Created by Alex on 5/14/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

protocol DataSingleResultType {

    associatedtype ItemType

    var item: Property<ItemType?> { get }
    var state: Property<DataState> { get }
    var isLoading: Property<Bool> { get }

}

class DataSingleResult<T>: DataSingleResultType {

    let item: Property<T?>
    let state: Property<DataState>

    private(set) lazy var isLoading: Property<Bool> = {
        return state.map { $0 == .loading }
    }()

    fileprivate let _item: MutableProperty<T?> = MutableProperty(nil)
    fileprivate let _state: MutableProperty<DataState> = MutableProperty(.none)

    fileprivate init() {
        item = Property(_item)
        state = Property(_state)
    }

    static func create<E: Error>(data: SignalProducer<T, E>) -> DataSingleResult<T> {
        return DataSingleResult_SignalProducer(data: data)
    }

}

private class DataSingleResult_SignalProducer<T, E: Error>: DataSingleResult<T> {

    private var dataDisposable: Disposable?

    init(data: SignalProducer<T, E>) {
        super.init()
        self._state.value = .loading
        dataDisposable = data.startWithResult { [weak self] result in
            switch result {
            case .failure(let error):
                self?._state.value = .error(error)
            case .success(let value):
                self?._item.value = value
                self?._state.value = .idle
            }
        }
    }

    deinit {
        dataDisposable?.dispose()
    }

}
