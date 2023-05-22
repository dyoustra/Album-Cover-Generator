//
//  Pipeline.swift
//  StableDiffusionApp
//
//  Created by Rehan Parwani on 5/19/23.
//

import Foundation
import CoreML
import Combine

import StableDiffusion

typealias StableDiffusionProgress = StableDiffusionPipeline.Progress

struct GenerationResult {
    var image: CGImage?
    var lastSeed: UInt32
    var interval: TimeInterval?
    var userCanceled: Bool
}

class Pipeline {
    let pipeline: StableDiffusionPipeline
    let maxSeed: UInt32
    
    var progress: StableDiffusionProgress? = nil {
        didSet {
            progressPublisher.value = progress
        }
    }
    lazy private(set) var progressPublisher: CurrentValueSubject<StableDiffusionProgress?, Never> = CurrentValueSubject(progress)
    
    private var canceled = false

    init(_ pipeline: StableDiffusionPipeline, maxSeed: UInt32 = UInt32.max) {
        self.pipeline = pipeline
        self.maxSeed = maxSeed
    }
    
    func generate(
        prompt: String,
        negativePrompt: String = "",
        scheduler: StableDiffusionScheduler,
        numInferenceSteps stepCount: Int = 50,
        seed: UInt32? = nil,
        guidanceScale: Float = 7.5,
        disableSafety: Bool = false
    ) throws -> GenerationResult {
        let beginDate = Date()
        canceled = false
        print("Generating...")
        let theSeed = seed ?? UInt32.random(in: 0...maxSeed)
        var configuration = StableDiffusionPipeline.Configuration(prompt: prompt)
        configuration.negativePrompt = negativePrompt
        configuration.imageCount = 1
        configuration.stepCount = stepCount
        configuration.seed = theSeed
        configuration.guidanceScale = guidanceScale
        configuration.disableSafety = disableSafety
        let images = try pipeline.generateImages(configuration: configuration) { progress in
            handleProgress(progress)
            return !canceled
        }
        let interval = Date().timeIntervalSince(beginDate)
        print("Got images: \(images) in \(interval)")
        
        // Unwrap the 1 image we asked for, nil means safety checker triggered
        let image = images.compactMap({ $0 }).first
        return GenerationResult(image: image, lastSeed: theSeed, interval: interval, userCanceled: canceled)
    }
    
    func handleProgress(_ progress: StableDiffusionPipeline.Progress) {
        self.progress = progress
    }
    
    func setCancelled() {
        canceled = true
    }
    
    func setupCancel() {
        canceled = false
    }
}
