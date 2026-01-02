//
//  PageNumberEditorSheet.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct PageNumberEditorSheet: View {
    let pageIndex: Int
    @Binding var pages: [PageItem]
    @Binding var input: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Assign Page Number") {
                    TextField("Page Number", text: $input)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("Save") {
                        if let number = Int(input) {
                            pages[pageIndex].pageNumber = number
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("Edit Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
