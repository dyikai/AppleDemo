//
//  ContentView.swift
//  WatchDemo Watch App
//
//  Created by 邓壹恺 on 2024/4/28.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            Text("Hello World!")
            ScrollView {
                ForEach(1...30, id: \.self) { _ in
                    Text("Hello World!")
                }
            }
            Text("Hello World!")
            ScrollView {
                ForEach(1...30, id: \.self) { _ in
                    Text("Hello World!")
                }
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
