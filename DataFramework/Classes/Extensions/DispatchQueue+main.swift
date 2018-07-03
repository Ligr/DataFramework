//
//  DispatchQueue+main.swift
//  DataFramework
//
//  Created by Alex on 7/3/18.
//

import Foundation

extension DispatchQueue {

    static func doOnMain(_ work: @escaping () -> Void) {
        guard Thread.isMainThread == false else {
            work()
            return
        }
        DispatchQueue.main.async {
            work()
        }
    }

    static func doOnMainSync(_ work: @escaping () -> Void) {
        guard Thread.isMainThread == false else {
            work()
            return
        }
        DispatchQueue.main.sync {
            work()
        }
    }

}
