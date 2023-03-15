//
//  AuthorizeView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import SwiftUI
import Combine

struct AuthorizeView: View {
    @ObservedObject var spotify : Spotify
    var body: some View {
        VStack(spacing: 30.0) {
            Button(action: {
                spotify.authorize()
            }, label: {
                Image(systemName: "music.note.list")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Connect with Spotify")
            })
            if (spotify.isAuthorized) {
                Image(systemName: "person.crop.circle.badge.checkmark")
            } else {
                Image(systemName: "person.crop.circle.badge.questionmark")
            }

        }
        .popover(isPresented: $spotify.isPresentingWebView) {
            WebView(url: spotify.authorizationURL!)
                .interactiveDismissDisabled(true)
        }
    }
}

