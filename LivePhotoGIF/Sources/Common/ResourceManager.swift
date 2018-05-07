//
//  ResourceManager.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 1..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import Foundation
import Photos
import AVKit
import MobileCoreServices

enum PlayPattern {
    case forward
    case backward
    case forwardbackward
    case backwardforward
}

struct GIFResource {
    let images: [UIImage]
    let delayTime: Float
    let loopCount: Int
    let pattern: PlayPattern
    let detinationFileName: String
}

class ResourceManager {
    enum RepresentativPhoto: Error {
        case unknown
    }
    enum CreateGIFError: Error {
        case noDestination
        case unknown
    }

    static let videoDirPath = URL.documentsPath.appending("/video/")
    static let gifDirPath = URL.documentsPath.appending("/gif/")
    
    static func extractImages(from: PHAssetResource, progress: ((Double)->())?, completion: @escaping ((URL?, [UIImage]?, Int64?, Error?) ->())) {
        if !FileManager.default.fileExists(atPath: ResourceManager.videoDirPath) {
            try? FileManager.default.createDirectory(atPath: ResourceManager.videoDirPath, withIntermediateDirectories: true, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: ResourceManager.gifDirPath) {
            try? FileManager.default.createDirectory(atPath: ResourceManager.gifDirPath, withIntermediateDirectories: true, attributes: nil)
        }
        let videoSource = ResourceManager.videoDirPath.appending(from.originalFilename)
        let videoURL = URL(fileURLWithPath: videoSource)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = progress
        
        let handleVideoFile: ((Error?) -> ()) = { (error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, nil, nil, error)
                }
                return
            }
            let avAsset = AVURLAsset(url: videoURL)
            let duration = Int64(CMTimeGetSeconds(avAsset.duration) + 0.5)
            
            let track = avAsset.tracks(withMediaType: AVMediaType.video).first!
            let naturalSize = track.naturalSize.applying(track.preferredTransform)
            let frameRate = track.nominalFrameRate
            
            let ratio = abs(naturalSize.height) / abs(naturalSize.width)
            let imageGenerator = AVAssetImageGenerator(asset: avAsset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: UIScreen.width, height: ratio * UIScreen.width)
            
            let times = ResourceManager.times(frameRate: Int32(frameRate), duration: duration)
            var requestCount: Int = 0
            var images = [UIImage]()
            // for requesting all frames
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, imageRef, actualTime, result, error) in
                requestCount = requestCount + 1
                if let error = error {
                    print(error)
                }
                if let imageRef = imageRef {
                    images.append(UIImage(cgImage: imageRef))
                }
                if times.count == requestCount {
                    DispatchQueue.main.async {
                        completion(videoURL, images, duration, nil)
                    }
                }
            }
        }
        if FileManager.default.fileExists(atPath: videoSource) {
            handleVideoFile(nil)
        } else {
            PHAssetResourceManager.default()
                .writeData(for: from,
                           toFile: videoURL,
                           options: options) { (error) in
                            handleVideoFile(error)
            }
        }
    }
    
    static func createGIF(with resource: GIFResource, completion: @escaping ((URL?, Error?) -> ())) {
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: resource.loopCount]]
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: resource.delayTime]]
        
        var images = [UIImage]()
        var fileName = ""
        switch resource.pattern {
        case .forward:
            images = resource.images
            fileName = resource.detinationFileName + ".gif"
        case .backward:
            images = resource.images.reversed()
            fileName = resource.detinationFileName + "_backward.gif"
        case .forwardbackward:
            images = resource.images + resource.images.reversed()
            fileName = resource.detinationFileName + "_forwardbackward.gif"
        case .backwardforward:
            images = resource.images.reversed() + resource.images
            fileName = resource.detinationFileName + "_backwardforward.gif"
        }
        let path = gifDirPath.appending(fileName)
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            DispatchQueue.main.async {
                completion(url, nil)
            }
            return
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, Int(images.count), nil) else {
            DispatchQueue.main.async {
                completion(nil, CreateGIFError.noDestination)
            }
            return
        }
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        for image in images {
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }
        }
        DispatchQueue.main.async {
            if CGImageDestinationFinalize(destination) {
                completion(url, nil)
            } else {
                completion(nil, CreateGIFError.unknown)
            }
        }
    }
    
    private static func times(frameRate: Int32, duration: Int64) -> [NSValue] {
        var times = [NSValue]()
        for second in 0..<duration {
            for frame in 0..<frameRate {
                let cmtime = CMTimeMake(second * Int64(frameRate) + Int64(frame), frameRate)
                times.append(NSValue(time: cmtime))
            }
        }
        return times
    }
}
