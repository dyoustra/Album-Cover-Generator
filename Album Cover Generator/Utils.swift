//
//  Utils.swift
//  StableDiffusionApp
//
//  Created by Rehan Parwani on 5/19/23.
//

import Foundation

extension String: Error {}

extension Double {
    func formatted(_ format: String) -> String {
        return String(format: "\(format)", self)
    }
}
