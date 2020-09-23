//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    // use map to turn a String into an array of Strings
                    // \.self = a keypath, a var on another object
                    ForEach(EmojiArtDocument.palette.map{ String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
        }
        
        GeometryReader { geometry in
            ZStack {
                Color.white
                    // overlay to size to the rectangle rather than of sizing to the image
                    .overlay( // argument to overlay is not a view builder - has to be a view therefore wrapped in a group (a single view)
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                ForEach(self.document.emojis) { emoji in
                    Text(emoji.text)
                        .font(animatableWithSize: emoji.fontSize * zoomScale)
                        .position(position(for: emoji, in: geometry.size))
                }
            }
            .clipped()
            .gesture(panGesture())
            .gesture(zoomGesture())
            .edgesIgnoringSafeArea([.bottom, .horizontal])
            // public.image is a URI, isTargeted - arguments is a binding (when dragging over us)
            // providers - provide information being dropped - transfer happens asynchronously
            .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                var location = geometry.convert(location, from: .global)
                location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                return self.drop(providers: providers, at: location)
            }
        }
    }
    
    // MARK: - Zoom gesture
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
        // what happens when done
            .onEnded {
                withAnimation {
                    self.zoomToFit(document.backgroundImage, in: size)
                }
                
            }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            // $ is a binding
            .updating($gestureZoomScale) { latestGestureScale, ourGestureStateInOut, transaction in
                // gesture only wants you to modify the state within the gesture (while it's happening)
                ourGestureStateInOut = latestGestureScale
            }
            .onEnded { finalGestureScale in
                self.steadyStateZoomScale *= finalGestureScale
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Pan gesture
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: emoji.location.x + size.width/2, y: emoji.location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        // URL.self (returns the type itself)
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.setBackgroundURL(url) // intent called
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }

    private let defaultEmojiSize: CGFloat = 40
}
