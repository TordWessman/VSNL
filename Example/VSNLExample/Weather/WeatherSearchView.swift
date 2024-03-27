//
//  WeatherSearchView.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import SwiftUI

struct WeatherSearchView: View {
    @ObservedObject var viewModel = WeatherSearchViewModel()
    @FocusState private var isEditing: Bool
    @Environment(\.colorScheme) var colorScheme

    func searchArea() -> some View {
        VStack {
            HStack {
                TextField("enter_city_name_placeholder".localized, text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isEditing)
                    .onSubmit {
                        isEditing = false
                        viewModel.load()
                    }
                Button("search".localized) {
                    isEditing = false
                    viewModel.load()
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .shadow(radius: 4)
                .padding()
            }
            .padding()
            Text(viewModel.errorText)
                .foregroundColor(.red)
        }

    }

    func searchResult() -> some View {
        List(viewModel.searchResult) { vm in
            NavigationLink(destination: WeatherDetailsView(viewModel: WeatherDetailsViewModel(locationViewModel: vm))) {
                HStack {
                    Text(vm.title)
                    Spacer()
                    Text(vm.flagEmoji)
                }
            }
            .listRowSeparator(.hidden)
        }.scrollContentBackground(.hidden)
    }
    var body: some View {
        NavigationView {
            VStack {
                searchArea()
                if (viewModel.isLoading) {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    searchResult()
                }
            }
            .navigationTitle("select_city_title".localized)
            Spacer()
        }
        .padding()
    }
}
