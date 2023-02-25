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
        if model.authorized {
            VStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .imageScale(.large)
                Text("AUTHORIZED LFG")
            }
        }
        VStack {
            Button(action: {
                model.AuthorizeSpotify()
            }, label: {
                Image(systemName: "music.note.list")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Connect with Spotify")
            })
        }
        .padding()
    }
}

struct AuthorizeView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizeView()
    }
}
