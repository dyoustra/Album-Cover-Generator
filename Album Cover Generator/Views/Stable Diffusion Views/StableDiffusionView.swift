//
//  StableDiffusionView.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 4/16/23.
//

import SwiftUI
import StableDiffusion

@available(iOS 16.2, *)
struct StableDiffusionView: View {

    @State var prompt: String = "a photo of a child looking at the stars"
    @State var pipeline: StableDiffusionPipeline?
    @State var initializing = true

    @State var image: CGImage?
    @State var progress = 0.0
    @State var generating = false

    var body: some View {
        VStack {
            if initializing {
                Text("Initializing...")
            } else {
                if let image {
                    Image(image, scale: 1.0, label: Text(""))
                }
                if generating {
                    Spacer()
                    ProgressView(value: progress)
                    Text("generating (\(Int(progress*100)) %)")
                } else {
                    Spacer()
                    TextField("Prompt", text: $prompt)
                    Button("Generate") {
                        generateImage()
                    }
                }
            }
        }
        .padding()
        .task {
            do {
                let url = Bundle.main.resourceURL?.appending(path: "model")
                pipeline = try StableDiffusionPipeline(resourcesAt: url!, disableSafety: false)
            } catch let error {
                print(error.localizedDescription)
            }
            initializing = false
        }
    }

    func generateImage(){
        progress = 0.0
        image = nil
        generating = true
        Task.detached(priority: .high) {
            var images: [CGImage?]?
            do {
                images = try pipeline?.generateImages(configuration: .init(prompt: prompt), progressHandler: { progress in
                    self.progress = Double(progress.step) / 50
                    if let image = progress.currentImages.first {
                        self.image = image
                    }
                    return true
                })
            }  catch let error {
                print(error.localizedDescription)
            }
            if let image = images?.first {
                self.image = image
            }
            generating = false
        }
    }
}

