//
//  Album_Cover_GeneratorApp.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import SwiftUI
import Combine

@main
struct Album_Cover_GeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView().environmentObject(Spotify())
            }
        }
    }
}

struct RootView: View {
    
    @State var deeplinkTarget: DeepLinkManager.DeeplinkTarget?
    @EnvironmentObject var spotify: Spotify
    
    var body: some View {
        if (spotify.isAuthorized) {
            LibraryView()
        } else {
            Group {
                switch self.deeplinkTarget {
                case .home:
                    Home()
                case .authorizeView:
                    AuthorizeView()
                case .none:
                    AuthorizeView()
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

let runningOnMac = ProcessInfo.processInfo.isMacCatalystApp
