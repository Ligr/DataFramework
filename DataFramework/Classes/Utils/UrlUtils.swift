//
//  UrlUtils.swift
//  DataFramework
//
//  Created by Alex on 6/26/18.
//

import Foundation

struct UrlUtils {

    static func urlQuery(with params: [String: String]) -> String? {
        let params = params.map({
            if $0.value.isEmpty {
                return $0.key
            } else {
                return $0.key + "=" + $0.value
            }
        }).joined(separator: "&")
        if params.count > 0 {
            return params
        }
        return nil
    }

}
