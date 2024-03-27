//
//  WeatherSearchViewModel.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation
import VSNL
import Combine

@MainActor
class WeatherSearchViewModel: ObservableObject {

    private let client: VSNL.SimpleClient
    private let lang = Locale.current.language.languageCode?.identifier ?? "en"

    @Published var searchText = ""
    @Published var isLoading: Bool = false
    @Published var errorText = ""
    @Published private(set) var searchResult = [LocationItemViewModel]()

    init(apiKey: String = "63725359d843a0aadb6bc9ba9aaab40f") {

        client = VSNL.SimpleClient(host: "api.openweathermap.org")
        Task { await client.session.setQueryStringParameter(key: "appid", value: apiKey) }
    }

    func search(text: String) async throws -> [LocationItemViewModel] {

        guard let geoResult = try await client.send(GeoLookupRequest(q: text))?.removeSimilar() else { return [] }

        return geoResult.map { LocationItemViewModel(title: $0.title, flagEmoji: $0.flag, lon: $0.lon, lat: $0.lat, lang: lang, client: client) }
    }

    func load() {
        guard searchText.isValidSearchText else {
            return errorText = "error_invalid_search_text".localized
        }
        errorText = ""
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            do {
                self.searchResult = try await self.search(text: self.searchText)
                self.errorText = ""
            } catch {
                self.errorText = "\(error)"
            }

            self.isLoading = false
        }
    }

    class LocationItemViewModel: Identifiable {

        let title: String
        let flagEmoji: String
        let lang: String
        let lon: Double
        let lat: Double
        let client: VSNL.SimpleClient

        init(title: String, flagEmoji: String, lon: Double, lat: Double, lang: String, client: VSNL.SimpleClient) {
            self.title = title
            self.flagEmoji = flagEmoji
            self.lon = lon
            self.lat = lat
            self.lang = lang
            self.client = client
        }
    }
}

