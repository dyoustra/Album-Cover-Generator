//
//  AuthorizeViewModel.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 2/24/23.
//

import Foundation
import SpotifyWebAPI
import Combine

class AuthorizeViewModel: ObservableObject {
    
    let spotify = SpotifyAPI(authorizationManager: AuthorizationCodeFlowPKCEManager(
        clientId: "89a6bb6fe2b046589fbd1e4dc3623ef4"
        )
    )
    let redirectURL = URL(string: "album-cover-generator-spotify-auth://callback")!
    var cancellations: [AnyCancellable] = []
    @Published var authorized = false
    
    // uses Authorization Code Flow with Proof Key for Code Exchange (can't put client secret on a public repo)
    // https://github.com/Peter-Schorn/SpotifyAPI#supported-platforms
    func AuthorizeSpotify() {
        let codeVerifier = String.randomURLSafe(length: 128)
        let codeChallenge = String.makeCodeChallenge(codeVerifier: codeVerifier)
        let state = String.randomURLSafe(length: 128)
        
        // https://peter-schorn.github.io/SpotifyAPI/documentation/spotifywebapi/authorizationcodeflowpkcebackendmanager/makeauthorizationurl(redirecturi:codechallenge:state:scopes:)/
        let authorizationURL = spotify.authorizationManager.makeAuthorizationURL(
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
        
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: redirectURL,
            // Must match the code verifier that was used to generate the
            // code challenge when creating the authorization URL.
            codeVerifier: codeVerifier,
            // Must match the value used when creating the authorization URL.
            state: state
        )
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    print("successfully authorized")
                    self.authorized = true
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
