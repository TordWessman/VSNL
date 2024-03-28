//
//  VSNLSimpleClient.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation

/** Simple HTTP client interface. */
public protocol VSNLSimpleClient: Actor {

    /** Sends a request of type `RequestType` and returns a model of type `RequestType.ResponseType` if successful or `nil` if the request was canceled or HTTP status code was 204 (No Content). */
    @discardableResult
    func send<RequestType: VSNL.Request>(_ request: RequestType) async throws ->
    RequestType.ResponseType?
}

public actor VSNLDefaultSimpleClient {

    private let client: VSNLDefaultClient<VSNLNoErrorModelDefined>

    public var session: VSNLSession { client.session }

    /** Initialize using a `VSNLSession` and optional `VSNLNetworkLayer` and a `VSNLRequestFactory` if more configuration is needed. */
    public init(session: VSNLSession,
                network: VSNLNetworkLayer = URLSession.shared,
                requestFactory: VSNLRequestFactory = VSNLDefaultRequestFactory()) {
        client = VSNLDefaultClient<VSNLNoErrorModelDefined>(session: session, network: network, requestFactory: requestFactory)
    }

    /** Convenience initializer where a `VSNLDefaultSession` is created using the `host` parameter. */
    public init(host: String) {
        client = VSNLDefaultClient<VSNLNoErrorModelDefined>(session: VSNLDefaultSession(host: host))
    }

    @discardableResult
    public func send<RequestType: VSNL.Request>(_ request: RequestType) async throws ->
    RequestType.ResponseType? {

        guard let result = try await client.send(request)?.result else {
            return nil
        }
        
        switch (result) {
        case .success(let model):
            return model
        case .failure(let error):
            throw VSNL.Error.error(model: error)
        }
    }
}

/** Use this if the no expected error model is required. */
public struct VSNLNoErrorModelDefined: Decodable { let 🤬: Int }
