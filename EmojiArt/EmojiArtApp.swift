//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var store: EmojiArtDocumentStore
    
    init() {
        store = EmojiArtDocumentStore(named: "Emoji Art")
    }
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
    
//    func setupStore() -> EmojiArtDocumentStore {
//        let store =
//        store.addDocument()
//        store.addDocument(named: "Hello world")
//        return store
//    }
}
