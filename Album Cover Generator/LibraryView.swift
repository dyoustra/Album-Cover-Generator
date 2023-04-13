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
    
    var body: some View {
        List {
            Group {
                NavigationLink("Saved Albums") {
                    MusicCollectionListView(collectionType: .Albums).environmentObject(spotify)
                }
                NavigationLink("Saved Playlists") {
                    MusicCollectionListView(collectionType: .Playlists).environmentObject(spotify)
                }
            }
            .frame(height: 70.0)
        }
        .font(.title)
        .listStyle(.insetGrouped)
        .navigationTitle("My Library")
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
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: getUserInfo)
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
