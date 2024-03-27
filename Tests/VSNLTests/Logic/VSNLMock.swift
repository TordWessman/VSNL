//
//  VSNLMock.swift
//  VSNLTests
//
//  Created by Tord Wessman on 2024-03-26.
//

import Foundation
@testable import VSNL

struct ComplexMockRequest: VSNL.Request {

    typealias ResponseType = ComplexMockRequest.MockResponse

    let member: Embedded
    let list: [Embedded]

    var _method: VSNL.HttpMethod = .get
    var _path: String = ""

    init(member: Embedded, list: [Embedded], method: VSNL.HttpMethod, path: String) {
        self.member = member
        self.list = list
        self._method = method
        self._path = path
    }

    enum CodingKeys: String, CodingKey {
        case member = "member"
        case list = "list"
    }

    func path() -> String { _path }
    func method() -> VSNL.HttpMethod { _method }

    struct Embedded: Encodable {
        let foo: String
        let bar: [Int]
    }
    
    struct MockResponse: Codable {
        let int: Int
    }

}
struct SimpleMockRequest: VSNL.Request, Decodable {

    typealias ResponseType = SimpleMockRequest.MockResponse

    let aValue: Int
    var _method: VSNL.HttpMethod = .get
    var _path: String = ""
    var _headers: [String: String] = [String: String]()

    init(aValue: Int, method: VSNL.HttpMethod, path: String) {
        self.aValue = aValue
        self._method = method
        self._path = path
    }

    enum CodingKeys: String, CodingKey {
        case aValue = "a_value"
    }

    func path() -> String { _path }
    func method() -> VSNL.HttpMethod { _method }
    func headers() -> [String : String]? { _headers }
    
    struct MockResponse: Codable {
        let int: Int
    }
}

struct MockErrorResponse: Codable {
    let message: String
    let code: Int
}

class MockNetworkLayer: VSNLNetworkLayer {

    let httpVersion = "HTTP/1.1"

    var responseModel: Encodable?
    var responseHeaders = [String: String]()
    var statusCode = 200
    var error: Error?
    var delay: Double?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {

        if let delay { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if let error { throw error }

        guard let url = request.url else { fatalError("request.url was nil") }

        if let responseModel {
            let data = try JSONEncoder().encode(responseModel)
            return (data, HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: responseHeaders)! as URLResponse)
        }

        return (Data(), HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: responseHeaders)! as URLResponse)
    }
}

actor MockURLRequestFactory: VSNLRequestFactory {

    var urlRequest: URLRequest

    init(urlRequest: URLRequest = URLRequest(url: URL(string: "https://foo.bar")!)) {
        self.urlRequest = urlRequest
    }

    public func createRequest<RequestType: VSNL.Request>(request: RequestType, session: VSNLSession) async throws -> URLRequest {
        return urlRequest
    }
}
