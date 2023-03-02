//
//  AuthorizeView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import SwiftUI

struct AuthorizeView: View {
    @ObservedObject var model = AuthorizeViewModel()
    var body: some View {
        VStack(spacing: 30.0) {
            Button(action: {
                model.AuthorizeSpotify()
            }, label: {
                Image(systemName: "music.note.list")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Connect with Spotify")
            })
            Button {
                model.checkAuthorization()
            } label: {
                Image(systemName: "person.crop.circle.badge.questionmark")
                Text("Check authorization")
            }

        }
        .sheet(isPresented: $model.isPresentingWebView) {
            WebView(url: model.authorizationURL!)
        }
    }
}

struct AuthorizeView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizeView()
    }
}
