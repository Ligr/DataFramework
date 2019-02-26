//
//  Synchronizer.swift
//

import Foundation

// DO NOT PUT THIS INTO SEPARATE MODULE! (due to performance reduce)
final class Synchronizer {
    private var mutex = pthread_mutex_t()
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    init() {
        pthread_mutex_init(&mutex, nil)
    }
    func sync<R>(_ execute: () throws -> R) rethrows -> R {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
        }
        return try execute()
    }
}
