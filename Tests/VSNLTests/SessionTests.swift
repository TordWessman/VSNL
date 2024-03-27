//
//  SessionTests.swift
//  VSNLTests
//
//  Created by Tord Wessman on 2024-03-26.
//

import XCTest
@testable import VSNL

final class SessionTests: XCTestCase {

    func testSetHeader() async {
        let session = VSNLDefaultSession(host: "http://www.com")
        var headers = await session.headers
        XCTAssertEqual(0, headers.count)
        await session.setHeader(key: "foo", value: "bar")
        headers = await session.headers
        XCTAssertEqual(1, headers.count)
        XCTAssertTrue(headers.contains(key: "foo"))
        await session.setHeader(key: "rat", value: "pig")
        headers = await session.headers
        XCTAssertEqual(2, headers.count)
        XCTAssertTrue(headers.contains(key: "foo"))
        XCTAssertTrue(headers.contains(key: "rat"))
    }

    func testRemoveHeader() async {
        let session = VSNLDefaultSession(host: "http://www.com")
        var headers = await session.headers
        XCTAssertEqual(0, headers.count)
        await session.setHeader(key: "foo", value: "bar")
        headers = await session.headers
        XCTAssertEqual(1, headers.count)
        XCTAssertTrue(headers.contains(key: "foo"))
        await session.removeHeader(key: "foo")
        headers = await session.headers
        XCTAssertEqual(0, headers.count)
        XCTAssertFalse(headers.contains(key: "foo"))
    }

    func testSetQueryStringParameter() async {
        let session = VSNLDefaultSession(host: "http://www.com")
        var qst = await session.queryStringParameters
        XCTAssertEqual(0, qst.count)
        await session.setQueryStringParameter(key: "fish", value: 42)
        qst = await session.queryStringParameters
        XCTAssertEqual(1, qst.count)
        XCTAssertEqual("42", qst["fish"])
    }

    func testRemoveQueryStringParameter() async {
        let session = VSNLDefaultSession(host: "http://www.com")
        var qst = await session.queryStringParameters
        XCTAssertEqual(0, qst.count)
        await session.setQueryStringParameter(key: "fish", value: 42)
        qst = await session.queryStringParameters
        XCTAssertEqual(1, qst.count)
        XCTAssertEqual("42", qst["fish"])
        await session.removeQueryStringParameter(key: "fish")
        qst = await session.queryStringParameters
        XCTAssertEqual(0, qst.count)
    }

}
