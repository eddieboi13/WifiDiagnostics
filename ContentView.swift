//
//  ContentView.swift
//  Networking Tools
//
//  Created by Edward Hawkson on 2/11/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: Networking_ToolsDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(Networking_ToolsDocument()))
}
