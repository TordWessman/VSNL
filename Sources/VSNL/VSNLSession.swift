//
//  VSNLSession.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

/** Global HTTP configuration. */
public protocol VSNLSession: Actor {

    /** Host name. Will serve as a base URL. */
    var host: String { get }

    /** HTTP Headers added to every request. */
    var headers: [String: String] { get }

    /** Query String Parameters added to every request. */
    var queryStringParameters: [String: String] { get }

    /** Sets a "global" header field that will be included in every request. */
    func setHeader(key: String, value: String)

    /** Remove any "global" header field matching key.  This method is case-insensitive. */
    func removeHeader(key: String)

    /** Set a "global" query string parameter that will be included in every request (regardless of HTTP method). */
    func setQueryStringParameter<T: CustomStringConvertible>(key: String, value: T)

    /** Remove any "global" query string parameter matching ´key. */
    func removeQueryStringParameter(key: String)

}

/** Default `VSNLSession` implementation. */
public actor VSNLDefaultSession: VSNLSession {

    public let host: String
    private(set) public var headers: [String: String] = [:]
    private(set) public var queryStringParameters: [String: String] = [:]

    public init(host: String) {
        self.host = host
    }

    public func setHeader(key: String, value: String) {
        headers[key] = value
    }

    public func removeHeader(key: String) {
        headers = headers.filter { $0.key.lowercased() != key.lowercased() }
    }

    public func setQueryStringParameter<T: CustomStringConvertible>(key: String, value: T) {
        queryStringParameters[key] = "\(value)"
    }

    public func removeQueryStringParameter(key: String) {
        queryStringParameters = queryStringParameters.filter { $0.key != key }
    }
}
