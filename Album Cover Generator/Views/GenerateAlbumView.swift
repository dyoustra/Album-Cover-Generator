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

struct GenerateAlbumView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotify : Spotify
    
    let coverImage: Image
    let albumCollection: Album
    
    @State var tracks : [Track] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var loadingTracks : Bool = true
    @State private var couldntLoadTracks : Bool = false

    @State var showOptions : Bool = false

    @State var deselectedSongs: [Int] = []

    
    @State private var toggles: [Bool] = [false, false, false, false, false, false, false]
    
    var body: some View {
        ScrollView {
            VStack {
                coverImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
                    .shadow(radius: 20)
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
                    VStack {
                        ForEach(GenerationOptions.allCases.filter({ option in
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
                    .presentationDetents([.height(UIScreen.main.bounds.height/2.25)])
                }

                Spacer()

                Button(action: {

                }) {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .bold()
                }
                .background(Color.primary)
                .cornerRadius(10)
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
                                    .shadow(radius: self.deselectedSongs.contains(track.hashValue) ? 10 : 0)
                                Text(track.name)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(self.deselectedSongs.contains(track.hashValue) ? .gray : .primary)
                                if (track.isExplicit) {
                                    Image(systemName: "e.square.fill")
                                }
                                Spacer()
                                if self.deselectedSongs.contains(track.hashValue) {
                                    Image(systemName: "plus")
                                        .foregroundColor(.blue)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                updateTrackSelection(track: track)
                                            }
                                        }
                                } else {
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
                                Button("Options") {
                showOptions = true
            }
        )
        .onAppear {
            retrieveTracks()
        }
    }
    
    func updateTrackSelection(track : Track) {
        if self.deselectedSongs.contains(track.hashValue) {
            self.deselectedSongs.remove(at: self.deselectedSongs.firstIndex(of: track.hashValue)!)
        } else {
            self.deselectedSongs.append(track.hashValue)
        }
    }
    
    func retrieveTracks() {
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
