//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

// ViewModel

import SwiftUI

class EmojiArtDocument: ObservableObject {
    
    static let palette: String = "⛳️⚾️🛹🏌🏽‍♂️❤️🐥🙈🐶🐼⏰📺🏁😀🦕⭐️🌝🌞"
    
    // everytime the emojiArt changes, uses observable object mechanism to cause our view to draw
    // @Published // commented out - workaround for property observer problem with property wrappers
    private var emojiArt: EmojiArt {
        willSet {
            objectWillChange.send()
        }
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    private static let untitled = "EmojiArtDocument.Untitled"
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    // MARK: - Intent(s)
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    // Sets the backgroundImage var
    private func fetchBackgroundImageData() {
        // in the meantime, clear the background image
        backgroundImage = nil
        
        // use URLSession normally if downloading from the internet
        if let url = self.emojiArt.backgroundURL {
            // try getting the data from the contents of the url
            // try? deals with errors that Data may have thrown - if fails, it returns nil
            // Data() could take either seconds, or minutes IT CAN'T BE BLOCKING, can't be in the main thread - users will not be able to interact with the UI
            DispatchQueue.global(qos: .userInitiated).async {
                // still blocking, but on a separated background queue thread
                if let imageData = try? Data(contentsOf: url) {
                    // changing backgroundImage in a background thread is wrong since it's published so the View will redraw therefore UI will happen in a background queue - A MISTAKE
                    DispatchQueue.main.async {
                        // protect against user selecting another image if the first chosen took too long
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }

        }
        
    }
}

// Not violating MVVM since it's in the view model
extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
