//
//  UsersExample.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation

import Combine
import VSNL

@MainActor
class UsersViewModel {

    private let client = VSNL.SimpleClient(host: "https://importantwebpagewhereistoremyusers.com")

    @Published
    private(set) var users = [UserResponse]()

    func search(name: String) {
        Task { [weak self] in
            do {
                if let users = try await self?.client.send(SearchUserRequest(name: name)) {
                    self?.users = users
                }
            } catch { print(error) }
        }
    }

    func create(name: String, password: String) {
        Task { [weak self] in
            do {
                if let newUser = try await self?.client.send(CreateUserRequest(name: name, password: password)) {
                    print("Created a user with id \(newUser.id)")
                }
            } catch { print(error) }
        }
    }

    func getUser(id: String) async -> UserResponse? {
        do {
            return try await client.send(GetUser(id: id))
        } catch { print(error) }
        return nil
    }
}

struct UserResponse: Decodable {
    let id: String
    let name: String
    let email: String
}

// Will generate a `GET "/users/search?name=<name>"` call.
struct SearchUserRequest: VSNL.Request {
    typealias ResponseType = [UserResponse]

    let name: String
    func path() -> String { "/users/search" }
}

// Will generate a `POST /users/new` call with the body `{"name": <name>, "password": <password>}`
struct CreateUserRequest: VSNL.Request {

    typealias ResponseType = Response

    let name: String
    let password: String

    func path() -> String { "/users/new" }
    func method() -> VSNL.HttpMethod { .post }

    struct Response: Decodable {
        let id: String
    }
}

// Will generate a `GET /users/<id>`
struct GetUser: VSNL.Request {

    typealias ResponseType = UserResponse

    let id: String

    // Omit the `id` parameter from being decoded
    enum CodingKeys: CodingKey { }

    func path() -> String { "/users/\(id)" }

}
