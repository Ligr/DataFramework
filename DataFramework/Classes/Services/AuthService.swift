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

    func authRequest<Service: ServiceProtocol>(with filter: Service.FilterType, service: Service) -> Service.ResultType where Service.FilterType: HttpDataFilterProtocol

}
