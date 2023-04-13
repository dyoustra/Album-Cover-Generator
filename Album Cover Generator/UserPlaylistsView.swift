//
//  UserLibraryView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/22/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct UserPlaylistsView: View {
    @EnvironmentObject var spotify: Spotify
    
    @State private var playlists: [Playlist<PlaylistItemsReference>] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
    var playlistLimit = 50
    

    var body: some View {
        VStack {
            if playlists.isEmpty {
                if isLoadingPlaylists {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Playlists")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadPlaylists {
                    Text("Couldn't Load Playlists")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No Playlists Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                List {
                    ForEach(playlists, id: \.uri) { playlist in
                        PlaylistCellView(spotify: spotify, playlist: playlist)
                    }
                }
                .listStyle(.insetGrouped)
                .accessibility(identifier: "Playlists List View")
            }
        }
        .navigationTitle("Playlists")
        .navigationBarItems(trailing: refreshButton)
        .onAppear(perform: retrievePlaylists)
    }
    
    var refreshButton: some View {
        Button(action: retrievePlaylists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPlaylists)
    }
    
    // performs onAppear
    func retrievePlaylists() {
        self.isLoadingPlaylists = true
        self.playlists = []
        spotify.api.currentUserPlaylists(limit: playlistLimit)
        // Gets all pages of playlists.
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingPlaylists = false
                    switch completion {
                        case .finished:
                            self.couldntLoadPlaylists = false
                        case .failure(_):
                            self.couldntLoadPlaylists = true
                    }
                },
                // We will receive a value for each page of playlists. You could
                // use Combine's `collect()` operator to wait until all of the
                // pages have been retrieved.
                receiveValue: { playlistsPage in
                    let playlists = playlistsPage.items
                    self.playlists.append(contentsOf: playlists)
                }
            )
            .store(in: &cancellables)
    }
}

struct UserPlaylistsView_Previews: PreviewProvider {
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
