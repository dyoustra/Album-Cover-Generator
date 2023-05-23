//
//  AuthorizeView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import SwiftUI
import Combine
import Neumorphic

struct AuthorizeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var spotify: Spotify
    
    @State var displayLibraryView : Bool = false
    
    var primary = Color(red: 255/255, green: 200/255, blue: 200/255)
    var secondary = Color(red: 255/255, green: 215/255, blue: 202/255)
    var tertiary = Color(red: 255/255, green: 142/255, blue: 106/255)
    
    var body: some View {
        VStack {
            if displayLibraryView {
                VStack {
                    LibraryView().environmentObject(spotify).navigationBarBackButtonHidden()
                }
            } else {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.white, tertiary]), startPoint: .bottom, endPoint: .top)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 30.0) {
                        
                        VStack(alignment: .center) {
                            Text("AI Music Covers")
                                .padding(10)
                                .font(.largeTitle)
                                .bold()
                            
                            Text("Generate a Cover for your Favorite Spotify Albums and Playlists using AI")
                                .padding(5)
                                .multilineTextAlignment(.center)
                                .font(.headline)
                                .bold()
                        }
                        .foregroundColor(.black)
                        
                        VStack {
                            Image("App Logo (AI Music Covers)")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .padding(10)
                            HStack {
                                Image("ARHOM2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                                Image("ARHOM1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                                Image("ARHOM3")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(10)
                            }
                            .padding(10)
                        }
                        
                        Button(action: {
                            spotify.authorize()
                        }) {
                            Text("Login with Spotify")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .foregroundColor(.black)
                                .bold()
                        }
                        .background(Color("SpotifyGreen"))
                        .cornerRadius(10)
                        .padding(10)
                        .onChange(of: spotify.isAuthorized) { _ in
                            withAnimation(.easeIn) {
                                displayLibraryView = true
                            }
                        }
                        
                        Text(spotify.isAuthorized ? "Yes" : "No")
                        
                    }
                    .popover(isPresented: $spotify.isPresentingWebView) {
                        WebView(url: spotify.authorizationURL!)
                            .interactiveDismissDisabled(true)
                    }
                    .padding()
                }
            }
        }
    }
}

