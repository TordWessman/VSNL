//
//  SimpleClientTest.swift
//  VSNLTests
//
//  Created by Tord Wessman on 2024-03-27.
//

import XCTest
@testable import VSNL

final class SimpleClientTest: XCTestCase {

    func makeSUT() -> (VSNL.SimpleClient, MockNetworkLayer, SimpleMockRequest) {

        let factory = MockURLRequestFactory()
        let session = VSNLDefaultSession(host: "https://www.foo.bar")
        let mockNetwork = MockNetworkLayer()
        mockNetwork.statusCode = 200
        let request = SimpleMockRequest(aValue: 42, method: .put, path: "/none")
        let connection = VSNL.SimpleClient(session: session, network: mockNetwork, requestFactory: factory)

        return (connection, mockNetwork, request)
    }

    func testSuccessful() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.responseModel = SimpleMockRequest.MockResponse(int: 44)
        let response = try await connection.send(request)!
        XCTAssertEqual(44, response.int)
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

    func testHttpNoContent() async throws {
        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.statusCode = 204
        let result = try await connection.send(request)
        XCTAssertNil(result)
    }

    func testCancellation() async throws {

        let (connection, mockNetwork, request) = makeSUT()
        mockNetwork.delay = 2.0
        mockNetwork.responseModel = SimpleMockRequest.MockResponse(int: 44)

        let requestExpectation = expectation(description: "requestExpectation")

        let task = Task {
            defer {
                requestExpectation.fulfill()
            }
            return try await connection.send(request)
        }
        try await Task.sleep(nanoseconds: UInt64(0.1 * 1_000_000_000))
        task.cancel()

        await fulfillment(of: [requestExpectation], timeout: 1.0)
        let result: SimpleMockRequest.MockResponse? = try await task.value

        XCTAssertNil(result)
    }
}
