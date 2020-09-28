//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Brian Alldred on 23/09/2020.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var chosenPalette: String = ""
    
    init(document: EmojiArtDocument) {
        self.document = document
        // _chosenPalette is the State of chosenPalette created by the property wrapper
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack {
                PaletteChoser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        // use map to turn a String into an array of Strings
                        // \.self = a keypath, a var on another object
                        ForEach(chosenPalette.map{ String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }

                Spacer()
                Button {
                    print("click")
                    deleteSelectedEmojis()
                } label: {
                    Label("Delete selected emojis", systemImage: "trash.fill")
                }
            }
            .onAppear {
                chosenPalette = document.defaultPalette
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
                
                if self.isLoading {
                    Image(systemName: "hourglass").imageScale(.large).spinning()
                } else {
                    ForEach(document.emojis) { emoji in
                        ZStack {
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * zoomScale * ((document.selectedEmojiIds.contains(matching: emoji.id)) ? emojiZoomScale : 1.0))
                                .overlay((document.selectedEmojiIds.contains(matching: emoji.id)) ? Rectangle().stroke(lineWidth: zoomScale) : nil)
                                .position(position(for: emoji, in: geometry.size))
                                // overlay if the emoji is in the set? or loop through set and draw a rectangle
                                .gesture(emojiSelectionGesture(emoji))
                                .gesture(document.selectedEmojiIds.contains(matching: emoji.id) ? dragSelectedEmojis() : nil)
                        }
                    }
                }
            }
            .clipped()
            .onTapGesture {
                document.selectedEmojiIds.removeAll()
            }
            .gesture(panGesture())
            .gesture(document.selectedEmojiIds.isEmpty ? zoomGesture().exclusively(before: dragSelectedEmojis()) : nil)
            .gesture(!document.selectedEmojiIds.isEmpty ? magnifyEmojiGesture() : nil)
            .edgesIgnoringSafeArea([.bottom, .horizontal])
            .onReceive(self.document.$backgroundImage) { image in
                self.zoomToFit(image, in: geometry.size)
            }
            // public.image is a URI, isTargeted - arguments is a binding (when dragging over us)
            // providers - provide information being dropped - transfer happens asynchronously
            .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                var location = geometry.convert(location, from: .global)
                location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                return self.drop(providers: providers, at: location)
            }
            .navigationBarItems(trailing: Button(action: {
                if let url = UIPasteboard.general.url, url != document.backgroundURL {
                    confirmBackgroundPaste = true
                } else {
                    explainBackgroundPaste = true
                }
            }, label: {
                Image(systemName: "doc.on.clipboard").imageScale(.large)
                    .alert(isPresented: $explainBackgroundPaste) { () -> Alert in
                        return Alert(title: Text("Paste Background"),
                                     message: Text("Copy the URL of an image to the clipboard and touch this button to make it the background of your document."),
                                     dismissButton: .default(Text("OK"))) // auto sets $explainBackgroundPaste to false
                    }
            }))
        }
        .zIndex(-1) // bring the document to the back and the palette choser forward
        .alert(isPresented: $confirmBackgroundPaste) { () -> Alert in
            return Alert(title: Text("Paste Background"),
                         message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                         primaryButton: .default(Text("OK")) {
                            document.backgroundURL = UIPasteboard.general.url
                         },
                         secondaryButton: .cancel())
        }
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    // MARK: - Zoom gesture
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        return document.steadyStateZoomScale * gestureZoomScale
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
                document.steadyStateZoomScale *= finalGestureScale
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStatePanOffset = .zero
            document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Pan gesture

    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
            }
    }
    
    // MARK: - Move emoji gesture
    @GestureState private var gestureEmojiOffset: CGSize = .zero
    
    private func dragSelectedEmojis() -> some Gesture {
        DragGesture()
            .updating($gestureEmojiOffset) { latestDragGestureValue, gestureEmojiOffset, transaction in
                let translation = latestDragGestureValue.translation
                gestureEmojiOffset = translation
            }
            .onEnded { finalDragGestureValue in
                print("drag")
                let translation = finalDragGestureValue.translation
                for emoji in document.selectedEmojiIds {
                    document.moveEmoji(document.getEmoji(withId: emoji)!, by: translation)
                }
            }
    }
    
    // MARK: - Resize emoji gesture
    @GestureState private var emojiZoomScale: CGFloat = 1.0
    
    private func magnifyEmojiGesture() -> some Gesture {
        MagnificationGesture()
            .updating($emojiZoomScale) { (latestGestureScale, emojiZoomScale, transaction) in
                emojiZoomScale = latestGestureScale
            }
            .onEnded { finalZoomValue in
                for emoji in document.selectedEmojiIds {
                    document.scaleEmoji(document.getEmoji(withId: emoji)!, by: finalZoomValue)
                }
            }
    }
    
    // MARK: - Select emoji gesture
    private func emojiSelectionGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded{
                document.selectEmoji(emoji.id)
            }
    }
    
    private func deleteSelectedEmojis() {
        document.deleteSelectedEmojis()
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: emoji.location.x + size.width/2, y: emoji.location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        if document.selectedEmojiIds.contains(matching: emoji.id) {
            location = CGPoint(x: location.x + gestureEmojiOffset.width, y: location.y + gestureEmojiOffset.height)
        }
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        // URL.self (returns the type itself)
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.backgroundURL = url // intent called
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
