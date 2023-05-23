//
//  LibraryView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/12/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct LibraryView: View {
    @EnvironmentObject var spotify: Spotify
    @State private var logOutAlert = false
    @State private var cancellables: [AnyCancellable] = []
    @State private var username = ""
    @State private var profilePicURL = URL(string: "")
    @State private var logOut = false
    
    @State private var searchText = ""
    @State private var librarySearchType = "Albums"
    let libraryTypes = ["Albums", "Playlists"]
    
    @State var albums = [Album]()
    @State var playlists = [Playlist<PlaylistItemsReference>]()
    
    var body: some View {
        VStack {
            if logOut {
                AuthorizeView().environmentObject(spotify)
                    .navigationBarBackButtonHidden(true)
                    .navigationTitle(Text(""))
            } else {
                List {
                    Section {
                        Picker("", selection: $librarySearchType) {
                            ForEach(libraryTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: searchText) { _ in
                            if librarySearchType == "Albums" {
                                retrieveAlbums()
                            } else {
                                retrievePlaylists()
                            }
                        }
                        .onChange(of: librarySearchType) { val in
                            if val == "Albums" {
                                retrieveAlbums()
                            } else {
                                retrievePlaylists()
                            }
                        }
                    }
                    
                    Section {
                        Group {
                            VStack {
                                Spacer()
                                NavigationLink("Saved Albums") {
                                    MusicCollectionListView(collectionType: .Albums).environmentObject(spotify)
                                }
                                Spacer()
                            }
                            VStack {
                                Spacer()
                                NavigationLink("Saved Playlists") {
                                    MusicCollectionListView(collectionType: .Playlists).environmentObject(spotify)
                                }
                                Spacer()
                            }
                        }
                    }
                    Section {
                        if (librarySearchType == "Albums") {
                            ForEach(albums, id: \.self) { album in
                                CollectionCellView(collection: album)
                            }
                        } else {
                            ForEach(playlists, id: \.self) { playlist in
                                CollectionCellView(collection: playlist)
                            }
                        }
                    }
                }
                .font(.title)
                .listStyle(.insetGrouped)
                .navigationTitle("My Library")
                .searchable(text: $searchText, prompt: "Search Albums and Playlists")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            logOutAlert = true
                        }, label: {
                            AsyncImage(url: profilePicURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(Circle())
                                
                            } placeholder: {
                                Image(systemName:"person.crop.circle")
                                    .resizable()
                            }
                            .frame(width: 40, height: 40)
                        })
                    }
                }
                .alert(username, isPresented: $logOutAlert) {
                    Button("Log Out", role: .destructive) {
                        spotify.authorizationManagerDidDeauthorize()
                        withAnimation(.easeOut) {
                            logOut = true
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .onAppear(perform: getUserInfo)
            }
        }
    }
    
    func getUserInfo() {
        self.spotify.api.currentUserProfile()
            .sink { _ in
                print("recieved user info: \(self.username)")
            } receiveValue: { user in
                self.username = user.displayName ?? user.id
                if let image = user.images?.first {
                    self.profilePicURL = image.url
                } else {
                    print("couldn't find an image")
                }
            }
            .store(in: &cancellables)
    }
    
    func retrieveAlbums() {
        spotify.api.search(query: searchText, categories: [.album]).sink(receiveCompletion: {_ in
            
        }, receiveValue: { album in
            self.albums = album.albums?.items ?? [Album]()
        }).store(in: &cancellables)
    }
    
    func retrievePlaylists() {
        spotify.api.search(query: searchText, categories: [.playlist]).sink(receiveCompletion: {_ in
            
        }, receiveValue: { playlist in
            self.playlists = playlist.playlists?.items ?? [Playlist<PlaylistItemsReference>]()
        }).store(in: &cancellables)
    }
}


struct LibraryView_Previews: PreviewProvider {
    static let spotify = Spotify()
    
    static var previews: some View {
        NavigationStack {
            LibraryView()
                .environmentObject(spotify)
        }
    }
}
