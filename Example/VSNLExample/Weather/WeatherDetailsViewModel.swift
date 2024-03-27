//
//  WeatherDetailsViewModel.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import SwiftUI
import VSNL

extension WeatherSearchViewModel.LocationItemViewModel {

    var asWeatherRequest: WeatherRequest {
        WeatherRequest(lon: lon, lat: lat, lang: lang)
    }
}

extension WeatherResponse {

    var asViewData: WeatherDetailsViewModel.ViewData {

        var url: URL?
        var windSpeed: String?
        var windAngle: Double?

        if let icon = weather.first?.icon {
            url = URL(string: "\(WeatherDetailsViewModel.ViewData.imageBaseEndpoint)\(icon)@2x.png")
        }

        if let speed = wind?.speed {
            windSpeed = "wind_speed_text".localize(speed)
        }
        
        if let windDirection = wind?.deg {
            windAngle = 45.0 - windDirection
        }

        return WeatherDetailsViewModel.ViewData(
            temperature: "temperature_text".localize(main?.temp ?? 0),
            url: url,
            description: weather.first?.description?.capitalized ?? "",
            windAngle: windAngle,
            windSpeed: windSpeed)
    }
}

@MainActor
class WeatherDetailsViewModel: ObservableObject {

    struct ViewData {

        static let imageBaseEndpoint = "https://openweathermap.org/img/wn/"

        let temperature: String
        let url: URL?
        let description: String
        let windAngle: Double?
        let windSpeed: String?
    }

    enum State {
        case loading
        case ready(viewData: ViewData)
        case error(message: String)
    }

    let title: String
    @Published private(set) var state: State = .loading

    private let client: VSNL.SimpleClient
    private let request: WeatherRequest
    
    init(locationViewModel: WeatherSearchViewModel.LocationItemViewModel) {
        request = locationViewModel.asWeatherRequest
        client = locationViewModel.client
        title = locationViewModel.title
    }

    func load() {
        state = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let weatherResponse = try await client.send(self.request) else { return }
                guard weatherResponse.containsEnoughData else {
                    return self.state = .error(message: "error_not_enough_data_text".localized)
                }
                self.state = .ready(viewData: weatherResponse.asViewData)
            } catch {
                self.state = .error(message: error.localizedDescription)
            }
        }
    }

}
