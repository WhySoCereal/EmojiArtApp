//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

import SwiftUI

// Handles a UIImage that might be nil
struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
