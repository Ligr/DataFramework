//
//  HttpDecodableService.swift
//  DataFramework
//
//  Created by Alex on 3/29/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public final class HttpDecodableService<FilterType: HttpDataFilterProtocol, DecodableType: Decodable>: ServiceProtocol {

    public typealias DataType = HttpResponse<DecodableType>
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
        return httpService.request(filter: jsonFilter).flatMap(.latest) { (result) -> ResultType in
            do {
                let jsonDecoder = JSONDecoder()
                let parsedData = try jsonDecoder.decode(DecodableType.self, from: result.data)
                return SignalProducer(value: DataType(data: parsedData, response: result.response))
            } catch let error {
                return SignalProducer(error: .invalidJson(error))
            }
        }
    }

}
