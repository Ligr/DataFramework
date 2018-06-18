//
//  AuthService.swift
//  DataFramework
//
//  Created by Alex on 6/18/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import ReactiveSwift

public protocol AuthServiceProtocol {

    func authRequest<Service: ServiceProtocol>(with filter: Service.FilterType, service: Service) -> SignalProducer<Service.ResultType, ServiceError> where Service.FilterType: HttpDataFilterProtocol

}
