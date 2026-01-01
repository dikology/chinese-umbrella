//
//  ContentView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        LibraryScreen(viewModel: DIContainer.libraryViewModel)
    }
}

#Preview {
    ContentView()
}
