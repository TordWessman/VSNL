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

    /** Default network interface responsible for sending `VSNL.Request` objects. */
    public typealias Client = VSNLDefaultClient<VSNLNoErrorModelDefined>

    /** Default network interface responsible for sending `VSNL.Request` objects.  An "expected error type" is required as a generic parameter. */
    public typealias AdvancedClient = VSNLDefaultClient

    /** Simple network client interface */
    public typealias SimpleClient = VSNLDefaultSimpleClient

    /** Network configuration, including host and global header parameters. */
    public typealias Session = VSNLDefaultSession

    /** Errors thrown by the network layer. */
    public typealias Error = VSNLError
}
