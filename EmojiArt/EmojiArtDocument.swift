//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

// ViewModel

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID // generates something unique
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let palette: String = "⛳️⚾️🛹🏌🏽‍♂️❤️🐥🙈🐶🐼⏰📺🏁😀🦕⭐️🌝🌞"
        
    // everytime the emojiArt changes, uses observable object mechanism to cause our view to draw
    @Published private var emojiArt: EmojiArt
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0
    
    private var autosaveCancellable: AnyCancellable?
    
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArt()
        // Link a subscriber to the emojiArt Publisher, $emojiArt is the publisher of emojiArt
        autosaveCancellable = $emojiArt.sink { emojiArt in
            print("\(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    @Published var selectedEmojiIds: Set<Int> = .init()
    
    // MARK: - Intent(s)
    
    func selectEmoji(_ emoji: Int) {
        selectedEmojiIds.toggleMatching(emoji)
    }
    
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
    
    func deleteSelectedEmojis() {
        for id in selectedEmojiIds {
            emojiArt.deleteEmoji(with: id)
        }
        selectedEmojiIds.removeAll()
    }
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
        
    }
    
    func getEmoji(withId id: Int) -> EmojiArt.Emoji? {
        for emoji in emojis {
            if emoji.id == id {
                return emoji
            }
        }
        return nil
    }
    
    private var fetchImageCancellable: AnyCancellable?
    
    // Sets the backgroundImage var
    private func fetchBackgroundImageData() {
        // in the meantime, clear the background image
        backgroundImage = nil
        
        // use URLSession normally if downloading from the internet
        if let url = self.emojiArt.backgroundURL {
            fetchImageCancellable?.cancel() // cancel the previous request and start a new fetch image request
//            let session = URLSession.shared // static var for straightforward download, don't care about timeout
//            let publisher = session.dataTaskPublisher(for: url)
//                .map { // closure give info from existing publisher i.e data and response, takes this and maps it onto the type you'd rather it be
//                    data, URLResponse in UIImage(data: data)
//                }
//                // publishes on the background threads by default - want it to be on the main queue
//                .receive(on: DispatchQueue.main)
//                // don't want it to publish errors so we don't have to deal with them in the sink modifier
//                .replaceError(with: nil)
//            // instead of sink can use publisher.assign (only works when Error is Never),
//            fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
            
            // One-liner
            
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { // closure give info from existing publisher i.e data and response, takes this and maps it onto the type you'd rather it be
                    data, URLResponse in UIImage(data: data)
                }
                // publishes on the background threads by default - want it to be on the main queue
                .receive(on: DispatchQueue.main)
                // don't want it to publish errors so we don't have to deal with them in the sink modifier
                .replaceError(with: nil)
                // instead of sink can use publisher.assign (only works when Error is Never),
                .assign(to: \.backgroundImage, on: self)

        }
        
    }
}

// Not violating MVVM since it's in the view model
extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
