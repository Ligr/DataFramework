//
//  HttpService.swift
//  DataFramework
//
//  Created by Alex on 2/11/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift

enum HTTP {

    struct ContentType {
        static let formUrlencoded = "application/x-www-form-urlencoded"
        static let json = "application/json"
        static func multipartFormData(boundary: String) -> String {
            return "multipart/form-data; boundary=\(boundary)"
        }
    }

    struct Accept {
        static let json = "application/json"
    }

    struct HeaderKey {
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let authorization = "Authorization"
    }

}

public struct HttpResponse<T> {
    public let data: T
    public let response: URLResponse
}

public final class HttpService<FilterType: HttpDataFilterProtocol>: HttpServiceProtocol {

    public typealias DataType = HttpResponse<Data>
    public typealias ResultType = SignalProducer<DataType, ServiceError>

    private let baseUrl: URL
    private let urlSession: URLSession
    private lazy var requestFactory: SignalProducerCachedFactory<FilterType, DataType, ServiceError> = {
        return SignalProducerCachedFactory(factory: { [unowned self] (filter) -> ResultType in
            return self.dataTask(with: filter)
        })
    }()

    convenience init?(baseUrl: String) {
        guard let url = URL(string: baseUrl) else {
            return nil
        }
        self.init(baseUrl: url)
    }

    public init(baseUrl: URL) {
        self.baseUrl = baseUrl
        let urlSessionConfig = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: urlSessionConfig)
    }

    public func request(filter: FilterType) -> ResultType {
        return requestFactory.producer(for: filter)
    }

}

// MARK: - Private

private extension HttpService {

    func dataTask(with filter: FilterType) -> ResultType {
        let request = urlRequest(for: filter)
        return SignalProducer { [weak self] observer, lifetime in
            guard let strongSelf = self else {
                observer.sendInterrupted()
                return
            }
            let task = strongSelf.urlSession.dataTask(with: request) { data, response, error in
                if let data = data, let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200..<300:
                        observer.send(value: DataType(data: data, response: response))
                        observer.sendCompleted()
                    default:
                        observer.send(error: .statusCodeInvalid(data, response))
                    }
                } else {
                    observer.send(error: .requestFailed(error))
                }
            }
            lifetime.observeEnded(task.cancel)
            task.resume()
        }
    }

    func urlRequest(for filter: FilterType) -> URLRequest {
        let url = self.url(for: filter)
        var request = URLRequest(url: url)
        switch filter.method {
        case .get:
            break
        case .post, .put, .patch, .delete:
            request.httpBody = filter.body
        }
        request.httpMethod = filter.method.rawValue
        for (headerKey, headerValue) in filter.headerParams {
            request.setValue(headerValue, forHTTPHeaderField: headerKey)
        }
        return request
    }

    func url(for filter: FilterType) -> URL {
        var url = baseUrl
        if filter.path.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            url = baseUrl.appendingPathComponent(filter.path)
        }
        if let query = urlQuery(for: filter), var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            urlComponents.query = query
            url = urlComponents.url ?? url
        }
        return url
    }

    func urlQuery(for filter: FilterType) -> String? {
        return UrlUtils.urlQuery(with: filter.requestParams)
    }

}
