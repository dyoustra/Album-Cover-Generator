//
//  Album_Cover_GeneratorApp.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import SwiftUI

@main
struct Album_Cover_GeneratorApp: App {

    @State var deeplinkTarget: DeepLinkManager.DeeplinkTarget?
    @ObservedObject var spotify = Spotify()

    var body: some Scene {
        WindowGroup {
            Group {
                switch self.deeplinkTarget {
                case .home:
                    Home()
                case .authorizeView:
                    AuthorizeView(spotify: spotify)
                case .none:
                    AuthorizeView(spotify: spotify)
                }
            }
            .onOpenURL { url in
                let deepLinkManager = DeepLinkManager()
                let deepLink = deepLinkManager.manage(url)
                self.deeplinkTarget = deepLink

                switch self.deeplinkTarget {
                case .authorizeView:
                    spotify.updateRedirectURIWithQuery(url: url)
                    break
                default:
                    break
                }
                spotify.isPresentingWebView = false
            }
        }
    }
}
