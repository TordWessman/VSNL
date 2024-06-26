//
//  VSNLResponse.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation

/** Response data for a VSNL request which returned "expected" values.

    A successful response will contain a `model` of type `ResponseType`.

    A failed request will contain an `error` model of type `ErrorType` which
     should be expected error information from the remote host.
 */
public struct VSNLResponse<RequestType: VSNL.Request, ErrorType: Decodable> {

    /** The decoded response model or `nil`. */
    public let model: RequestType.ResponseType?

    /** The decoded error model or `nil`. */
    public let error: ErrorType?

    /** Response HTTP status code. */
    public let code: Int

    /** Response headers. */
    public let headers: [AnyHashable: Any]?

    public init(code: Int, model: RequestType.ResponseType? = nil, error: ErrorType? = nil, headers: [AnyHashable : Any]? = nil) {
        self.code = code
        self.model = model
        self.error = error
        self.headers = headers
    }
    /** Typed `Result` enumeration. */
    public enum Result {
        case success(_ model: RequestType.ResponseType)
        case failure(_ error: ErrorType)
    }

    /**
        The `VSNLResponse.Result`

        - `.success(model)` if the result was parsed correctly.

        - `.failure(errorModel)` if a model of type `ErrorType` was parsed.

        - `nil` if nothing was parsed (typically an HTTP 204).

     */
    public var result: Result? {
        if let model {
            return .success(model)
        } else if let error {
            return .failure(error)
        }
        return nil
    }
}
