//
//  TextToImageView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 5/19/23.
//

import SwiftUI

@available(iOS 16.2, *)
struct TextToImageView: View {
    static let negativePrompt =
    """
    lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits,
     cropped, worst quality, low quality, normal quality, jpeg artifacts, blurry, multiple legs, malformation
    """
    
    @ObservedObject var imageGenerator: ImageGenerator
    @State var generationParameter : ImageGenerator.GenerationParameter
    var body: some View {
        ScrollView {
            VStack {
                Text("Text to image").font(.title3).bold().padding(6)
                Text("Sample App using apple/ml-stable-diffusion")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.bottom)
                
                PromptView(parameter: $generationParameter)
                    .disabled(imageGenerator.generationState != .idle)
                
                if imageGenerator.generationState == .idle {
                    Button(action: generate) {
                        Text("Generate").font(.title)
                    }.buttonStyle(.borderedProminent)
                } else {
                    ProgressView()
                }
                
                if let generatedImages = imageGenerator.generatedImages {
                    ForEach(generatedImages.images) {
                        Image(uiImage: $0.uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
        }
        .padding()
    }
    
    func generate() {
        imageGenerator.generateImages(generationParameter)
    }
}

