//
//  HttpJsonService.swift
//  DataFramework
//
//  Created by Alex on 2/14/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift

public final class HttpJsonService<FilterType: HttpDataFilterProtocol>: HttpServiceProtocol {

    public typealias DataType = HttpResponse<Any>
    public typealias ResultType = SignalProducer<DataType, ServiceError>

    private let httpService: HttpService<FilterType>

    convenience init?(baseUrl: String) {
        guard let url = URL(string: baseUrl) else {
            return nil
        }
        self.init(baseUrl: url)
    }

    public init(baseUrl: URL) {
        self.httpService = HttpService(baseUrl: baseUrl)
    }

    public func request(filter: FilterType) -> ResultType {
        var jsonFilter = filter
        jsonFilter.headerParams[HTTP.HeaderKey.accept] = HTTP.Accept.json
        return httpService.request(filter: jsonFilter).flatMap(.latest) { (result) -> SignalProducer<DataType, ServiceError> in
            do {
                let json = try JSONSerialization.jsonObject(with: result.data, options: [])
                return SignalProducer(value: DataType(data: json, response: result.response))
            } catch let error {
                return SignalProducer(error: .invalidJson(error))
            }
        }
    }
    
}
