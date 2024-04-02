//
//  ViewModelExample.swift
//  
//
//  Created by Tord Wessman on 2024-03-28.
//

import Foundation
import VSNL

// View model bound to a `VSNLSimpleClient`.
class ViewModel_SimpleClient {

    let client: any VSNLSimpleClient
    init(client: any VSNLSimpleClient) {
        self.client = client
    }
}

// View model bound to a `VSNLClient`.
class ViewModel_Client {

    let client: any VSNLClient
    init(client: any VSNLClient) {
        self.client = client
    }
}

/** Example of simple mock-class.
    Implements both `VSNLClient` and `VSNLSimpleClient` because I'm lazy. */
actor MyMockClient: VSNLClient, VSNLSimpleClient {

    var responseModel: Decodable?
    var error: Error?

    func send<RequestType: VSNLRequest>(_ request: RequestType) async throws -> VSNLResponse<RequestType, VSNLNoErrorModelDefined>? {

        if let error { throw error }
        if let responseModel { return VSNLResponse(code: 200, model: responseModel as? RequestType.ResponseType) }
        return nil
    }

    @discardableResult
    func send<RequestType: VSNL.Request>(_ request: RequestType) async throws ->
    RequestType.ResponseType? {
        if let error { throw error }
        return responseModel as? RequestType.ResponseType
    }
}

func production() {

    // VSNL.SimpleClient usage.
    let clientSimple = VSNL.SimpleClient(session: VSNL.Session(host: "www.com"))
    let vmSimple = ViewModel_SimpleClient(client: clientSimple)

    // VSNL.Client usage.
    let client = VSNL.Client(session: VSNL.Session(host: "www.com"))
    let vm = ViewModel_Client(client: client)
}

func testViewModels() {

    let client = MyMockClient()
    // Yay! I'm to lazy to write two mock classes for VSNLClient and VSNLSimpleClient
    let vm_simple = ViewModel_SimpleClient(client: client)
    let vm = ViewModel_Client(client: client)
}

//--- Typed Example

// Define an "expected error" type used by your network client.
struct MyErrorType: Decodable {}

// Declare a protocol for your specific `VSNL.TypedClient` implementation.
protocol MyTypedClientProtocol: VSNLTypedClient where ErrorType == MyErrorType { }

// Make sure your network client implementation conforms to your protocol.
extension VSNL.TypedClient<MyErrorType> : MyTypedClientProtocol { }

// Create a simple mock-nework.
actor MyTypedMockClient: MyTypedClientProtocol {

    var responseModel: Decodable?
    var errorModel: Decodable?
    var error: Error?

    func send<RequestType: VSNLRequest>(_ request: RequestType) async throws -> VSNLResponse<RequestType, MyErrorType>? {

        if let error { throw error }
        if let responseModel { return VSNLResponse(code: 200, model: responseModel as? RequestType.ResponseType) }
        if let errorModel { return VSNLResponse(code: 444, model: nil, error: errorModel as? MyErrorType) }
        return nil
    }
}

// View model where the client is injected.
class ViewModel_Typed {

    // The client adhers to the associated
    let client: any MyTypedClientProtocol

    // Allow injection of any client class that implements `MyNetworkClientProtocol`
    init(client: any MyTypedClientProtocol) {
        self.client = client
    }
}

func productionTyped() async {

    // Use the production client
    let client = VSNL.TypedClient<MyErrorType>(session: VSNL.Session(host: "example.com"))
    let vm = ViewModel_Typed(client: client)
}

func testTyped() {
    // Use the mock client for unit tests
    let client_mock = MyTypedMockClient()
    let vm_for_unit_tests = ViewModel_Typed(client: client_mock)
}
