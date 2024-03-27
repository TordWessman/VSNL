//
//  ContentView.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            WeatherSearchView()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
