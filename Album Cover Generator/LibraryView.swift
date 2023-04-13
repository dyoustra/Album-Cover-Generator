//
//  LibraryView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/12/23.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var spotify: Spotify
    @State private var logOutAlert = false
    
    var body: some View {
        List {
            Group {
                NavigationLink("Albums") {
                    
                }
                
                NavigationLink("Playlists") {
                    UserPlaylistsView().environmentObject(spotify)
                }
            }
            .frame(height: /*@START_MENU_TOKEN@*/70.0/*@END_MENU_TOKEN@*/)
        }
        .font(.title)
        .listStyle(.insetGrouped)
        .navigationTitle("My Library")
        // can i get the toolbar inline with the navigationTitle?
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    logOutAlert = true
                }, label: {
                    Image(systemName: "person.crop.circle.badge.minus")
                })
            }
        }
        .alert("AY!", isPresented: $logOutAlert) {
            Button("Log Out", role: .destructive) {
                spotify.authorizationManagerDidDeauthorize()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView()
        }
    }
}
