//
//  Service.swift
//  DataFramework
//
//  Created by Alex on 2/11/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift

public enum ServiceError: Error {
    case unknown
    case requestFailed(Error?)
    case invalidJson(Error?)
    case cancelled
    case authorizationFailed(Error?)
    case statusCodeInvalid(Data?, HTTPURLResponse)
    case noInternetConnection(Error?)
}

public protocol ServiceProtocol {

    associatedtype FilterType: DataFilterProtocol
    associatedtype ResultType

    func request(filter: FilterType) -> ResultType

}

public protocol HttpServiceProtocol: ServiceProtocol where ResultType == SignalProducer<DataType, ServiceError> {

    associatedtype DataType

}
