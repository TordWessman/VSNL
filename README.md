# VSNL

VSNL, or "Vintage Scaffolding Network Layer," is a simple, yet modular and thread-safe HTTP/JSON network layer written in Swift, wrapping `URLSession`. It employs the `async/await` and `throws`, reducing complexity and increasing visibility. 

The goal is to provide a network interface that is simple and easy to read. Instead of configuring the request _calls_, the request _models_ contains the request configuration.

## 1. Basic Examples

The `VSNL.SimpleClient` provides basic interface configuration options suitable for most applications.

### 1.1 Basic Usage

Will make a `GET https://example.com/some/path?requestValue=42` request.
```swift
import VSNL

// The `host` parameters provide the "root URL" for every request. It can optionally define a URL Scheme ("http://example.com") and/or a base path ("example.com/base/path").
let client = VSNL.SimpleClient(host: "example.com")
do {
    if let response = try await client.send(MyGetRequest(requestValue: 42)) {
        print(response)
    } else {
        print("Request was canceled")
    }
} catch {
    print("Request failed: \(error)")
}

// ...

// `MyGetRequest` defines the HTTP Method (defaults to GET) and the HTTP path.
struct MyGetRequest: VSNL.Request {

    // This request expects a response object of type `MyRequest.MyResponse`.
    typealias ResponseType = MyResponse

    // A request parameter.
    let requestValue: Int

    // The (relative) path to the resource.
    func path() -> String { "/some/path" }

    // Definition of the response object. In this case, { "someReturnValue": Int }
    struct MyResponse: Decodable { let someReturnValue: Int }
}
```

### 1.2 Basic Usage, including Session Configuration

In most cases, requests need to be decorated with extra information. This could be an authentication token of some sort or an API key.

The following example will perform a "sign-in" (`POST https://example.com/signin?apiKey=1234` with the body `{"user": user, "password": password}`.)  It will set the "authentication token" for every consecutive request if the sign-in is successful.

The example below displays the usage of the "global" configuration in the `VSNL.Session` bound to `client`. 

* `session.setQueryStringParameter(key:value:)` Will set a query string parameter to every request.
* `session.setHeader(key:value:)` Will set an HTTP header value which will be included in every request.

In the example below, if the sign-in request was successful, the response model, `SignInRequest.Response`, provides a `jwt` token used for consecutive requests.

This configuration is also applicable for `VSNL.Client` and `VSNL.TypedClient`.
```swift
let session = VSNL.Session(host: "example.com")

// Every request (regardless of HTTP method will include the query string parameter "apiKey=1234").
await session.setQueryStringParameter(key: "apiKey", value: "1234")
let client = VSNL.SimpleClient(session: session)

do {
    if let response = try await client.send(SignInRequest(user: "foo", password: "bar")) {
        if response.authenticated, let jwt = response.jwt {

            // Every consecutive request contains the header "Authentication: Bearer <jwt>".
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
```
## 2. Architecture

The core implementation of the client is the [VSNLDefaultClient<T: Decodable>](Sources/VSNL/VSNLTypedClient.swift). VSNL does, however, provide a set of simplified interfaces.

* `VSNL.Client` Is the primary network interface, allowing more accurate investigation of responses. 
* `VSNL.SimpleClient` Is a more straight-forward interface with reduced configuration options.
* `VSNL.TypedClient` Is similar to `VSNL.Client`, but it provides logic for "expected errors" (see [Typed Usage](#31-expected-errors) )

### 2.1 The Request Model

The [VSNL.Request](Sources/VSNL/VSNLRequest.swift) protocol defines the input parameters for a network request as well as the output of the request. Every call is declared by specifying an implementation of `VSNL.Request`. The implementation will be `Encodable` and contain a set of parameters (encoded into a request) and must implement one or more request-specific methods (e.g. `path()`, `method()`). 

The following code will generate a `POST example.com/relative/path` with the body `{"foo": 42, "bar": "argh" }` and expects a response of `{"baz": Int, "boo": Int? }`.

```swift
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

// ...

let client = VSNL.SimpleClient(host: "example.com")
let response = try? await client.send(MyRequestExample(foo: 42, bar: "argh"))
```

### 2.2 Other Classes
* `VSNL.Session` Represent shared client configuration.
* `URLSession` Is the default data transport layer.
* `VSNLRequestFactory` Is responsible of creating an `URLRequest`.

## 3. Advanced Examples

There are many situations where the configurational capabilities of the `VSNL.SimpleClient` is insufficient. `VSNL.SimpleClient` wraps a `VSNL.TypedClient`, which provides more configuration options. The `VSNL.Client` is a middle ground that supports everything `VSNL.TypedClient` does but without the "expected error" logic.

### 3.1 Expected Errors

Often, backends have an "expected error," which employs a well-defined format. In contrast to `VSNL.SimpleClient` (which always will throw an error if a result is unsuccessful), A `VSNL.TypedClient` provides a mechanism for defining "recoverable errors" by specifying the error model during instantiation  (`VSNL.TypedClient<ErrorModelType>`).

Here's an example of an implementation:
```swift
import VSNL

// This is a common error the backend uses to communicate recoverable information.
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
let client: VSNL.TypedClient<ExpectedErrorModel> = VSNL.TypedClient(session: session)

do {
    // Make a request. If `response?.result` is not `nil`, the request was successful _or_ a "recoverable error" occurred.
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
```

### 3.2 Other Configuration Options
Here, we'll employ a `VSNL.Client`  to demonstrate some of the other available configuration options. 

* Inject a custom `URLSession` (with a separate cache).
* Set the request cache policy by injecting a custom `VSNLDefaultRequestFactory`.
* Check the HTTP response headers.
* Use `CodingKeys` to mask out one of the properties in a `VSNL.Request` in order for it to be used when composing the `path()`.
* Use custom headers for a `VSNL.Request`.
* See what happens if we get an HTTP status code 204 from the backend.

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

            // If the responseModel was nil, it should be a HTTP 204 (no content) reply.
            return print("Got no response model. Was it a HTTP 204? (code: \(response.code)")
        }
        print("Got response: \(responseModel)")
    }
} catch {
    print("Argh! \(error)")
}
```
## 4. Unit Tests
An application needs to be able to inject a network layer to promote testability.

Each of the VSNL-client implementations has their corresponding `protocol`s.
* `VSNL.SimpleClient` implements `VSNLSimpleClient`
* `VSNL.Client` implements `VSNLClient`
* `VSNL.TypedClient` implements `VSNLTypedClient`

### 4.1 VSNLSimpleClient and VSNLClient
Neither `VSNLSimpleClient` or `VSNLClient` have any `associatedType`, so injection or mocking is relatively straight-forward.
```swift
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
```

### 4.2 VSNLTypedClient
To inject and mock a `VSNLTypedClient`, some idiosyncrasy is required. In short, create a protocol corresponding to your `VSNLTypedClient` client's implementation and use this for conformance and reference. Here's an example of code that do just that.
```swift
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
```

## 5. Other Examples
* [Simple Weather app](Example/VSNLExample)
* [User handling](Example/VSNLExample/UsersExample.swift)
* [Basic Requests](Example/VSNLExample/SimpleExamples.swift)
* [Typed Requests](Example/VSNLExample/AdvancedExamples.swift)
* [ViewModel Injection](Example/VSNLExample/ViewModelExample.swift)

## 6. About
_VSNL_ was an acronym for "Very Simple Network Layer." Still, once I wrote it, I realized it wasn't very simple anymore, so I believe it's a more suitable abbreviation for "Vintage Scaffolding Network Layer" or "Vampires Spreading Neurotic Love."

## 7. License
VSNL is released under the MIT license. See [LICENCE](LICENCE)
