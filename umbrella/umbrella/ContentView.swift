//
//  ContentView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🌂 Chinese Umbrella")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Chinese Language Learning App")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("✅ Project Setup Complete")
                    .foregroundColor(.green)
                Text("✅ Core Data Schema Ready")
                Text("✅ Dependency Injection Container")
                Text("✅ Clean Architecture Structure")
                Text("📋 Next: Authentication & Book Upload")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Spacer()

            Text("Week 1-2: Project setup, DI container, Core Data schema")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
