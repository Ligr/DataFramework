//
//  DataFilter.swift
//  DataKit
//
//  Created by Alex on 1/11/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation

protocol DataFilterProtocol {
    
    var identifier: String { get }
    
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol HttpDataFilterProtocol: DataFilterProtocol {

    var method: HttpMethod { get }
    var path: String { get }
    var requestParams: [String: String] { get }
    var headerParams: [String: String] { get set }
    var body: Data? { get }

}

class HttpDataFilter: HttpDataFilterProtocol {

    let method: HttpMethod
    let path: String
    let requestParams: [String: String]
    var headerParams: [String: String]
    let body: Data?
    
    init(path: String, method: HttpMethod = .get, requestParams: [String: String] = [:], headerParams: [String: String] = [:], body: Data? = nil) {
        self.path = path
        self.method = method
        self.requestParams = requestParams
        self.headerParams = headerParams
        self.body = body
    }

    var identifier: String {
        var fullString = path + "|" + method.rawValue + "|"
        fullString += requestParams.map { $0.0 + $0.1 }.joined()
        fullString += headerParams.map { $0.0 + $0.1 }.joined()
        return fullString
    }
    
}
