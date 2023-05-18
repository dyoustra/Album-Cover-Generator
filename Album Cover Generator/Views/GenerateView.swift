//
//  GenerateView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/13/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine

enum GenerationOptions: String, CaseIterable, Identifiable {
    case Song_Titles
    case Song_Duration
    case Album_Name
    /// Name of the creator of the Album, or the creator of the playlist
    case Artist_Name
    /// Names of the individual song artists. Used only for playlists
    case Song_Artist_Names
    /// Album Covers of the individual songs. Used only for playlists.
    case Song_Album_Covers
    
    func playlistOnly() -> Bool {
        switch self {
                case .Song_Artist_Names,
                     .Song_Album_Covers:
                return true
            default:
                return false
        }
    }
    
    func ordinal() -> Int {
        return Self.allCases.firstIndex(of: self)!
    }
    
    var id: Self {
        self
    }
}

struct OptionsView: View {
    var isPlaylist : Bool
    
    @Binding var toggles : [Bool]
    @Binding var showOptions : Bool
    
    var body: some View {
        VStack {
            Text("Options")
                .font(.title3)
                .bold()
                .padding()
            ForEach(isPlaylist ? GenerationOptions.allCases : GenerationOptions.allCases.filter({ option in
                !option.playlistOnly()
            })) { option in
                Toggle(option.rawValue.replacingOccurrences(of: "_", with: " "), isOn: $toggles[option.ordinal()])
                .padding()
                .foregroundColor(.primary)
                .bold()
                Divider()
            }

            Button(action: {
                self.showOptions = false
            }) {
                Text("Done")
                    .bold()
                    .padding(10)
            }
        }
        .presentationDetents(isPlaylist ? [.height(UIScreen.main.bounds.size.height/1.5)] : [.height(UIScreen.main.bounds.size.height/2.15)])
        .interactiveDismissDisabled()
    }
}

struct GenerateView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotify : Spotify
    
    let coverImage: Image
    
    let collection: Any
    let isPlaylist: Bool
    
    
    @State var tracks : [Track] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var loadingTracks : Bool = true
    @State private var couldntLoadTracks : Bool = false

    @State var showOptions : Bool = false

    @State var deselectedSongs: [Int] = []

    
    @State private var toggles: [Bool] = [false, false, false, false, false, false, false]
    
    @State var generatePressed = false
    @State var displayCompletedView = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                coverImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
                    .shadow(radius: 20)
                if let albumCollection = collection as? Album {
                    Text(albumCollection.name)
                        .font(.largeTitle)
                        .bold()
                    HStack {
                        Image(systemName: "music.mic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        ForEach(albumCollection.artists ?? [Artist(name: "No Artist")], id: \.id) { artist in
                            Text(artist.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.secondary)
                        }
                    }
                    .frame(height: 30)
                    .sheet(isPresented: $showOptions) {
                        OptionsView(isPlaylist: false, toggles: $toggles, showOptions: $showOptions)
                    }
                } else if let playlistCollection = collection as? Playlist<PlaylistItemsReference> {
                    Text(playlistCollection.name)
                        .font(.largeTitle)
                        .bold()
                    HStack {
                        Image(systemName: "music.mic")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Text(playlistCollection.owner?.displayName ?? "Your Playlist")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondary)
                    }
                    .frame(height: 30)
                    .sheet(isPresented: $showOptions) {
                        OptionsView(isPlaylist: true, toggles: $toggles, showOptions: $showOptions)
                    }
                }
                
                Spacer()

                Button(action: {
                    withAnimation(.linear) {
                        generatePressed = true
                    }
                }) {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .bold()
                }
                .background(generatePressed ? Color.secondary : Color.primary)
                .cornerRadius(10)
                .disabled(generatePressed)
                .navigationDestination(isPresented: $displayCompletedView) {
                    if let album = collection as? Album {
                        CompletedView(coverImage: coverImage, collectionName: album.name, isPlaylist: false, displayCompletedView: $displayCompletedView)
                    } else if let playlist = collection as? Playlist<PlaylistItemsReference> {
                        CompletedView(coverImage: coverImage, collectionName: playlist.name, isPlaylist: true, displayCompletedView: $displayCompletedView)
                    }
                }
            }
            .padding(.all)
            
            List {
                if loadingTracks {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Tracks")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadTracks {
                    Text("Couldn't Load Tracks")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else if !loadingTracks {
                    VStack {
                        ForEach(tracks, id: \.id) { track in
                            HStack {
                                coverImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                                    .frame(width: 70, height: 70)
                                    .shadow(radius: self.deselectedSongs.contains(track.hashValue) || generatePressed ? 10 : 0)
                                Text(track.name)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(self.deselectedSongs.contains(track.hashValue) || generatePressed ? .gray : .primary)
                                if (track.isExplicit) {
                                    Image(systemName: "e.square.fill")
                                        .foregroundColor(self.deselectedSongs.contains(track.hashValue) || generatePressed ? .gray : .primary)
                                }
                                Spacer()
                                if self.deselectedSongs.contains(track.hashValue) && !generatePressed {
                                    Image(systemName: "plus")
                                        .foregroundColor(.blue)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                updateTrackSelection(track: track)
                                            }
                                        }
                                } else if !generatePressed {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                updateTrackSelection(track: track)
                                            }
                                        }
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
            .scaledToFit()
            .listStyle(.inset)
        }
        .navigationBarItems(trailing:
            VStack {
                if (generatePressed) {
                    Button("Cancel") {
                        withAnimation(.linear) {
                            generatePressed = false
                        }
                    }
                    .foregroundColor(.red)
                    .bold()
                } else {
                    Button("Options") {
                        showOptions = true
                    }
                }
            }
        )
        .onAppear {
            if !isPlaylist {
                retrieveAlbumTracks()
            } else {
                retrievePlaylistTracks()
            }
        }
        .overlay(
            VStack {
                if generatePressed {
                    Spacer()
                    ProgressBar(displayNextView: $displayCompletedView, generatePressed: $generatePressed)
                        .padding(.all)
                }
            }
        )
    }
    
    func updateTrackSelection(track : Track) {
        if self.deselectedSongs.contains(track.hashValue) {
            self.deselectedSongs.remove(at: self.deselectedSongs.firstIndex(of: track.hashValue)!)
        } else {
            self.deselectedSongs.append(track.hashValue)
        }
    }
    
    func retrieveAlbumTracks() {
        if let albumCollection = collection as? Album {
            spotify.api.albumTracks(albumCollection.uri!).sink(receiveCompletion: { completion in
                self.loadingTracks = false
                switch completion {
                    case .finished:
                        self.couldntLoadTracks = false
                    case .failure(_):
                        self.couldntLoadTracks = true
                }
            }, receiveValue: { albumItems in
                let items = albumItems.items
                for item in items {
                    tracks.append(item)
                }
            }

            )
            .store(in: &cancellables)
        }
    }
    
    func retrievePlaylistTracks() {
        if let playlistCollection = collection as? Playlist<PlaylistItemsReference> {
            spotify.api.playlistTracks(playlistCollection.uri).sink(receiveCompletion: { completion in
                self.loadingTracks = false
                switch completion {
                    case .finished:
                        self.couldntLoadTracks = false
                    case .failure(_):
                        self.couldntLoadTracks = true
                }
            }, receiveValue: { playlistItems in
                let items = playlistItems.items
                for item in items {
                    let track = item.item
                    if let trackItem = track {
                        tracks.append(trackItem)
                    }
                }

            }

            )
            .store(in: &cancellables)
        }
    }
}
