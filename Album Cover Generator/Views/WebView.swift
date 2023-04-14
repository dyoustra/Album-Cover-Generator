//
//  WebView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 3/1/23.
//

import SwiftUI
import SafariServices

struct WebView: UIViewControllerRepresentable {
 
    var url: URL
 
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
 
    func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {
        
    }
}
