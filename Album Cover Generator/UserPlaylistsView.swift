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
    @ObservedObject var spotify: Spotify

    @State private var playlists: [Playlist<PlaylistItemsReference>] = []

    @State private var cancellables: Set<AnyCancellable> = []

    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false


    var body: some View {
        NavigationView {
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
                    Text(
                                """
                                Tap on a playlist to play it. Tap and hold on a Playlist \
                                to remove duplicates.
                                """
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    List {
                        ForEach(playlists, id: \.uri) { playlist in
                            PlaylistCellView(spotify: spotify, playlist: playlist)

                        }
                    }
                    .listStyle(PlainListStyle())
                    .accessibility(identifier: "Playlists List View")
                }
            }
            .navigationTitle("Playlists")
            .navigationBarItems(trailing: refreshButton)
            .onAppear(perform: retrievePlaylists)
        }
    }

    var refreshButton: some View {
            Button(action: retrievePlaylists) {
                Image(systemName: "arrow.clockwise")
                    .font(.title)
                    .scaleEffect(0.8)
            }
            .disabled(isLoadingPlaylists)

        }

    func retrievePlaylists() {
            self.isLoadingPlaylists = true
            self.playlists = []
            spotify.api.currentUserPlaylists(limit: 50)
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
//                                self.alert = AlertItem(
//                                    title: "Couldn't Retrieve Playlists",
//                                    message: error.localizedDescription
//                                )
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

