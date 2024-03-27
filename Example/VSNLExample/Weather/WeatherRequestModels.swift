//
//  WeatherModels.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation
import VSNL

struct GeoLookupRequest: VSNL.Request {

    typealias ResponseType = [GeoLookupItem]
    let q: String
    let limit = 10
    func path() -> String { "geo/1.0/direct" }
    func ttl() -> TimeInterval { 60 * 60 * 24 }
}

struct GeoLookupItem: Decodable {

    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}

struct WeatherRequest: VSNL.Request {

    typealias ResponseType = WeatherResponse

    let lon: Double
    let lat: Double
    let lang: String
    let units = "metric"

    //https://openweathermap.org/current
    func path() -> String { "data/2.5/weather" }
}

struct WeatherResponse: Decodable {

    struct Details: Decodable {

        let temp: Double?
        let humidity: Double?
    }

    struct Wind: Decodable {
        let speed: Double?
        let deg: Double?
    }

    struct Description : Decodable {

        let description: String?
        let icon: String?
    }

    let weather: [Description]
    let main: Details?
    let wind: Wind?

    var desription: String { return weather.first?.description ?? "" }
}

extension GeoLookupItem {

    var title: String {
        if let state {
            return "\(name) (\(state))"
        }
        return name
    }

    /// https://onmyway133.com/posts/how-to-show-flag-emoji-from-country-code-in-swift/
    var flag: String {
        let base : UInt32 = 127397
        var s = ""
        for v in country.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
}

extension Array where Element == GeoLookupItem {

    private static let delimiter: Double = 0.2

    func removeSimilar() -> [Element] {

        var items = [GeoLookupItem]()
        for i in self {
            if !items.contains(where: {
                (i.name.contains($0.name) || $0.name.contains(i.name))  &&
                $0.country == i.country &&
                abs($0.lon - i.lon) < Self.delimiter &&
                abs($0.lat - i.lat) < Self.delimiter
            }) {
                items.append(i)
            }
        }
        return items
    }
}

extension WeatherResponse {

    var containsEnoughData: Bool {
        return main?.temp != nil && !desription.isEmpty
    }
}
