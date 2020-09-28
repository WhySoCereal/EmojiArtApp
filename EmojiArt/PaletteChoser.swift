//
//  PaletteChoser.swift
//  EmojiArt
//
//  Created by Brian Alldred on 27/09/2020.
//

import SwiftUI

struct PaletteChoser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @State private var showPaletteEdittor = false
    
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                chosenPalette = document.palette(after: chosenPalette)
            }, onDecrement: {
                chosenPalette = document.palette(before: chosenPalette)
            }, label: { EmptyView() })
            Text(document.paletteNames[chosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    showPaletteEdittor = true
                }
                .popover(isPresented: $showPaletteEdittor) {
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEdittor)
                        .environmentObject(document)
                        .frame(minWidth: 300, minHeight: 500)
                }
        }
        // doesn't use any extra space offered to it
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    // When passing the ViewModel to a separate View, we want to do it as an Environment Object
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette: String
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor")
                    .font(.headline)
                    .padding()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowing = false
                    }, label: {
                        Text("Done")
                    }).padding()
                }
            }
            
            Divider()
            Form {
                Section(header: Text("Palette Name")) {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    }).padding()
                    
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    }).padding()
                }
                
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .onTapGesture {
                                document.removeEmoji(emoji, fromPalette: chosenPalette)
                            }
                            .font(Font.system(size: fontSize))
                        
                    }
                    .frame(height: height)
                }
            }
        }
        .onAppear {
            paletteName = document.paletteNames[chosenPalette] ?? ""
        }
    }
    
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    var fontSize: CGFloat = 40
}


struct PaletteChoser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChoser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}


