//
//  CollectionCellView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/22/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct CollectionCellView: View {

    @EnvironmentObject var spotify: Spotify

    /// Type: Playlist<PlaylistItemsReference> or Album
    let collection: Any

        /// The cover image for the playlist. If we want to switch it back to the square SpotifyAlbumPlaceholder, we need a version for light mode
    @State private var image = Image(systemName: "music.note")

    @State private var didRequestImage = false

        // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var playPlaylistCancellable: AnyCancellable? = nil

    var body: some View {
        NavigationLink {
            EmptyView()
        } label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
//                    .padding(.trailing, 5)
                collectionName()
                Spacer()
            }
            // Ensure the hit box extends across the entire width of the frame.
            // See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
        }
        .onAppear(perform: loadImage)
    }
    
    func collectionName() -> Text {
        if let album = collection as? Album {
            return Text(album.name)
        }
        if let playlist = collection as? Playlist<PlaylistItemsReference> {
            return Text(playlist.name)
        }
        return Text("")
    }
    
    func loadImage() {

        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
        if self.didRequestImage {
            // print("already requested image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        var spotifyImage: SpotifyImage
        
        if let image = ((collection as? Album)?.images?.largest) {
            spotifyImage = image
        }
        else if let image = ((collection as? Playlist<PlaylistItemsReference>)?.images.largest) {
            spotifyImage = image
        }
        else { return }

        // print("loading image for '\(playlist.name)'")

        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    self.image = image
                }
            )
    }
}

