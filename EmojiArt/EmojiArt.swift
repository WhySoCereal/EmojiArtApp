//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

import Foundation

struct EmojiArt {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable {
        let text: String
        var x: Int // Offset from the center
        var y: Int // Offset from the center
        var size: Int
        let id: Int     // UUID() is a bit overkill
        
        // fileprivate means no one can create an emoji outside this file
        fileprivate init(_ text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
}
