//
//  DataFilter.swift
//  DataFramework
//
//  Created by Alex on 1/11/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation

public protocol DataFilterProtocol {
    
    var identifier: String { get }
    
}

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

public protocol HttpDataFilterProtocol: DataFilterProtocol {

    var method: HttpMethod { get }
    var path: String { get }
    var requestParams: [String: String] { get set }
    var headerParams: [String: String] { get set }
    var body: Data? { get }

}

open class HttpDataFilter: HttpDataFilterProtocol {

    public let method: HttpMethod
    public let path: String
    public var requestParams: [String: String]
    public var headerParams: [String: String]
    public let body: Data?
    
    public init(path: String, method: HttpMethod = .get, requestParams: [String: String] = [:], headerParams: [String: String] = [:], body: Data? = nil) {
        self.path = path
        self.method = method
        self.requestParams = requestParams
        self.headerParams = headerParams
        self.body = body
    }

    public var identifier: String {
        var fullString = path + "|" + method.rawValue + "|"
        fullString += requestParams.map { $0.0 + $0.1 }.joined()
        fullString += headerParams.map { $0.0 + $0.1 }.joined()
        return fullString
    }
    
}
