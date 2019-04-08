//
//  DataSingleResult_FlatMap.swift
//  DataFramework
//
//  Created by Alex on 1/9/19.
//

import Foundation
import ReactiveSwift

extension DataSingleResult {

    public func flatMap<U>(_ transform: @escaping (T) -> DataResult<U>) -> DataResult<U> {
        return DataSingleResult_FlatMap(inner: self, transform: transform)
    }

}

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

        let disposable = CompositeDisposable()
        innerRresultDisposable = disposable
        disposable += inner.item.producer.skipNil().startWithValues { [weak self] value in
            self?.setNewResult(transform(value))
        }
        disposable += inner.state.producer.startWithValues { [weak self] _ in
            self?.refreshState()
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
        disposable += result.state.producer.startWithValues { [weak self] _ in
            self?.refreshState()
        }
        DispatchQueue.doOnMain {
            self.updatesObserver.send(value: [.all])
        }
        disposable += result.updates.observe(updatesObserver)
    }

    private func refreshState() {
        switch (innerResult.state.value, mappedResult.state.value) {
        case (.loading, _):
            _state.value = .loading
        case (.error(let error), _):
            _state.value = .error(error)
        case (.none, _):
            _state.value = .none
        case (_, .none), (_, .loading), (_, .idle), (_, .error):
            _state.value = mappedResult.state.value
        }
    }

}
