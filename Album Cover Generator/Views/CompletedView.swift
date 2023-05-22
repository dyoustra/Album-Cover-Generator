//
//  CompletedView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 5/17/23.
//

import SwiftUI

struct CompletedView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var spotify: Spotify

    let generatedImage: Image
    let collectionName : String
    let isPlaylist : Bool
    
    @State var items : [Any] = []
    
    @State var displayShareSheet = false
    
    @Binding var displayCompletedView : Bool
    
    @State private var renderedImage: Image?
    
    var body: some View {
        VStack {
            generatedImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(50)
                .shadow(radius: 20)
                .padding()
                .onAppear {
                    let renderer = ImageRenderer(content: generatedImage)
                    renderer.scale = 3
                    if let image = renderer.cgImage {
                        renderedImage = Image(decorative: image, scale: 1.0)
                    }
                }
            Text(collectionName)
                .font(.largeTitle)
                .bold()
            
//            Button(action: {
//                
//            }) {
//                HStack {
//                    Text("Show Diffusion Steps")
//                    Image(systemName: "photo.on.rectangle.angled")
//                }
//                .frame(maxWidth: .infinity)
//                .foregroundColor(colorScheme == .dark ? .black : .white)
//                .padding(10)
//                .bold()
//            }
//            .background(Color.primary)
//            .cornerRadius(10)
//            .padding(5)
//            
//            if (isPlaylist) {
//                Button(action: {
//                    
//                }) {
//                    HStack {
//                        Text("Upload to Spotify")
//                        Image(systemName: "music.note")
//                    }
//                    .frame(maxWidth: .infinity)
//                    .foregroundColor(colorScheme == .dark ? .black : .white)
//                    .padding(10)
//                    .bold()
//                }
//                .background(Color.primary)
//                .cornerRadius(10)
//                .padding(5)
//            }
            
            Button(action: {
                displayCompletedView = false
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                    .padding(10)
                    .bold()
            }
            .background(Color.primary)
            .cornerRadius(10)
            .padding(5)
        }
        .navigationTitle(!isPlaylist ? Text("Album Cover") : Text("Playlist Cover"))
        .toolbar {
            if let renderedImage {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink("Share", item: renderedImage, subject: Text("Share Generated Image"),  message: Text(""), preview: SharePreview(Text(collectionName), image: renderedImage))
                }
            }
        }
    }
}
