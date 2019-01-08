//
//  DataSingleResult_FlatMap.swift
//  DataFramework
//
//  Created by Alex on 1/9/19.
//

import Foundation
import ReactiveSwift

internal final class DataSingleResult_FlatMap<U, T>: DataResult<T> {

    private var mappedResult: DataResult<T> = .empty
    private let innerResult: DataSingleResult<U>
    private var mappedResultDisposable: Disposable?
    private var innerRresultDisposable: Disposable?

    deinit {
        mappedResultDisposable?.dispose()
        innerRresultDisposable?.dispose()
    }

    init(inner: DataSingleResult<U>, transform: @escaping (U) -> DataResult<T>) {
        self.innerResult = inner
        super.init()

        innerRresultDisposable = inner.item.producer.skipNil().startWithValues { [weak self] value in
            self?.setNewResult(transform(value))
        }
    }

    override var count: Int { return mappedResult.count }
    override var numberOfSections: Int { return mappedResult.numberOfSections }
    override func numberOfItemsInSection(_ section: Int) -> Int { return mappedResult.numberOfItemsInSection(section) }

    override func reload() { mappedResult.reload() }
    override func loadMore() { mappedResult.loadMore() }

    override var values: [T] {
        return mappedResult.values
    }

    override subscript(_ index: Int) -> T {
        return mappedResult[index]
    }

    override subscript(_ index: IndexPath) -> T {
        return mappedResult[index]
    }

    private func setNewResult(_ result: DataResult<T>) {
        mappedResultDisposable?.dispose()
        let disposable = CompositeDisposable()
        mappedResultDisposable = disposable

        mappedResult = result

        disposable += _state <~ result.state
        disposable += result.updates.observe(updatesObserver)
    }

}
