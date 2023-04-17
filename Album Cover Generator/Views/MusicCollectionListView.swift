//
//  MusicCollectionListView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/22/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

enum MusicCollectionType: String {
    case Albums
    case Playlists
}

struct MusicCollectionListView: View {
    
    @EnvironmentObject var spotify: Spotify
    let collectionType: MusicCollectionType
    
    // either [Playlist<PlaylistItemsReference>] or [Album
    @State private var collection: [Any] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingCollection = false
    @State private var couldntLoadCollection = false
    
    var itemLimit = 50

    var body: some View {
        VStack {
            if collection.isEmpty {
                if isLoadingCollection {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading \(collectionType.rawValue)")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadCollection {
                    Text("Couldn't Load \(collectionType.rawValue)")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No \(collectionType.rawValue) Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                List {
                    switch collectionType {
                        case .Playlists:
                            if let playlists = collection as? [Playlist<PlaylistItemsReference>] {
                                ForEach(playlists, id: \.id) { playlist in
                                    CollectionCellView(collection: playlist).environmentObject(spotify)
                                }
                            }
                        case .Albums:
                            if let albums = collection as? [Album] {
                                ForEach(albums, id: \.id) { album in
                                    CollectionCellView(collection: album).environmentObject(spotify)
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .accessibility(identifier: "\(collectionType.rawValue) List View")
            }
        }
        .navigationTitle("\(collectionType.rawValue)")
        .navigationBarItems(trailing: refreshButton)
        .onAppear {
            switch collectionType {
                case .Albums: retrieveAlbums()
                case .Playlists: retrievePlaylists()
            }
        }
    }
    
    var refreshButton: some View {
        VStack {
            switch collectionType {
            case .Albums:
                Button(action: retrieveAlbums) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title)
                        .scaleEffect(0.8)
                }
                .disabled(isLoadingCollection)
            case .Playlists:
                Button(action: retrievePlaylists) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title)
                        .scaleEffect(0.8)
                }
                .disabled(isLoadingCollection)
            }
        }
    }
    
    func retrievePlaylists() {
        self.isLoadingCollection = true
        self.collection = []
        spotify.api.currentUserPlaylists(limit: itemLimit)
        // Gets all pages of playlists.
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingCollection = false
                    switch completion {
                        case .finished:
                            self.couldntLoadCollection = false
                        case .failure(_):
                            self.couldntLoadCollection = true
                    }
                },
                // We will receive a value for each page of playlists. You could
                // use Combine's `collect()` operator to wait until all of the
                // pages have been retrieved.
                receiveValue: { playlistsPage in
                    let playlists = playlistsPage.items
                    self.collection.append(contentsOf: playlists)
                }
            )
            .store(in: &cancellables)
    }
    
    func retrieveAlbums() {
        self.isLoadingCollection = true
        self.collection = []
        spotify.api.currentUserSavedAlbums()
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingCollection = false
                    switch completion {
                        case .finished:
                            self.couldntLoadCollection = false
                        case .failure(_):
                            self.couldntLoadCollection = true
                    }
                },
                receiveValue: { savedAlbums in
                    let albums = savedAlbums.items
                        .map(\.item)
                        /*
                         Remove albums that have a `nil` id so that this
                         property can be used as the id for the ForEach above.
                         (The id must be unique, otherwise the app will crash.)
                         In theory, the id should never be `nil` when the albums
                         are retrieved using the `currentUserSavedAlbums()`
                         endpoint.

                         Using \.self in the ForEach is extremely expensive as
                         this involves calculating the hash of the entire
                         `Album` instance, which is very large.
                         */
                        .filter { $0.id != nil }
                    
                    self.collection.append(contentsOf: albums)
                }
            )
            .store(in: &cancellables)
    }
}

struct MusicCollectionListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Group {
                //            PreviewList().listStyle(.automatic)
                //            PreviewList().listStyle(.grouped)
                //            PreviewList().listStyle(.inset)
                PreviewList().listStyle(.insetGrouped)
                //            PreviewList().listStyle(.plain)
                //            PreviewList().listStyle(.sidebar)
            }
        }
    }
}

struct PreviewList: View {
    var body: some View {
        List {
            HStack {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                Text("option 1")
            }
            HStack {
                Image(systemName: "music.note.list")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                Text("option 2")
            }
            HStack {
                Image(systemName: "music.quarternote.3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                Text("option 3")
            }
        }
        .navigationTitle("Playlists")
    }
}
