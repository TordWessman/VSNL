//
//  VSNLRequest.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

public extension VSNL {

    enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}

public protocol VSNLRequest: Encodable {

    /** Type of expected response model */
    associatedtype ResponseType : Decodable

    /** Request HTTP method. Defaults to ´.get´. */
    func method() -> VSNL.HttpMethod

    /** Relative path of the request (e.g. "/resources"). */
    func path() -> String

    /** Additional headers for this request. Defaults to ´nil´. */
    func headers() -> [String: String]?
}

public extension VSNLRequest {

    /** Defaults HTTP method to `.get` */
    func method() -> VSNL.HttpMethod { .get }

    /** No request-specific headers by default. */
    func headers() -> [String: String]? { nil }
}
