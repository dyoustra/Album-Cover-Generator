//
//  PlaylistCellView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/22/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistCellView: View {

    @ObservedObject var spotify: Spotify

    let playlist: Playlist<PlaylistItemsReference>

        /// The cover image for the playlist.
    // if we want to switch it back to the square SpotifyAlbumPlaceholder, need a version for light mode
    @State private var image = Image(systemName: "music.note")

    @State private var didRequestImage = false

        // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var playPlaylistCancellable: AnyCancellable? = nil

    var body: some View {
        Button(action: generatePlaylistCover, label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
//                    .padding(.trailing, 5)
                Text("\(playlist.name)")
                Spacer()
            }
            // Ensure the hit box extends across the entire width of the frame.
            // See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())

        })
        .buttonStyle(PlainButtonStyle())
        .onAppear(perform: loadImage)
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

        guard let spotifyImage = playlist.images.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }

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

    func generatePlaylistCover() {
        
    }
}

