//
//  ContentView.swift
//  Accumulator
//

import SwiftUI
import LiveViewNative

struct ContentView: View {
    var body: some View {
        LiveView(.automatic(
            development: .localhost(path: "/native"),
            production: .custom(URL(string: "https://phoenix.aayushsahu.com/native")!)
        ))
    }
}
