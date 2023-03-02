//
//  AuthorizeViewModel.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import Foundation
import SpotifyWebAPI
import Combine
import UIKit

class AuthorizeViewModel: ObservableObject {
    
    private let spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowPKCEManager(
        clientId: "89a6bb6fe2b046589fbd1e4dc3623ef4"
        )
    )
    private let redirectURL = URL(string: "album-cover-generator-spotify-auth://callback")!
    private var cancellations: [AnyCancellable] = []
    @Published var isPresentingWebView = false {
        didSet {
            print("presenting web view: \(self.isPresentingWebView)")
        }
    }
    @Published var authorizationURL = URL(string: "") {
        didSet {
            self.isPresentingWebView = true
        }
    }
    private var codeVerifier    = ""
    private var codeChallenge   = ""
    private var state           = ""
    
    // uses Authorization Code Flow with Proof Key for Code Exchange (can't put client secret on a public repo)
    // https://github.com/Peter-Schorn/SpotifyAPI#supported-platforms
    func AuthorizeSpotify() {
        self.codeVerifier = String.randomURLSafe(length: 128)
        self.codeChallenge = String.makeCodeChallenge(codeVerifier: self.codeVerifier)
        self.state = String.randomURLSafe(length: 128)
        // https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkcebackendmanager/makeauthorizationurl(redirecturi:codechallenge:state:scopes:)/
        self.authorizationURL = spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: redirectURL,
            codeChallenge: codeChallenge,
            state: state,
            scopes: [
                .ugcImageUpload,
                .playlistReadPrivate,
                .playlistReadCollaborative,
                .playlistModifyPrivate,
                .playlistModifyPublic,
                .userReadPrivate,
                .userLibraryRead
            ]
        )!
        
        self.objectWillChange.send()
    }
    
    func checkAuthorization() {
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: self.redirectURL,
            // Must match the code verifier that was used to generate the
            // code challenge when creating the authorization URL.
            codeVerifier: self.codeVerifier,
            // Must match the value used when creating the authorization URL.
            state: self.state
        )
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    print("successfully authorized")
                case .failure(let error):
                    if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                        print("The user denied the authorization request")
                    }
                    else {
                        print("couldn't authorize application: \(error)")
                    }
            }
        })
        .store(in: &cancellations)
    }
}
