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

public final class HttpDecodableService<FilterType: HttpDataFilterProtocol, DecodableType: Decodable>: HttpServiceProtocol {

    public typealias DataType = HttpResponse<DecodableType>
    public typealias ResultType = SignalProducer<DataType, ServiceError>

    private let httpService: HttpService<FilterType>
    private let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?

    convenience public init?(baseUrl: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        guard let url = URL(string: baseUrl) else {
            return nil
        }
        self.init(baseUrl: url, dateDecodingStrategy: dateDecodingStrategy)
    }

    public init(baseUrl: URL, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
        self.httpService = HttpService(baseUrl: baseUrl)
        self.dateDecodingStrategy = dateDecodingStrategy
    }

    public func request(filter: FilterType) -> ResultType {
        var jsonFilter = filter
        jsonFilter.headerParams[HTTP.HeaderKey.accept] = HTTP.Accept.json
        let dateDecodingStrategy = self.dateDecodingStrategy
        return httpService.request(filter: jsonFilter).flatMap(.latest) { (result) -> ResultType in
            do {
                let jsonDecoder = JSONDecoder()
                if let dateDecodingStrategy = dateDecodingStrategy {
                    jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
                }
                let parsedData = try jsonDecoder.decode(DecodableType.self, from: result.data)
                return SignalProducer(value: DataType(data: parsedData, response: result.response))
            } catch let error {
                return SignalProducer(error: .invalidJson(error))
            }
        }
    }

}
