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
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
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

    public convenience init<T: Encodable>(path: String, method: HttpMethod = .post, requestParams: [String: String] = [:], headerParams: [String: String] = [:], json: T) {
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(json)
        var headerParams = headerParams
        headerParams[HTTP.HeaderKey.contentType] = HTTP.ContentType.json
        self.init(path: path, method: method, requestParams: requestParams, headerParams: headerParams, body: data)
    }

    public convenience init(path: String, method: HttpMethod = .post, requestParams: [String: String] = [:], headerParams: [String: String] = [:], form: [String: String]) {
        var data: Data?
        var headerParams = headerParams
        if let query = UrlUtils.urlQuery(with: form) {
            headerParams[HTTP.HeaderKey.contentType] = HTTP.ContentType.formUrlencoded
            data = query.data(using: .utf8)
        }
        self.init(path: path, method: method, requestParams: requestParams, headerParams: headerParams, body: data)
    }

    public convenience init(path: String, requestParams: [String: String] = [:], headerParams: [String: String] = [:], mimeType: String = "application/octet-stream", multipartFormData: (String, Data)) {
        // quick and dirty implementation, will be refactored in future
        let (name, uploadData) = multipartFormData

        let boundary: String = "Boundary-\(NSUUID().uuidString)"
        var headerParams = headerParams
        headerParams[HTTP.HeaderKey.contentType] = HTTP.ContentType.multipartFormData(boundary: boundary)

        var bodyStr = "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(name)\"\r\n"
        bodyStr += "Content-Type: \(mimeType)\r\n\r\n"

        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8) ?? Data())
        data.append(bodyStr.data(using: .utf8) ?? Data())
        data.append(uploadData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())

        for (key, value) in requestParams {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }

        self.init(path: path, method: .post, requestParams: [:], headerParams: headerParams, body: data)
    }

    public var identifier: String {
        var fullString = path + "|" + method.rawValue + "|"
        fullString += requestParams.map { $0.0 + $0.1 }.joined()
        fullString += headerParams.map { $0.0 + $0.1 }.joined()
        return fullString
    }
    
}
