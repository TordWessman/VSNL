//
//  VSNLRequestFactory.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

/** Implementations of this are responsible for the creation of `URLRequests`. */
public protocol VSNLRequestFactory: Actor {

    /** Will create a URLRequest by combining the properties of a `VSNL.Request` and a `VSNLSession`. */
    func createRequest<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async throws -> URLRequest
}

/** Default `VSNLRequestFactory` implementation. */
public actor VSNLDefaultRequestFactory: VSNLRequestFactory {

    typealias Error = VSNL.Error

    private let cachePolicy: URLRequest.CachePolicy
    private let timeoutInterval: TimeInterval

    /** Optional constructor parameters for fine-tuning the `URLRequest`. */
    public init(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0) {
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
    }
    
    public func createRequest<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async throws -> URLRequest {

        guard var components = URLComponents(string: await session.host) else {
            throw Error.urlComponents
        }

        if components.scheme == nil {
            components.scheme = "https"
        }

        components.path += await createPath(request: request, session: session)
        components.queryItems = try await createQueryItems(request: request, session: session)

        guard let url = components.url else {
            throw Error.urlCreation(path: components.path)
        }

        var urlRequest = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)

        if request.method() == .put || request.method() == .post {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        }

        urlRequest.httpMethod = request.method().rawValue
        urlRequest.allHTTPHeaderFields = await createHeaders(request: request, session: session)

        return urlRequest
    }

    private func createPath<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async -> String {

        if await session.host.last != "/" && request.path().first != "/" {
            return "/" + request.path()
        } else if await session.host.last == "/" {
            var path = request.path()
            while path.hasPrefix("/") {
                path = String(path.dropFirst())
            }
            return path
        }

        return request.path()
    }

    private func createQueryItems<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async throws -> [URLQueryItem]? {

        var queryItems = [URLQueryItem]()

        if request.method() == .get || request.method() == .delete {
            queryItems += try request.asQuery()
        }

        let sessionQueryStringParameters = await session.queryStringParameters
        if !sessionQueryStringParameters.isEmpty {
            queryItems += sessionQueryStringParameters.map { URLQueryItem(name: $0.key, value: $0.value)}
        }

        return queryItems.isEmpty ? nil : queryItems
    }

    private func createHeaders<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async -> [String: String] {
        
        var allHTTPHeaderFields = ["Content-Type": "application/json"]

        for header in await session.headers {
            allHTTPHeaderFields[header.key] = header.value
        }

        if let headers = request.headers() {
            for header in headers {
                allHTTPHeaderFields[header.key] = header.value
            }
        }
        return allHTTPHeaderFields
    }
}
