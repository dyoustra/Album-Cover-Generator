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
import SpotifyExampleContent
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
    }
}

struct InfoView: View {
    let collection: Any
    @Binding var optionToggles: [Bool]
    @Binding var showOptions: Bool
    @EnvironmentObject var spotify: Spotify
    
    let vStackSpacing = 5.0
    
    @State var artistImage = Image(systemName: "music.mic")
    @State var cancellables: [AnyCancellable] = []

    var body: some View {
        if let album = collection as? Album {
            VStack(spacing: vStackSpacing) {
                Text(album.name)
                    .font(.largeTitle)
                    .lineLimit(3)
                    .bold()
                HStack {
                    artistImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(artistImage == Image(systemName: "music.mic") ? AnyShape(Rectangle()) : AnyShape(Circle()))
                        .onReceive(spotify.api.getFromHref(album.artists!.first!.href!, responseType: Artist.self).assertNoFailure().receive(on: DispatchQueue.main), perform: { artist in
                            artist.images?.largest?.load().assertNoFailure().receive(on: DispatchQueue.main).sink(receiveValue: { image in
                                artistImage = image
                            }).store(in: &cancellables)
                        })
                    ForEach(album.artists ?? [Artist(name: "No Artist")], id: \.id) { artist in
                        Text(artist.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.secondary)
                .frame(height: 30)
                .sheet(isPresented: $showOptions) {
                    OptionsView(isPlaylist: false, toggles: $optionToggles, showOptions: $showOptions)
                }
            }
            
        } else if let playlist = collection as? Playlist<PlaylistItemsReference> {
            VStack(spacing: vStackSpacing) {
                Text(playlist.name)
                    .font(.largeTitle)
                    .bold()
                HStack {
                    artistImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(artistImage == Image(systemName: "music.mic") ? AnyShape(Rectangle()) : AnyShape(Circle()))
                        .onReceive(spotify.api.getFromHref(playlist.owner!.href, responseType: SpotifyUser.self).assertNoFailure().receive(on: DispatchQueue.main), perform: { user in
                            user.images?.largest?.load().assertNoFailure().receive(on: DispatchQueue.main).sink(receiveValue: { image in
                                artistImage = image
                            }).store(in: &cancellables)
                        })
                    
                    Text(playlist.owner?.displayName ?? "Unknown Owner")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
                .frame(height: 30)
                .sheet(isPresented: $showOptions) {
                    OptionsView(isPlaylist: true, toggles: $optionToggles, showOptions: $showOptions)
                }
            }
        }
    }
}

struct TrackItem: Identifiable {
    let spotifyTrack: Track
    var enabled = true
    var image: Image
    
    init(_ spotifyTrack: Track, image: Image) {
        self.spotifyTrack = spotifyTrack
        self.image = image
    }
    
    var id: String {
        spotifyTrack.id ?? spotifyTrack.name
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

struct GenerateView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotify : Spotify
    
    // VIEW ARGUMENTS
    let coverImage: Image
    let collection: Any
    let isPlaylist: Bool
    
    // Track, then is that track enabled
    @State var tracks: [TrackItem] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var loadingTracks: Bool = true
    @State private var couldntLoadTracks: Bool = false

    @State var showOptions : Bool = false
    @State private var optionToggles: [Bool] = Array(repeating: true, count: GenerationOptions.allCases.count)
    
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
        ScrollView(showsIndicators: true) {
            VStack() {
                coverImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
                    .shadow(radius: 20)
                
                InfoView(collection: collection, optionToggles: $optionToggles, showOptions: $showOptions)
                
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
                
                Divider()
                
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
                else {
                    VStack {
                        ForEach($tracks) { $track in
                            Toggle(isOn: $track.enabled) {
                                HStack {
                                    track.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(10)
                                        .frame(width: 70, height: 70)
                                        .shadow(radius: track.enabled || generatePressed ? 10 : 0)
                                    Text(track.spotifyTrack.name)
                                        .foregroundColor(!track.enabled || generatePressed ? .secondary : .primary)
                                        .lineLimit(3)
                                    if (track.spotifyTrack.isExplicit) {
                                        Image(systemName: "e.square.fill")
                                            .foregroundColor(!track.enabled || generatePressed ? .secondary : .primary)
                                    }
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
            .padding(.all)
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
                    tracks.append(TrackItem(item, image: coverImage))
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
                        var newTrack = TrackItem(trackItem, image: coverImage)
                        newTrack.spotifyTrack.album!.images!.largest!.load().assertNoFailure().receive(on: DispatchQueue.main).sink { image in
                            newTrack.image = image
                            tracks.append(newTrack)
                        }.store(in: &cancellables)
                        
                    }
                }

            }

            )
            .store(in: &cancellables)
        }
    }
}

struct GenerateView_Previews: PreviewProvider {
    static let spotify = Spotify()
    static let album = Album.darkSideOfTheMoon
    static let playlist = Playlist<PlaylistItemsReference>.thisIsMFDoom
    static var image = Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
    
    static var loadImageCancellable: AnyCancellable? = nil
    
    static var previews: some View {
        NavigationView {
            GenerateView(
                coverImage: image,
                collection: album,
                isPlaylist: false
            )
            .environmentObject(spotify)
            .onAppear {
                loadImage()
            }
        }
    }
    
    static func loadImage() {
        
        // or playlist.Playlist<PlaylistItemsReference>
        let spotifyImage = album.images!.largest!
        
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
