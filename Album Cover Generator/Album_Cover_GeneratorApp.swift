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
    @ObservedObject var model = AuthorizeViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                switch self.deeplinkTarget {
                case .home:
                    Home()
                case .authorizeView:
                    AuthorizeView(model: model)
                case .none:
                    AuthorizeView(model: model)
                }
            }
            .onOpenURL { url in
                let deepLinkManager = DeepLinkManager()
                let deepLink = deepLinkManager.manage(url)
                self.deeplinkTarget = deepLink

                switch self.deeplinkTarget {
                case .authorizeView:
                    model.updateRedirectURIWithQuery(url: url)
                    break
                default:
                    break
                }
                model.isPresentingWebView = false
            }
        }
    }
}
