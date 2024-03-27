//
//  VSNLNetworkLayer.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation

/** The interface between the underlying network socket connection */
public protocol VSNLNetworkLayer {

    /** Imitates the implementation of `URLSession`. */
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/** Enfore URLSession to conform to VSNLNetworkLayer. */
extension URLSession: VSNLNetworkLayer { }
