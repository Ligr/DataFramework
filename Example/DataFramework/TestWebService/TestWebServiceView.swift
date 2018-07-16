//
//  TestWebServiceView.swift
//  DataFramework_Example
//
//  Created by Aliaksandr on 7/16/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import DataFramework

class TestWebServiceView: UIViewController {

    private struct Response: Decodable {

        struct Item: Decodable {
            let title: String
            let details: String
        }

        let data: [Item]

    }

    private let service: HttpDecodableService<HttpDataFilter, Response> = HttpDecodableService(baseUrl: URL(string: "https://api.myjson.com/bins")!)

    override func viewDidLoad() {
        super.viewDidLoad()

        let filter = HttpDataFilter(path: "rexye")
        service.request(filter: filter).startWithResult { result in
            switch result {
            case .failure:
                print("failed")
            case .success(let response):
                for item in response.data.data {
                    print(item.title)
                }
            }
        }

    }

}
