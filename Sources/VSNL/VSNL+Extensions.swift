//
//  VSNL+Extensions.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

internal extension Encodable {

    /** Creates a dictionary with `QueryStringParameter` values of the model. */
    func asDictionary() throws -> [String: Any] {

        let parametersData = try JSONEncoder().encode(self)
        let parameters = try JSONSerialization.jsonObject(with: parametersData, options: .allowFragments)

        guard let dictionary = parameters as? [String: Any] else {
            throw VSNL.Error.typeMissmatch
        }

        return dictionary
    }

    /** Encodes object as a query string parameterized string. */
    public func asQuery() throws -> [URLQueryItem] {

        var queryItems = [URLQueryItem]()

        let parameters = try asDictionary()

        for parameter in parameters {
            if let nestedObject = parameter.value as? [String: Any] {
                let encoded = try JSONSerialization.data(withJSONObject: nestedObject, options: .withoutEscapingSlashes)
                let queryString = String(data: encoded, encoding: .utf8)!
                queryItems.append(URLQueryItem(name: parameter.key, value: queryString))
            } else {
                queryItems.append(URLQueryItem(name: parameter.key, value: "\(parameter.value)"))
            }
        }

        return queryItems.reversed()
    }
}
