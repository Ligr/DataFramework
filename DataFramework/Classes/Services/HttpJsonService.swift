//
//  HttpJsonService.swift
//  DataKit
//
//  Created by Alex on 2/14/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift

final class HttpJsonService<FilterType: HttpDataFilterProtocol>: ServiceProtocol {

    typealias ResultType = HttpResponse<Any>

    private let httpService: HttpService<FilterType>

    convenience init?(baseUrl: String) {
        guard let url = URL(string: baseUrl) else {
            return nil
        }
        self.init(baseUrl: url)
    }

    init(baseUrl: URL) {
        self.httpService = HttpService(baseUrl: baseUrl)
    }

    func request(filter: FilterType) -> SignalProducer<ResultType, ServiceError> {
        var jsonFilter = filter
        jsonFilter.headerParams[HTTP.HeaderKey.accept] = HTTP.Accept.json
        return httpService.request(filter: jsonFilter).flatMap(.latest) { (result) -> SignalProducer<ResultType, ServiceError> in
            do {
                let json = try JSONSerialization.jsonObject(with: result.data, options: [])
                return SignalProducer(value: ResultType(data: json, response: result.response))
            } catch let error {
                return SignalProducer(error: .invalidJson(error))
            }
        }
    }
    
}
