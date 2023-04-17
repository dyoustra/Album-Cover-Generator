//
//  GenerateView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/13/23.
//

import SwiftUI
import SpotifyWebAPI

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
                case .Song_Duration,
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
    
    let coverImage: Image
    let albumCollection: Album
//    let playlistCollection: Playlist<PlaylistItemsReference>

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
                            Button(action: {
                                toggles[option.ordinal()].toggle()
                            }) {
                                HStack {
                                    Text(option.rawValue.replacingOccurrences(of: "_", with: " "))
                                    if (toggles[option.ordinal()]) {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }

                            }
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
                    .presentationDetents([.height(325)])
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
                ForEach(albumCollection.tracks?.items ?? [Track(name: "No Tracks Available", isLocal: true, isExplicit: true)], id: \.id) { track in
                    HStack {
                        coverImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .frame(width: 70, height: 70)
                            .shadow(radius: self.deselectedSongs.contains(track.hashValue) ? 20 : 0)
                        Text(track.name)
                            .foregroundColor(self.deselectedSongs.contains(track.hashValue) ? .gray : .primary)
                        Spacer()
                        Button(action: {
                            if self.deselectedSongs.contains(track.hashValue) {
                                self.deselectedSongs.remove(at: self.deselectedSongs.firstIndex(of: track.hashValue)!)
                            } else {
                                self.deselectedSongs.append(track.hashValue)
                            }
                        }) {
                            self.deselectedSongs.contains(track.hashValue) ? Image(systemName: "plus").foregroundColor(.blue) : Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .shadow(radius: self.deselectedSongs.contains(track.hashValue) ? 10 : 0)
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
    }
}

//struct GenerateView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            GenerateView(coverImage: Image(systemName: "square.fill"))
//        }
//    }
//}
