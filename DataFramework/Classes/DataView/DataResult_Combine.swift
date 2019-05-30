//
//  DataResult_Combine.swift
//  DataFramework
//
//  Created by Alex on 1/19/19.
//

import Foundation
import ReactiveSwift

internal final class DataResult_Combine<T>: DataResult<T> {

    private let results: [DataResult<T>]
    private var setupDisposable: Disposable?

    deinit {
        setupDisposable?.dispose()
    }

    init(results: [DataResult<T>]) {
        self.results = results
        super.init()

        setup()
    }

    override var count: Int {
        return results.reduce(0, { (result, data) -> Int in
            return result + data.count
        })
    }

    override var numberOfSections: Int {
        return results.reduce(0, { (result, data) -> Int in
            return result + data.numberOfSections
        })
    }

    override func numberOfItemsInSection(_ section: Int) -> Int {
        var sectionsOffset: Int = 0
        for result in results {
            if section - sectionsOffset < result.numberOfSections {
                return result.numberOfItemsInSection(section - sectionsOffset)
            } else {
                sectionsOffset += result.numberOfSections
            }
        }
        return 0
    }

    override func reload() {
        for result in results {
            result.reload()
        }
    }

    override func loadMore() {
        results.last?.loadMore()
    }

    override var values: [T] {
        return results.reduce([T](), { (result, data) -> [T] in
            return result + data.values
        })
    }

    override subscript(_ index: Int) -> T {
        var offset: Int = 0
        for result in results {
            if index - offset < result.count {
                return result[index - offset]
            } else {
                offset += result.count
            }
        }
        fatalError()
    }

    override subscript(_ index: IndexPath) -> T {
        var sectionsOffset: Int = 0
        for result in results {
            if index.section - sectionsOffset < result.numberOfSections {
                return result[IndexPath(item: index.item, section: index.section - sectionsOffset)]
            } else {
                sectionsOffset += result.numberOfSections
            }
        }
        fatalError()
    }

    private func setup() {
        let disposable = CompositeDisposable()
        setupDisposable = disposable
        
        disposable += setupState()
        disposable += setupUpdates()
    }

    private func setupState() -> Disposable? {
        let states = results.map { $0.state.producer }
        let stateProducer = SignalProducer.combineLatest(states).map { states -> DataState in
            for state in states {
                if case .error = state {
                    return state
                }
            }
            if states.contains(.loading) {
                return .loading
            }
            if states.contains(.none) {
                return .none
            }
            return .idle
        }
        return _state <~ stateProducer
    }

    private func setupUpdates() -> Disposable? {
        let updates = results.enumerated().map { [weak self] resultIndex, result -> Signal<[DataUpdate], Never> in
            return result.updates.map { [weak self] updates -> [DataUpdate] in
                guard let strongSelf = self else {
                    return []
                }
                let sectionOffset = resultIndex == 0 ? 0 : strongSelf.results[0..<resultIndex].reduce(0, { (result, data) -> Int in
                    return result + data.numberOfSections
                })
                return updates.map { update -> DataUpdate in
                    switch update {
                    case .all:
                        return .all
                    case .insert(at: let index):
                        return .insert(at: IndexPath(item: index.item, section: index.section + sectionOffset))
                    case .delete(at: let index):
                        return .delete(at: IndexPath(item: index.item, section: index.section + sectionOffset))
                    case .update(at: let index):
                        return .update(at: IndexPath(item: index.item, section: index.section + sectionOffset))
                    case .move(from: let fromIndex, to: let toIndex):
                        return .move(from: IndexPath(item: fromIndex.item, section: fromIndex.section + sectionOffset),
                                     to: IndexPath(item: toIndex.item, section: toIndex.section + sectionOffset))
                    }
                }
            }
        }
        return Signal.merge(updates).observe(updatesObserver)
    }

}
