//
//  SignalProducerCachedFactory.swift
//  DataFramework
//
//  Created by Alex on 2/14/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift

internal final class SignalProducerCachedFactory<Filter: DataFilterProtocol, Output, E: Error> {

    private let factory: (Filter) -> SignalProducer<Output, E>
    private var cache: [String: SignalProducer<Output, E>] = [:]
    private let queue = DispatchQueue(label: "SignalProducerCachedFactory")

    init(factory: @escaping (Filter) -> SignalProducer<Output, E>) {
        self.factory = factory
    }

    func producer(for filter: Filter) -> SignalProducer<Output, E> {
        return SignalProducer<Output, E> { [weak self] observer, lifetime in
            guard let strongSelf = self else {
                observer.sendInterrupted()
                return
            }
            let disposable = strongSelf.getOrCreateProducer(for: filter).start(observer)
            lifetime += disposable
        }
    }

}

private extension SignalProducerCachedFactory {

    func getOrCreateProducer(for filter: Filter) -> SignalProducer<Output, E> {
        var result: SignalProducer<Output, E> = SignalProducer.empty
        let producerIdentifier = filter.identifier
        queue.sync {
            if let producer = cache[producerIdentifier] {
                result = producer
            } else {
                let producer = factory(filter).on(
                    terminated: { [weak self] in
                        _ = self?.queue.sync {
                            self?.cache.removeValue(forKey: producerIdentifier)
                        }
                }).replayLazily(upTo: 1)
                cache[producerIdentifier] = producer
                result = producer
            }
        }
        return result
    }

}
