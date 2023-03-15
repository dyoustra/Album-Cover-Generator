//
//  Spotify.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/14/23.
//

import Foundation
import Combine
import UIKit
import KeychainAccess
import SpotifyWebAPI

final class Spotify: ObservableObject {

    private static let clientId: String = "89a6bb6fe2b046589fbd1e4dc3623ef4"


    static let authorizationManagerKey = "authorizationManager"

    static let redirectURL = URL(string: "album-cover-generator://authorize-view")!
    static var redirectURIWithQuery = URL(string: "album-cover-generator://authorize-view")!

    @Published var isPresentingWebView = false {
        didSet {
            if isPresentingWebView == false {
                checkAuthorization()
            }
        }
    }


    var authorizationState = String.randomURLSafe(length: 128)
    private var codeVerifier    = ""
    private var codeChallenge   = ""

    @Published var isAuthorized = false

    private let keychain = Keychain(service: "Danny.Album-Cover-Generator")

    let api = SpotifyAPI(authorizationManager: AuthorizationCodeFlowPKCEManager(
        clientId: "89a6bb6fe2b046589fbd1e4dc3623ef4"
        )
    )

    @Published var authorizationURL = URL(string: "") {
        didSet {
            self.isPresentingWebView = true
        }
    }

    var cancellables: [AnyCancellable] = []

    init() {
        print("mhm buddy")
        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are updating the
            // @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)

        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)

        // Check to see if the authorization information is saved in the
        // keychain.
        if let authManagerData = keychain[data: Self.authorizationManagerKey] {
            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowPKCEManager.self,
                    from: authManagerData
                )

                self.api.authorizationManager = authorizationManager

            } catch {
                print("could not decode authorizationManager from data:\n\(error)")
            }
        }
        else {
            print("did not find authorization information in keychain")
        }

    }

    func updateRedirectURIWithQuery(url: URL) {
        Spotify.redirectURIWithQuery = url
    }

    func authorize() {
        self.codeVerifier = String.randomURLSafe(length: 128)
        self.codeChallenge = String.makeCodeChallenge(codeVerifier: self.codeVerifier)
        self.authorizationState = String.randomURLSafe(length: 128)
        authorizationURL = api.authorizationManager.makeAuthorizationURL(
            redirectURI: Spotify.redirectURL,
            codeChallenge: codeChallenge,
            state: authorizationState,
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
        api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: Spotify.redirectURIWithQuery,
            // Must match the code verifier that was used to generate the
            // code challenge when creating the authorization URL.
            codeVerifier: self.codeVerifier,
            // Must match the value used when creating the authorization URL.
            state: self.authorizationState
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
        .store(in: &cancellables)
    }

    func authorizationManagerDidChange() {
        print("yessir bruh")
        // Update the @Published `isAuthorized` property.
        self.isAuthorized = self.api.authorizationManager.isAuthorized()

        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(self.api.authorizationManager)

            // Save the data to the keychain.
            self.keychain[data: Self.authorizationManagerKey] = authManagerData

        } catch {
            print(
                "couldn't encode authorizationManager for storage in the " +
                "keychain:\n\(error)"
            )
        }

    }


    func authorizationManagerDidDeauthorize() {

        self.isAuthorized = false

        do {

            try self.keychain.remove(Self.authorizationManagerKey)
            print("did remove authorization manager from keychain")

        } catch {
            print(
                "couldn't remove authorization manager from keychain: \(error)"
            )
        }
    }

}
