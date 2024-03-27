//
//  DefaultClientTest.swift
//  VSNLTests
//
//  Created by Tord Wessman on 2024-03-26.
//

import XCTest
@testable import VSNL

final class RequestFactoryTests: XCTestCase {

    func makeSUT(host: String, method: VSNL.HttpMethod) -> (VSNLDefaultRequestFactory, VSNLDefaultSession) {
        let requestFactory = VSNLDefaultRequestFactory()
        let session = VSNLDefaultSession(host: host)
        return (requestFactory, session)
    }

    func testGenerateGet() async throws {
        let requestModel = SimpleMockRequest(aValue: 42, method: .get, path: "/bar")
        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .get)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual("https://example.com/foo/bar?a_value=42", urlRequest.url?.absoluteString)
        XCTAssertNil(urlRequest.httpBody)
    }

    func testGeneratePost() async throws {
        let requestModel = SimpleMockRequest(aValue: 42, method: .post, path: "/bar")
        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .post)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/foo/bar")
        XCTAssertEqual("{\"a_value\":42}", String(data: urlRequest.httpBody!, encoding: .utf8))
    }

    func testGenerateComplexPut() async throws {
        let member = ComplexMockRequest.Embedded(foo: "baz", bar: [1, 2 ,3])
        let list = [ComplexMockRequest.Embedded(foo: "cat", bar: [42, 43])]
        let requestModel = ComplexMockRequest(member: member, list: list, method: .put, path: "/rat")

        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .post)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/foo/rat")
        XCTAssertEqual("{\"member\":{\"foo\":\"baz\",\"bar\":[1,2,3]},\"list\":[{\"foo\":\"cat\",\"bar\":[42,43]}]}", String(data: urlRequest.httpBody!, encoding: .utf8))
    }

    func testNoAdditionalHeaders() async throws {

        let requestModel = SimpleMockRequest(aValue: 42, method: .get, path: "/bar")
        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .get)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual(1, urlRequest.allHTTPHeaderFields!.count)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields!.contains(key: "Content-Type", value: "application/json"))
    }

    func testModelHeaders() async throws {

        var requestModel = SimpleMockRequest(aValue: 42, method: .get, path: "/bar")
        requestModel._headers = ["Dog": "rat"]

        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .get)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual(2, urlRequest.allHTTPHeaderFields!.count)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields!.contains(key: "Content-Type", value: "application/json"))
        XCTAssertTrue(urlRequest.allHTTPHeaderFields!.contains(key: "Dog", value: "rat"))
    }

    func testSessionAndModelHeaders() async throws {

        var requestModel = SimpleMockRequest(aValue: 42, method: .get, path: "/bar")
        requestModel._headers = ["Fish": "bowl"]

        let (requestFactory, session) = makeSUT(host: "https://example.com/foo/", method: .get)
        await session.setHeader(key: "Dog", value: "rat")
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)
        XCTAssertEqual(3, urlRequest.allHTTPHeaderFields!.count)
        XCTAssertTrue(urlRequest.allHTTPHeaderFields!.contains(key: "Content-Type", value: "application/json"))
        XCTAssertTrue(urlRequest.allHTTPHeaderFields!.contains(key: "Dog", value: "rat"))
    }

    func testSessionQueryStringParametersGet() async throws {
        let requestModel = SimpleMockRequest(aValue: 42, method: .get, path: "bar")

        let (requestFactory, session) = makeSUT(host: "https://example.com/foo", method: .get)
        await session.setQueryStringParameter(key: "duck", value: 43)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)

        XCTAssertEqual("https://example.com/foo/bar?a_value=42&duck=43", urlRequest.url?.absoluteString)
        XCTAssertNil(urlRequest.httpBody)
    }

    func testSessionQueryStringParametersPost() async throws {
        let requestModel = SimpleMockRequest(aValue: 42, method: .post, path: "bar")

        let (requestFactory, session) = makeSUT(host: "https://example.com", method: .get)
        await session.setQueryStringParameter(key: "duck", value: 43)
        let urlRequest = try await requestFactory.createRequest(request: requestModel, session: session)

        XCTAssertEqual("https://example.com/bar?duck=43", urlRequest.url?.absoluteString)
        XCTAssertEqual("{\"a_value\":42}", String(data: urlRequest.httpBody!, encoding: .utf8))
    }
}
