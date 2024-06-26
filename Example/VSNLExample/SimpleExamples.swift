//
//  SimpleExamples.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation
import VSNL

struct MyRequestExample: VSNL.Request {

    typealias ResponseType = MyRequestExample.MyResponseExample
    let foo: Int
    let bar: String

    func path() -> String { "relative/path" }
    func method() -> VSNL.HttpMethod { .post }
    func headers() -> [String : String]? { nil }

    // Definition of response object ({"baz": Int, "boo": Int? })
    struct MyResponseExample: Decodable {
        let baz: Int
        let boo: Int?
    }
}

func simpleExample1() async {

    // The `host` parameters provide the "root URL" for every request. It can optionally define a URL Scheme ("http://example.com") and/or a base path ("example.com/base/path").
    let client = VSNL.SimpleClient(host: "example.com")

    if let response = try? await client.send(MyGetRequest(requestValue: 42)) {
        print(response)
    } else {
        print("Request failed or was canceled")
    }

    // ...

    struct MyGetRequest: VSNL.Request {
        // This request expects a response object of type `MyRequest.MyResponse`.
        typealias ResponseType = MyResponse

        let requestValue: Int
        func path() -> String { "/some/path" }
        struct MyResponse: Decodable { let someReturnValue: Int }
    }
}
func simpleExample2() async {

    let session = VSNL.Session(host: "example.com")

    // Every request (regardless of HTTP method will include the query string parameter "apiKey=1234").
    await session.setQueryStringParameter(key: "apiKey", value: "1234")
    let client = VSNL.SimpleClient(session: session)

    do {
        if let response = try await client.send(SignInRequest(user: "foo", password: "bar")) {
            if response.authenticated, let jwt = response.jwt {

                // Every consequitive request will contain the header value "Authentication: Bearer <jwt>".
                await client.session.setHeader(key: "Authentication", value: "Bearer \(jwt)")
            } else {
                print("User not authenticated")
            }
        } else {
            print("Sign in task was canceled.")
        }
    } catch {
        print("Sign in failed with error: \(error).")
    }

    // ...

    struct SignInRequest: VSNL.Request {
        typealias ResponseType = Response

        let user: String
        let password: String
        func path() -> String { "/signin" }
        func method() -> VSNL.HttpMethod { .post }
        struct Response: Decodable { let authenticated: Bool, jwt: String? }
    }
}
