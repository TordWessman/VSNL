# VSNL

VSNL, or "Vintage Scaffolding Network Layer", is a simple, yet modular and thread safe network layer written in Swift, wrapping `URLSession`. It employs the `async/await` and `throws`, reducing complexity and increasing visibility.

There are three network client interfaces:
* `VSNL.Client` is the main network interface, allowing responses to be more accurately investigated. 
* `VSNL.SimpleClient` is a simpler interface, with reduced configuration options.
* `VSNL.AdvancedClient` is similar to `VSNL.Client`, but it provides logic for "expected errors" (see [Advanced Usage](#21-expected-errors) )

## 1. Basic Examples

The `VSNL.SimpleClient` provides a basic interface configuration options suitable for most applications.

### 1.1 Basic Usage

Will make a `GET https://example.com/some/path?requestValue=42` request.
```swift
import VSNL

// The `host` parameters provides the "root URL" for every request. It can optionally define URL Scheme ("http://example.com") and/or a base path ("example.com/base/path").
let client = VSNL.SimpleClient(host: "example.com")

if let response = try? await client.send(MyGetRequest(requestValue: 42)) {
    print(response)
} else {
    print("Request failed or was cancelled")
}

// ...

struct MyGetRequest: VSNL.Request {
    // This request expects a response object of type `MyRequest.MyResponse`.
    typealias ResponseType = MyResponse

    let requestValue: Int
    func path() -> String { "/some/path" }
    struct MyResponse: Decodable { let someReturnValue: Int }
}
```

### 1.2 Basic Usage, including session configuration

In most cases, requests needs to be decorated with some extra information. This could be an authentication token of some sort or an api-key.

The following example will make a `POST https://example.com/signin?apiKey=1234` with the body `{"user": user, "password": password}`. 

It displays the usage of the "global" configuration in the `VSNL.Session` bound to `client`. 

* `session.setQueryStringParameter(key:value:)` will set a query string parameter to every request.
* `session.setHeader(key:value:)` will set a HTTP header value which will be included in every request.

In the example below, if the sign-in request was successfull, the response model, `SignInRequest.Response`, provides a `jwt` token used for consecutive requests.

This configuration is also applicable for `VSNL.Client` and `VSNL.AdvancedClient`.
```swift
let session = VSNL.Session(host: "example.com")

// Every request (regardles of HTTP method will include the query string parameter "apiKey=1234").
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
        print("Sign in task was cancelled.")
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
```

## 2. Advanced Examples

There are many situations where the basic complexity in the `VSNL.SimpleClient` is not sufficient. `VSNL.SimpleClient` wraps a `VSNL.AdvancedClient` which provides more configuration options. The `VSNL.Client` is a middle-ground which support everything `VSNL.AdvancedClient` does, but without the "expected error" logic.

### 2.1 Expected Errors
Often, backends has a "expected error" which employs a well defined format. In contrast to `VSNL.SimpleClient` (which always will throw an error if a result was not successful), A `VSNL.AdvancedClient` provides a mechanism of defining "recoverable errors", by specifying the error model during instantiation (`VSNL.AdvancedClient<ErrorModelType>`).

Here's an example an implementation:
```swift
import VSNL

// This is an common error the backend uses to communicate recoverable information.
struct ExpectedErrorModel: Decodable {
    let message: String
    let code: Int
}

struct Request: VSNL.Request {
    typealias ResponseType = Response
    /* ... request properties ... */
    func path() -> String { "/path" }
    struct Response: Decodable { /* ... response properties ... */ }
}

let session = VSNL.Session(host: "example.com")

// The client is typed to `ExpectedErrorModel`. If the HTTP status code != 200, the client will try to parse the response into an `ExpectedErrorModel`.
let client: VSNL.AdvancedClient<ExpectedErrorModel> = VSNL.AdvancedClient(session: session)

do {
    // Make a request. If `response?.result` is not `nil`, the request was successful _or_ a "recoverable error" occured.
    if let response = try await client.send(Request()),
        let result = response.result {
        switch(result) {
        case .success(let responseModel):
            print("Got response: \(responseModel)")
        case .failure(let expectedErrorModel):
            print("This can happen sometimes: \(expectedErrorModel)")
        }
    } else { print("Request task was cancelled") }
} catch {
    print("Request failed critically!")
}
```

### 2.2 Other configuration options
Here, we'll employ a `VSNL.Client` to demonstrate some of the other configuration options available. 

* Inject a custom `URLSession` (with separate cache).
* Set the request cache policy by injecting a custom `VSNLDefaultRequestFactory`.
* Check the HTTP response headers.
* Use `CodingKeys` to mask out one of the properties in `Request` in order for it to be used when composing the `path()`.
* Use custom headers for `Request`.
* See what happens if we get a HTTP status code 204 from the backend.

```swift
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
    func headers() -> [String : String]? { ["Special-Header": "A-very-very-very-very-very-secret-message"] }

    struct Response: Decodable { /* ... response properties ... */ }
}

// Set up a custom `URLSession` with custom cache configuration.
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

            // If the responseModel was nil, it should be a HTTP 204 (no content) reply.
            return print("Got no response model. Was it a HTTP 204? (code: \(response.code)")
        }
        print("Got response: \(responseModel)")
    }
} catch {
    print("Argh! \(error)")
}
```
## 3. Other Examples
* [Simple Weather app](VSNLExample)
* [User handling](VSNLExample/UsersExample.swift)
* [Basic Requests](VSNLExample/SimpleExamples.swift)
* [Advanced Requests](VSNLExample/AdvancedExamples.swift)

## 4. About
_VSNL_ was an acronym for "Very Simple Network Layer", but once I wrote it, I realized it wasn't very simple anymore, so I believe it's a more suitable abbreviation for  "Vintage Scaffolding Network Layer" or "Vampires Spreading Neurotic Love".

## 5. License
VSNL is released under the MIT license. See [LICENCE](LICENCE.txt)