//
//  GenerateView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/13/23.
//

import SwiftUI
import SpotifyWebAPI
import StableDiffusion
import CoreML
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

struct GenerateOverlay : View {
    var state: Binding<GenerationState>
    @Binding var generateProgress : Double
    
    var body: some View {
        switch state.wrappedValue {
        case .startup: return AnyView(EmptyView())
        case .running(let progress):
            guard let progress = progress, progress.stepCount > 0 else {
                // The first time it takes a little bit before generation starts
                return AnyView(ProgressView())
            }
            let step = Int(progress.step) + 1
            return AnyView(
                VStack {
                    ProgressBar(percent: $generateProgress)
                        .onChange(of: step) { step in
                            print(step)
                            generateProgress = Double(step) / Double(progress.stepCount)
                        }
                }
            )
        case .complete( _, _, _, _):
            return AnyView(EmptyView())
        case .failed(_):
            return AnyView(Text("Failed"))
        case .userCanceled:
            return AnyView(Text("Cancelled"))
        }
    }
}

let model = ModelInfo.v2Base

@available(iOS 16.2, *)
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
    
    @State var loadingPipeline = true
    
    @StateObject var generation = GenerationContext()

    @State private var preparationPhase = "Downloading Files"
    @State private var downloadProgress: Double = 0
    @State private var generateProgress: Double = 0
    
    enum CurrentView {
        case loading
        case textToImage
        case error(String)
    }
    @State private var currentView: CurrentView = .loading
    
    @State private var stateSubscriber: Cancellable?
    
    @State var generatedImage = Image("App Logo (AI Music Covers)")
    
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
                        submit()
                    }
                }) {
                    Text(loadingPipeline ? preparationPhase : "Generate")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .bold()
                }
                .background(generatePressed || loadingPipeline ? Color.secondary : Color.primary)
                .cornerRadius(10)
                .disabled(generatePressed || loadingPipeline)
                .navigationDestination(isPresented: $displayCompletedView) {
                    if let album = collection as? Album {
                        CompletedView(generatedImage: generatedImage, collectionName: album.name, isPlaylist: false, displayCompletedView: $displayCompletedView)
                    } else if let playlist = collection as? Playlist<PlaylistItemsReference> {
                        CompletedView(generatedImage: generatedImage, collectionName: playlist.name, isPlaylist: true, displayCompletedView: $displayCompletedView)
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
                            TrackView(coverImage: coverImage, track: track, deselectedSongs: $deselectedSongs, generatePressed: $generatePressed)
                        }
                    }
                }
            }
            .scaledToFit()
            .listStyle(.inset)
        }
        .navigationBarItems(trailing:
            VStack {
                if (generatePressed && generateProgress == 0) {
                    Button("Cancel") {
                        withAnimation(.linear) {
                            generation.cancelGeneration()
                            generatePressed = false
                        }
                    }
                    .foregroundColor(.red)
                    .bold()
                } else {
                    Button("Options") {
                        showOptions = true
                    }
                    .disabled(generatePressed)
                }
            }
        )
        .onAppear {
            generateProgress = 0
            if !isPlaylist {
                retrieveAlbumTracks()
            } else {
                retrievePlaylistTracks()
            }
            
            Task.init {
                let loader = PipelineLoader(model: model)
                stateSubscriber = loader.statePublisher.sink { state in
                    DispatchQueue.main.async {
                        loadingPipeline = true
                        switch state {
                        case .downloading(let progress):
                            preparationPhase = "Downloading Files"
                            downloadProgress = progress
                        case .uncompressing:
                            preparationPhase = "Uncompressing Files"
                            downloadProgress = 1
                        case .readyOnDisk:
                            preparationPhase = "Loading Files"
                            downloadProgress = 1
                        default:
                            break
                        }
                    }
                }
                do {
                    generation.pipeline = try await loader.prepare()
                    loadingPipeline = false
                } catch {
                    
                }
            }
            
        }
        .overlay(
            VStack {
                Spacer()
                GenerateOverlay(state: $generation.state, generateProgress: $generateProgress)
                if loadingPipeline {
                    Spacer()
                        .padding(.all)
                    switch currentView {
                    case .error(_): Text("Error")
                        case .loading:
                        // TODO: Don't present progress view if the pipeline is cached
                            ProgressBar(percent: $downloadProgress)
                    case .textToImage: EmptyView()

                    }
                }
            }
        )
    }
    
    func submit() {
        if let albumCollection = collection as? Album {
            generation.positivePrompt = albumCollection.name + " " + (albumCollection.artists?.first?.name ?? "")
        } else if let playlistCollection = collection as? Playlist<PlaylistItemsReference> {
            generation.positivePrompt = playlistCollection.name + " " + (playlistCollection.owner?.displayName ?? "")
        }
        
        generation.positivePrompt += " Music Cover"
        
        if case .running = generation.state { return }
        Task {
            generation.state = .running(nil)
            do {
                let result = try await generation.generate()
                generation.state = .complete(generation.positivePrompt, result.image, result.lastSeed, result.interval)
                if let image = result.image {
                    generatedImage = Image(uiImage: UIImage(cgImage: image))
                    displayCompletedView = true
                    generatePressed = false
                }
            } catch {
                generation.state = .failed(error)
            }
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

struct TrackView : View {
    let coverImage : Image
    let track : Track
    
    @Binding var deselectedSongs : [Int]
    @Binding var generatePressed : Bool
    
    var body: some View {
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
                            updateTrackSelection()
                        }
                    }
            } else if !generatePressed {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            updateTrackSelection()
                        }
                    }
            }
        }
        Divider()
    }
    
    func updateTrackSelection() {
        if self.deselectedSongs.contains(track.hashValue) {
            self.deselectedSongs.remove(at: self.deselectedSongs.firstIndex(of: track.hashValue)!)
        } else {
            self.deselectedSongs.append(track.hashValue)
        }
    }
}

