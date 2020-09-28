//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Brian Alldred on 27/09/2020.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document).navigationBarTitle(store.name(for: document))) {
                        EditableText(store.name(for: document), isEditing: editMode.isEditing) { name in
                            store.setName(name, for: document)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { document in
                        store.removeDocument(document)
                    }
                }
            }
            .navigationBarTitle(store.name)
            .navigationBarItems(
                leading: Button(action: {
                        store.addDocument()
                    }, label: {
                        Image(systemName: "plus").imageScale(.large)
                    }),
                trailing: EditButton()
            )
            // .environment sets the var in EnvironmentValues only for the View you call it on
            // The EditButton() needs to see this environment
            .environment(\.editMode, $editMode)
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
