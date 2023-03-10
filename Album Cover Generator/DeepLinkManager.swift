//
//  DeepLinkManager.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 3/1/23.
//

import Foundation

class DeepLinkManager {

    enum DeeplinkTarget: Equatable {
        case authorizeView
        case home
    }

    class DeepLinkConstants {
        static let scheme = "album-cover-generator"
        static let authorizeQuery = "authorize-view"
    }

    func manage(_ url: URL) -> DeeplinkTarget {
        let urlName = url.absoluteString
        let urlArray = urlName.components(separatedBy: "/")

        for value in urlArray {
            switch value {
            case DeepLinkConstants.authorizeQuery:
                return .authorizeView
            default:
                continue
            }
        }

        return .home

    }
}
