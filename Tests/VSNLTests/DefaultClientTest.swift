//
//  DefaultClientTest.swift
//  VSNLTests
//
//  Created by Tord Wessman on 2024-03-26.
//

import XCTest
@testable import VSNL

final class DefaultClientTest: XCTestCase {

    func makeSUT() -> (VSNL.AdvancedClient<MockErrorResponse>, MockNetworkLayer, SimpleMockRequest) {

        let factory = MockURLRequestFactory()
        let session = VSNLDefaultSession(host: "https://www.foo.bar")
        let mockNetwork = MockNetworkLayer()
        mockNetwork.statusCode = 200
        let request = SimpleMockRequest(aValue: 42, method: .put, path: "/none")
        let connection = VSNL.AdvancedClient<MockErrorResponse>(session: session, network: mockNetwork, requestFactory: factory)

        return (connection, mockNetwork, request)
    }

    func testSimpleSuccess() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.responseModel = SimpleMockRequest.MockResponse(int: 44)
        let response = try await connection.send(request)!
        XCTAssertEqual(44, response.model!.int)
    }

    func testSimpleNetworkFail() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.error = NSError(domain: "network layer", code: 45)
        await assertThrowsAsyncError(try await connection.send(request)) { error in
            let error = error as NSError
            XCTAssertEqual(45, error.code)
        }
    }

    func testExpectedErrorModel() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.responseModel = MockErrorResponse(message: "lol", code: 123)
        mockNetwork.statusCode = 321
        let response = try await connection.send(request)!
        XCTAssertEqual("lol", response.error!.message)
        XCTAssertEqual(123, response.error!.code)
    }

    func testHeaders() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.statusCode = 200
        mockNetwork.responseModel = SimpleMockRequest.MockResponse(int: 44)
        mockNetwork.responseHeaders["dog"] = "bag"
        let response = try await connection.send(request)!
        XCTAssertEqual(1, response.headers!.count)
        XCTAssertEqual("bag", response.headers!["dog"] as! String)
    }
    
    func testUnexpectedError() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.statusCode = 503
        mockNetwork.responseModel = SimpleMockRequest.MockResponse(int: 44)
        await assertThrowsAsyncError(try await connection.send(request)) { error in
           let error = error as! VSNL.Error
            switch (error) {
            case .invalidResponseCode(let code):
                XCTAssertEqual(503, code)
            default:
                XCTFail("Wrong error model: \(error)")
            }
        }
    }
}
