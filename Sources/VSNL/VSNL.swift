//
//  VSNL.swift
//  VSNL
//
//  Created by Tord Wessman on 2024-03-27.
//

/** Vintage Scaffolding Network Layer. */
public enum VSNL {

    /** Models implements this protocol in order to be used as requests. */
    public typealias Request = VSNLRequest

    /**
        Default network client implementation.
        Initialize the clients with the requiered parameter `session`.
        See ``VSNLDefaultClient`` for details.

        - Parameters:
            - session: A `VSNLSession`. Use `VSNL.Session` if no custom session is required.
            - network: Underlying network layer. Defaults to `URLSession.shared`.
            - requestFactory: Responsible for creating `URLRequests` using a `VSNLSession`. Defaults to `VSNLDefaultRequestFactory`
    */
    public typealias Client = VSNLDefaultClient<VSNLNoErrorModelDefined>

    /**
        Client implementation with a typed error contstraint.
        Initialize the clients with the requiered parameter `session`.
        See ``VSNLDefaultClient`` for details.

        - Parameters:
            - session: A `VSNLSession`. Use `VSNL.Session` if no custom session is required.
            - network: Underlying network layer. Defaults to `URLSession.shared`.
            - requestFactory: Responsible for creating `URLRequests` using a `VSNLSession`. Defaults to `VSNLDefaultRequestFactory`
    */
    public typealias TypedClient = VSNLDefaultClient

    /**
        Simple network client implementation.
        Initialize the clients with the requiered parameter `session`.
        See ``VSNLDefaultSimpleClient`` for details.

        - Parameters:
            - session: A `VSNLSession`. Use `VSNL.Session` if no custom session is required.
            - network: Underlying network layer. Defaults to `URLSession.shared`.
            - requestFactory: Responsible for creating `URLRequests` using a `VSNLSession`. Defaults to `VSNLDefaultRequestFactory`
    */
    public typealias SimpleClient = VSNLDefaultSimpleClient

    /** Network configuration, including host and global header parameters. */
    public typealias Session = VSNLDefaultSession

    /** Errors thrown by the network layer. */
    public typealias Error = VSNLError

}

/** Simplify the injection of a VSNL.Client. */
extension VSNL.Client: VSNLClient { }
