//
//  VSNLClient.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

/** The HTTP Client. */
public protocol VSNLClient: Actor {

    /** A `Decodable` type representing an _expected_ error model. */
    associatedtype ErrorType: Decodable

    /**
        Make an API call using a request of type `RequestType`.

        There are 4 potential results of the execution.

        1. The HTTP status code == 200 and the HTTP body could be parsed as a `RequestType.ResponseType`. A `VSNLResponse` will be returned with the `model` property set.
        2. The HTTP status code != 200 and the HTTP body could be parsed as an  `ErrorType`.  A `VSNLResponse` will be returned with the `error` property set.
        3. The request-task was canceled, causing the method to return `nil`
        4. An error occurred causing the method to `throw`.

        - Parameters:
            - request: Request model conforming to `VSNL.Request`.
        - Returns:`VSNLResponse<RequestType, ErrorType>` or `nil` if the request-task was canceled.

        - Throws: On any error or if the response can't be interpreted.
     */
    func send<RequestType: VSNL.Request>(_ request: RequestType) async throws ->
        VSNLResponse<RequestType, ErrorType>?
}

/** Default `VSNLClient` implementation. */
public actor VSNLDefaultClient<T: Decodable>: VSNLClient {

    public typealias ErrorType = T

    /** Access to the `VSNLSession` used by the connection. */
    public let session: VSNLSession

    private let requestFactory: VSNLRequestFactory
    private let network: VSNLNetworkLayer

    /** Initialize using a `VSNLSession` and optional `VSNLNetworkLayer` and a `VSNLRequestFactory` if more configuration is needed. */
    public init(session: VSNLSession,
                network: VSNLNetworkLayer = URLSession.shared,
                requestFactory: VSNLRequestFactory = VSNLDefaultRequestFactory()) {
        self.session = session
        self.network = network
        self.requestFactory = requestFactory
    }

    @discardableResult
    public func send<RequestType: VSNL.Request>(_ request: RequestType) async throws -> VSNLResponse<RequestType, ErrorType>? {

        let urlRequest = try await requestFactory.createRequest(request: request, session: session)

        var data: Data
        var response: URLResponse

        do {
            (data, response) = try await network.data(for: urlRequest)
            try Task.checkCancellation()
        } catch (_ as CancellationError) {
            return nil
        } catch {
            throw error
        }

        guard let response = response as? HTTPURLResponse else {
            throw VSNL.Error.responseType(response: response)
        }

        if response.statusCode == 204 {
            return VSNLResponse(model: nil, error: nil, code: 204, headers: response.allHeaderFields)
        }

        if data.isEmpty {
            throw VSNL.Error.noData
        }

        if response.statusCode == 200 {
            let responseModel: RequestType.ResponseType = try JSONDecoder().decode(RequestType.ResponseType.self, from: data)
            return VSNLResponse(model: responseModel,
                                error: nil,
                                code: 200,
                                headers: response.allHeaderFields)
        }

        if let errorModel = try? JSONDecoder().decode(ErrorType.self, from: data) {
           return VSNLResponse(model: nil,
                               error: errorModel,
                               code: response.statusCode,
                               headers: response.allHeaderFields)
        }

        throw VSNL.Error.invalidResponseCode(code: response.statusCode)
    }
}
