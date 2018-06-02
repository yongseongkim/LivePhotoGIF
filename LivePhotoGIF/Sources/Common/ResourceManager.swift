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
import RxSwift

enum PlayPattern: String {
    case forward = "FORWARD"
    case backward = "BACKWARD"
    case forwardbackward = "FORWARDBACKWARD"
    case backwardforward = "BACKWARDFORWARD"
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
    
    static func extractImages(from: PHAssetResource, progressHandler: ((Double)->())?, completionHandler: @escaping ((URL?, [UIImage]?, Int64?, Error?) ->())) {
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
        options.progressHandler = { (progressValue) in
            if let phandler = progressHandler {
                phandler(progressValue / 2)
            }
        }
        
        let handleVideoFile: ((Error?) -> ()) = { (error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, error)
                }
                return
            }
            let avAsset = AVURLAsset(url: videoURL)
            let duration = Int64(CMTimeGetSeconds(avAsset.duration) + 0.5)
            
            let track = avAsset.tracks(withMediaType: AVMediaType.video).first!
            let naturalSize = track.naturalSize.applying(track.preferredTransform)
            let frameRate = track.nominalFrameRate
            
            let imageGenerator = AVAssetImageGenerator(asset: avAsset)
            imageGenerator.appliesPreferredTrackTransform = true
            let width = abs(naturalSize.width)
            let height = abs(naturalSize.height)
            let basis = UIScreen.width * UIScreen.main.scale
            if width > height {
                imageGenerator.maximumSize = CGSize(width: basis, height: (height / width) * basis)
            } else {
                imageGenerator.maximumSize = CGSize(width: (width / height) * basis, height: basis)
            }
            
            let times = ResourceManager.times(frameRate: Int32(frameRate), duration: duration)
            var requestCount: Int = 0
            var images = [UIImage]()
            // for requesting all frames
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, imageRef, actualTime, result, error) in
                requestCount = requestCount + 1
                if let phandler = progressHandler {
                    phandler(0.5 + 0.5 * (Double(requestCount) / Double(times.count)))
                }
                if let error = error {
                    print(error)
                }
                if let imageRef = imageRef {
                    images.append(UIImage(cgImage: imageRef))
                }
                if times.count == requestCount {
                    DispatchQueue.main.async {
                        completionHandler(videoURL, images, duration, nil)
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
    
    static func createGIF(with resource: GIFResource, completionHandler: @escaping ((URL?, Error?) -> ())) {
        DispatchQueue.global().async {
            let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: resource.loopCount]]
            let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: resource.delayTime]]
            
            let fileName: String
            switch resource.pattern {
            case .forward:
                fileName = resource.detinationFileName + ".gif"
            case .backward:
                fileName = resource.detinationFileName + "_backward.gif"
            case .forwardbackward:
                fileName = resource.detinationFileName + "_forwardbackward.gif"
            case .backwardforward:
                fileName = resource.detinationFileName + "_backwardforward.gif"
            }
            
            var images = resource.images
            var lowQualityImages = [UIImage]()
            for image in images {
                if let compressedData = UIImageJPEGRepresentation(image, 0), let compressedImage = UIImage(data: compressedData) {
                    lowQualityImages.append(compressedImage)
                }
            }
            images = lowQualityImages
            
            let path = gifDirPath.appending(fileName)
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, Int(images.count), nil) else {
                DispatchQueue.main.async {
                    completionHandler(nil, CreateGIFError.noDestination)
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
                    completionHandler(url, nil)
                } else {
                    completionHandler(nil, CreateGIFError.unknown)
                }
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

extension ResourceManager: ReactiveCompatible {}
extension Reactive where Base: ResourceManager {
    enum ResourceRequestState {
        case inProgress(Double)
        case success([String: Any])
        case failure(Error)
    }
    
    static func extractImages(from: PHAssetResource) -> Observable<ResourceRequestState> {
        return Observable.create({ (observer) -> Disposable in
            ResourceManager.extractImages(from: from,
                                          progressHandler: { (progress) in
                                            observer.onNext(.inProgress(progress))
            },
                                          completionHandler: { (url, images, duration, error) in
                                            if let error = error {
                                                observer.onNext(.failure(error))
                                            } else {
                                                var result = [String: Any]()
                                                if let url = url {
                                                    result["url"] = url
                                                }
                                                if let images = images {
                                                    result["images"] = images
                                                }
                                                if let duration = duration {
                                                    result["duration"] = duration
                                                }
                                                observer.onNext(.success(result))
                                            }
                                            observer.onCompleted()
            })
            return Disposables.create()
        })
    }
}
