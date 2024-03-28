//
//  AdvancedExamples.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation
import VSNL

func advancedExample1() async {

    struct Request: VSNL.Request {
        typealias ResponseType = Response
        /* ... request properties ... */
        func path() -> String { "/path" }
        struct Response: Decodable { /* ... response properties ... */ }
    }

    // This is a common error the backend uses to communicate recoverable information.
    struct ExpectedErrorModel: Decodable {
        let message: String
        let code: Int
    }

    let session = VSNL.Session(host: "example.com")

    // The client is typed to `ExpectedErrorModel`. If the HTTP status code != 200, the client will try to parse the response into an `ExpectedErrorModel`.
    let client: VSNL.AdvancedClient<ExpectedErrorModel> = VSNL.AdvancedClient(session: session)

    do {
        if let response = try await client.send(Request()),
           let result = response.result {
            switch(result) {
            case .success(let responseModel):
                print("Got response: \(responseModel)")
            case .failure(let expectedErrorModel):
                print("This can happen sometimes: \(expectedErrorModel)")
            }
        } else { print("Request task was canceled") }
    } catch {
        print("Request failed critically!")
    }
}

func advancedExample2() async {

    // Example of a request with `CodingKeys` to mask out some properties.
    struct Request: VSNL.Request {
        typealias ResponseType = Response

        // Encoded property
        let aProperty: Int
        let id: Int

        // Make sure `id` is not encoded, since it's used to derive the `path()`.
        enum CodingKeys: String, CodingKey {
            case aProperty = "a_property"
        }

        func path() -> String { "/path/\(id)" }
        func method() -> VSNL.HttpMethod { .put }

        // Enables custom headers to be set for this request type only.
        func headers() -> [String : String]? { ["Special-Header": "A-very-very-very-very-very-secret-message"]}

        struct Response: Decodable { /* ... response properties ... */ }
    }

    // Set up a custom `URLSession` with a custom cache configuration.
    let urlSessionConfiguration = URLSessionConfiguration.default
    urlSessionConfiguration.urlCache = URLCache(memoryCapacity: 2 * 1024 * 1024,
                                                diskCapacity: 8 * 1024 * 1024)
    let myURLSession = URLSession(configuration: urlSessionConfiguration)

    // Set up cache-load policy and timeout interval.
    let requestFactory = VSNLDefaultRequestFactory(cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 5.0)

    let client = VSNL.Client(
        session: VSNL.Session(host: "example.com"),
        network: myURLSession,
        requestFactory: requestFactory)

    do {
        // Send a `PUT https://example.com/path/44`.
        if let response = try await client.send(Request(aProperty: 42, id: 44)) {

            // Fetch the HTTP headers from the response.
            if let responseHeaders = response.headers {
                print("Got response headers: \(responseHeaders)")
            }

            // Fetch the model from the response.
            guard let responseModel = response.model else {

                // If the responseModel was nil, it should be an HTTP 204 (no content) reply.
                return print("Got no response model. Was it an HTTP 204? (code: \(response.code)")
            }
            print("Got response: \(responseModel)")
        }
    } catch {
        print("Argh! \(error)")
    }
}
