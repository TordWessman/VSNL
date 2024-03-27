//
//  WeatherDetailsView.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import SwiftUI

struct WeatherDetailsView: View {

    @ObservedObject var viewModel: WeatherDetailsViewModel

    func imageView(viewData: WeatherDetailsViewModel.ViewData) -> some View {
        VStack {
            HStack {
                Spacer()
                AsyncImage(url: viewData.url) { image in
                    image
                        .padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(EdgeInsets(top: 75, leading: 0, bottom: 0, trailing: 50))
                }
            }
            Spacer()
        }
    }

    func viewDetails(viewData: WeatherDetailsViewModel.ViewData) -> some View {

        HStack {
            VStack {
                Text(viewModel.title)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(viewData.temperature)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                Text(viewData.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 6, trailing: 0))
                if let windAngle = viewData.windAngle, let windSpeed = viewData.windSpeed {
                    HStack {
                        Text(windSpeed)
                        Image(systemName: "paperplane")
                            .rotationEffect(Angle(degrees: windAngle))
                        Spacer()
                    }
                }
                Spacer()
            }.padding()
            Spacer()
        }
    }
    var body: some View {

        ZStack {
            switch (viewModel.state) {

            case .ready(let viewData):
                imageView(viewData: viewData)
                viewDetails(viewData: viewData)
            case .error(let message):
                VStack {
                    Text("ARGH: \(message)")
                        .padding()
                    Button("Reload", action: {
                        viewModel.load()
                    })
                    Spacer()
                }
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }.onAppear {
            viewModel.load()
        }
    }
}
