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
    
    @State var isExplicit = false

    var body: some View {
        NavigationLink {
            if #available(iOS 16.2, *) {
                if let album = collection as? Album {
                    GenerateView(coverImage: self.image, collection: album, isPlaylist: false).environmentObject(spotify)
                }

                if let playlist = collection as? Playlist<PlaylistItemsReference> {
                    GenerateView(coverImage: self.image, collection: playlist, isPlaylist: true).environmentObject(spotify)
                }
            }

        } label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .cornerRadius(10)
                collectionName()
                if (isExplicit) {
                    Image(systemName: "e.square.fill")
                }
                Spacer()
            }
            // Ensure the hit box extends across the entire width of the frame.
            // See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
        }
        .onAppear {
            loadImage()
            Task {
                if let album = collection as? Album {
                    isExplicit = await album.isExplicit(spotify: spotify)
                } else if let playlist = collection as? Playlist<PlaylistItemsReference> {
                    isExplicit = await playlist.isExplicit(spotify: spotify)
                }
            }
        }
        .font(.body)
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
    
    // another time: check if we can just replace this function by using AsyncImage
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

extension Album {
    func isExplicit(spotify: Spotify) async -> Bool {
        var loadingTracks = true
        var tracks = [Track]()
        var cancellables = [AnyCancellable]()
        spotify.api.albumTracks(self.uri!).sink(receiveCompletion: { completion in
            loadingTracks = false
        }, receiveValue: { albumItems in
            let items = albumItems.items
            for item in items {
                tracks.append(item)
            }
        })
        .store(in: &cancellables)
        
        
        while (loadingTracks) {
            
        }
        
        
        let total = tracks.reduce(0, {total, track in
            if track.isExplicit {
                return total + 1
            } else {
                return total
            }
        })
        if total >= 1 {
            return true
        }
        return false
    }
}

extension Playlist<PlaylistItemsReference> {
    
    func loadPlaylists(spotify: Spotify) async -> [Track] {
        var tracks = [Track]()
        var cancellables = [AnyCancellable]()
        spotify.api.playlistTracks(self.uri).sink(receiveCompletion: { completion in
            
        }, receiveValue: { albumItems in
            let items = albumItems.items
            for item in items {
                if let track = item.item {
                    tracks.append(track)
                }
            }
        })
        .store(in: &cancellables)
        
        return tracks
    }
    
    func isExplicit(spotify: Spotify) async -> Bool {
        var loadingTracks = true
        var tracks = [Track]()
        var cancellables = [AnyCancellable]()
        spotify.api.playlistTracks(self.uri).sink(receiveCompletion: { completion in
            loadingTracks = false
        }, receiveValue: { albumItems in
            let items = albumItems.items
            for item in items {
                if let track = item.item {
                    tracks.append(track)
                }
            }
        })
        .store(in: &cancellables)
        
        while (loadingTracks) {
            
        }
        
        let total = tracks.reduce(0, {total, track in
            if track.isExplicit {
                return total + 1
            } else {
                return total
            }
        })
        if total >= 1 {
            return true
        }
        return false
    }
}
