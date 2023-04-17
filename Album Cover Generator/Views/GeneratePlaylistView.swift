//
//  GeneratePlaylistView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 4/15/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct GeneratePlaylistView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var spotify: Spotify

    let coverImage: Image
    let playlistCollection: Playlist<PlaylistItemsReference>

    @State var showOptions : Bool = false

    @State var deselectedSongs: [Int] = []

    @State var tracks : [Track] = []


    @State private var toggles: [Bool] = [false, false, false, false, false, false, false]

    @State private var cancellables: Set<AnyCancellable> = []
    @State private var loadingTracks : Bool = true
    @State private var couldntLoadTracks : Bool = false

    @State private var displayGenerateSheet : Bool = false

    var body: some View {
        ScrollView {
            VStack {
                coverImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
                    .shadow(radius: 20)
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
                    .presentationDetents([.height(UIScreen.main.bounds.size.height/2.25)])
                }

                Spacer()

                Button(action: {
                    displayGenerateSheet = true
                }) {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .bold()
                }
                .background(Color.primary)
                .cornerRadius(10)
                .sheet(isPresented: self.$displayGenerateSheet) {
                    if #available(iOS 16.2, *) {
                        StableDiffusionView()
                    } else {
                        // Fallback on earlier versions
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
                                    .shadow(radius: self.deselectedSongs.contains(track.hashValue) ? 10 : 0)
                                Text(track.name)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(self.deselectedSongs.contains(track.hashValue) ? .gray : .primary)
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

