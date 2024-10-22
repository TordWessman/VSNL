//
//  VSNLError.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-22.
//

import Foundation

public enum VSNLError: Error {

    case typeMissmatch
    
    /** Unable to create URLComponents. */
    case urlComponents

    /** Unable to create URL from URLComponents. */
    case urlCreation(path: String)

    /** Response was not an HTTP Response. */
    case responseType(response: URLResponse?)

    /** The response code was unexpected. */
    case invalidResponseCode(code: Int, body: String?)

    /** An error that has been decoded from an expected format. */
    case error(model: Decodable)

    /** No data returned from host. */
    case noData
}
