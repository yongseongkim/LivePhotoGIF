//
//  LivePhotoDetailViewController.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit
import Photos
import SnapKit
import RxSwift
import RxCocoa
import RxGesture
import AVKit
import SwiftyGif

class LivePhotoDetailViewController: UIViewController {
    static var contentWidth: CGFloat {
        return UIScreen.width * 0.95
    }
    static var thumbnailCollectionWidth: CGFloat {
        return LivePhotoDetailViewController.contentWidth - 30
    }
    static var patternList: [PlayPattern] {
        return [.forward, .backward, .forwardbackward, .backwardforward]
    }
    static var speedList: [Float] {
        return [1.0, 1.5, 2.0, 0.5]
    }
    static var thumbnailLineViewWidth: CGFloat {
        return 15
    }
    struct Resource {
        let images: [UIImage]
        let duration: Int64
        let pattern: PlayPattern
        let speed: Float
        let fileName: String
    }
    
    private let mainView = UIView()
    private let contentView = UIView()
    private let imageView = UIImageView(image: nil)
    
    private let optionView = UIView()
    private let thumbnailView = UIView()
    private let thumbnailCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let thumbnailStartView = UIView()
    private let thumbnailEndView = UIView()
    private let patternButton = UIButton()
    private let speedButton = UIButton()
    
    private let buttonsView = UIView()
    private let exportButton = UIButton()
    private let closeButton = UIButton()
    
    private let assetIdentifier: String
    private let disposeBag = DisposeBag()
    private let resource = Variable<Resource?>(nil)
    private var numberOfVisibleFrames: Int {
        var frames = resource.value?.images.count ?? 0
        if frames > Int(LivePhotoFrameImageCell.numberOfCellInRow) {
            frames = Int(LivePhotoFrameImageCell.numberOfCellInRow)
        }
        return frames
    }
    private var isStartDragging = false
    private var isEndDragging = false
    
    init(assetIdentifier: String) {
        self.assetIdentifier = assetIdentifier
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        loadResource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        thumbnailStartView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: LivePhotoDetailViewController.thumbnailLineViewWidth,
                                          height: LivePhotoFrameImageCell.size.height)
        thumbnailEndView.frame = CGRect(x: thumbnailView.frame.width - LivePhotoDetailViewController.thumbnailLineViewWidth,
                                        y: 0,
                                        width: LivePhotoDetailViewController.thumbnailLineViewWidth,
                                        height: LivePhotoFrameImageCell.size.height)
    }
    
    private func configureUI() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(view)
        }
        mainView.backgroundColor = UIColor.clear
        mainView.contentHuggingPriority(for: .vertical)
        mainView.contentCompressionResistancePriority(for: .vertical)
        view.addSubview(mainView)
        mainView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(view.snp.centerY)
            make.width.equalTo(LivePhotoDetailViewController.contentWidth)
            make.height.equalTo(100).priority(.low)
        }
        mainView.addSubview(contentView)
        contentView.contentHuggingPriority(for: .vertical)
        contentView.contentCompressionResistancePriority(for: .vertical)
        contentView.backgroundColor = UIColor.clear
        contentView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(mainView)
            make.height.equalTo(100).priority(.low)
        }
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = 10
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView)
            make.centerX.equalTo(contentView.snp.centerX)
            make.width.height.equalTo(LivePhotoDetailViewController.contentWidth)
        }
        contentView.addSubview(optionView)
        optionView.backgroundColor = UIColor.white
        optionView.contentHuggingPriority(for: .vertical)
        optionView.contentCompressionResistancePriority(for: .vertical)
        optionView.layer.cornerRadius = 8
        optionView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.left.right.bottom.equalTo(contentView)
            make.height.equalTo(50).priority(.low)
        }
        
        optionView.addSubview(thumbnailView)
        thumbnailView.backgroundColor = UIColor.clear
        thumbnailView.snp.makeConstraints { (make) in
            make.top.equalTo(optionView).offset(8)
            make.centerX.equalTo(optionView.snp.centerX)
            make.width.equalTo(LivePhotoDetailViewController.thumbnailCollectionWidth + 30)
            make.height.equalTo(LivePhotoFrameImageCell.size.height)
        }
        thumbnailView.addSubview(thumbnailCollectionView)
        thumbnailCollectionView.dataSource = self
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.allowsMultipleSelection = false
        thumbnailCollectionView.isScrollEnabled = false
        (thumbnailCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        thumbnailCollectionView.register(LivePhotoFrameImageCell.self)
        thumbnailCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(thumbnailView)
            make.centerX.equalTo(thumbnailView.snp.centerX)
            make.width.equalTo(LivePhotoDetailViewController.thumbnailCollectionWidth)
            make.height.equalTo(LivePhotoFrameImageCell.size.height)
        }
        thumbnailStartView.backgroundColor = UIColor.gray145
        thumbnailStartView.isUserInteractionEnabled = false
        thumbnailView.addSubview(thumbnailStartView)
        thumbnailEndView.backgroundColor = UIColor.gray145
        thumbnailEndView.isUserInteractionEnabled = false
        thumbnailView.addSubview(thumbnailEndView)
        
        optionView.addSubview(patternButton)
        patternButton.setTitle("FORWARD", for: .normal)
        patternButton.setTitleColor(UIColor.black, for: .normal)
        patternButton.setTitleColor(UIColor.gray220, for: .disabled)
        patternButton.contentHuggingPriority(for: .horizontal)
        patternButton.contentCompressionResistancePriority(for: .horizontal)
        patternButton.snp.makeConstraints { (make) in
            make.top.equalTo(thumbnailView.snp.bottom).offset(8)
            make.left.right.equalTo(optionView)
            make.height.equalTo(36)
        }
        optionView.addSubview(speedButton)
        speedButton.setTitle("1.0", for: .normal)
        speedButton.setTitleColor(UIColor.black, for: .normal)
        speedButton.setTitleColor(UIColor.gray220, for: .disabled)
        speedButton.contentHuggingPriority(for: .horizontal)
        speedButton.contentCompressionResistancePriority(for: .horizontal)
        speedButton.snp.makeConstraints { (make) in
            make.top.equalTo(patternButton.snp.bottom)
            make.height.equalTo(36)
            make.left.right.bottom.equalTo(optionView)
        }
        buttonsView.addSubview(exportButton)
        exportButton.setTitle("EXPORT", for: .normal)
        exportButton.setTitleColor(UIColor.black, for: .normal)
        exportButton.setTitleColor(UIColor.gray220, for: .disabled)
        exportButton.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        exportButton.backgroundColor = UIColor.white
        exportButton.contentEdgeInsets.left = 30
        exportButton.contentEdgeInsets.right = 30
        exportButton.layer.cornerRadius = 8
        exportButton.contentHuggingPriority(for: .horizontal)
        exportButton.contentCompressionResistancePriority(for: .horizontal)
        exportButton.snp.makeConstraints { (make) in
            make.width.equalTo(50).priority(.low)
            make.height.equalTo(40)
            make.top.left.bottom.equalTo(buttonsView)
        }
        buttonsView.addSubview(closeButton)
        closeButton.setTitle("CLOSE", for: .normal)
        closeButton.setTitleColor(UIColor.black, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        closeButton.backgroundColor = UIColor.white
        closeButton.contentEdgeInsets.left = 20
        closeButton.contentEdgeInsets.right = 20
        closeButton.layer.cornerRadius = 8
        closeButton.contentHuggingPriority(for: .horizontal)
        closeButton.contentCompressionResistancePriority(for: .horizontal)
        closeButton.snp.makeConstraints { (make) in
            make.width.equalTo(44).priority(.low)
            make.height.equalTo(40)
            make.top.bottom.right.equalTo(buttonsView)
            make.left.equalTo(exportButton.snp.right).offset(10)
        }
        mainView.addSubview(buttonsView)
        buttonsView.snp.makeConstraints { (make) in
            make.width.equalTo(50).priority(.low)
            make.height.equalTo(40)
            make.centerX.equalTo(mainView.snp.centerX)
            make.top.equalTo(contentView.snp.bottom).offset(10)
            make.bottom.equalTo(mainView)
        }
    }
    
    private func bind() {
        // UI Binding
        thumbnailView.rx.panGesture().subscribe(onNext: { [weak self] (recognizer) in
            guard let `self` = self, let resource = self.resource.value else { return }
            let position = recognizer.location(in: self.thumbnailView)
            let minimumSpace: CGFloat = 20
            let width = LivePhotoDetailViewController.thumbnailLineViewWidth
            var centerX = position.x - width / 2
            var minX = centerX - width / 2
            var maxX = centerX + width / 2
            switch recognizer.state {
            case .began:
                if self.thumbnailStartView.isNear(position: position) {
                    self.isStartDragging = true
                }
                if self.thumbnailEndView.isNear(position: position) {
                    self.isEndDragging = true
                }
            case .changed:
                if self.isStartDragging {
                    if minX < 0 {
                        minX = 0
                        centerX = width / 2
                        maxX = width
                    }
                    if maxX > self.thumbnailEndView.frame.minX - minimumSpace {
                        minX = self.thumbnailEndView.frame.minX - minimumSpace - width
                        centerX = self.thumbnailEndView.frame.minX - minimumSpace - width / 2
                        maxX = self.thumbnailEndView.frame.minX - minimumSpace
                    }
                    self.thumbnailStartView.frame = CGRect(x: minX, y: 0, width: self.thumbnailStartView.frame.width, height: self.thumbnailStartView.frame.height)
                    let imageIdx = Int(((maxX - width) / self.thumbnailCollectionView.frame.width) * CGFloat(resource.images.count))
                    self.imageView.stopAnimating()
                    self.imageView.image = resource.images[imageIdx]
                }
                if self.isEndDragging {
                    if minX < self.thumbnailStartView.frame.maxX + minimumSpace {
                        minX = self.thumbnailStartView.frame.maxX + minimumSpace
                        centerX = self.thumbnailStartView.frame.maxX + minimumSpace + width / 2
                        maxX = self.thumbnailStartView.frame.maxX + minimumSpace + width
                    }
                    if maxX > self.thumbnailView.frame.size.width {
                        minX = self.thumbnailView.frame.size.width - width
                        centerX = self.thumbnailView.frame.size.width - width / 2
                        maxX = self.thumbnailView.frame.size.width
                    }
                    self.thumbnailEndView.frame = CGRect(x: minX, y: 0, width: self.thumbnailEndView.frame.width, height: self.thumbnailEndView.frame.height)
                    let imageIdx = Int(((minX - width) / self.thumbnailCollectionView.frame.width) * CGFloat(resource.images.count))
                    self.imageView.stopAnimating()
                    self.imageView.image = resource.images[imageIdx]
                }
            case .ended:
                self.isStartDragging = false
                self.isEndDragging = false
                let startImageIdx = Int(((self.thumbnailStartView.frame.maxX - width) / self.thumbnailCollectionView.frame.width) * CGFloat(resource.images.count))
                let endImageIdx = Int(((self.thumbnailEndView.frame.minX - width) / self.thumbnailCollectionView.frame.width) * CGFloat(resource.images.count))
                let newImages = resource.images.slices(from: startImageIdx, to: endImageIdx)
                let newDuration = Double(newImages.count) / Double(resource.images.count) * Double(resource.duration)
                self.imageView.animationImages = newImages
                self.imageView.animationDuration = TimeInterval(newDuration)
                self.imageView.startAnimating()
            default:
                self.isStartDragging = false
                self.isEndDragging = false
                break
            }
        }).disposed(by: disposeBag)
        patternButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            let patternList = LivePhotoDetailViewController.patternList
            guard let `self` = self, let resource = self.resource.value else { return }
            guard let patternIdx = patternList.index(of: resource.pattern) else { return }
            self.resource.value = Resource(images: resource.images,
                                           duration: resource.duration,
                                           pattern: patternList[(patternIdx + 1) % patternList.count],
                                           speed: resource.speed,
                                           fileName: resource.fileName)
        }).disposed(by: disposeBag)
        speedButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            let speedList = LivePhotoDetailViewController.speedList
            guard let `self` = self, let resource = self.resource.value else { return }
            guard let speedIdx = speedList.index(of: resource.speed) else { return }
            self.resource.value = Resource(images: resource.images,
                                           duration: resource.duration,
                                           pattern: resource.pattern,
                                           speed: speedList[(speedIdx + 1) % speedList.count],
                                           fileName: resource.fileName)
        }).disposed(by: disposeBag)
        exportButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self, let resource = self.resource.value else { return }
            self.deactiveButtons()
            let duration = (Float(resource.duration) / resource.speed)
            let fileName = String.init(format: "%@_%f", resource.fileName, resource.speed * 10)
            ResourceManager.createGIF(with: GIFResource(images: resource.images,
                                                        delayTime: duration / Float(resource.images.count),
                                                        loopCount: 0,
                                                        pattern: resource.pattern,
                                                        detinationFileName: fileName)) { [weak self] (url, error) in
                                                            guard let url = url else { return }
                                                            let items = [url]
                                                            let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                                                            self?.present(activityViewController, animated: true, completion: {
                                                                self?.activeButtons()
                                                            })
            }
        }).disposed(by: disposeBag)
        closeButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        // Properties Binding
        resource.asObservable()
            .subscribe(onNext: { [weak self] (resource) in
                guard let `self` = self, let resource = resource else { return }
                self.speedButton.setTitle(String(resource.speed), for: .normal)
                switch resource.pattern {
                case .forward:
                    self.patternButton.setTitle("FORWARD", for: .normal)
                case .backward:
                    self.patternButton.setTitle("BACKWARD", for: .normal)
                case .forwardbackward:
                    self.patternButton.setTitle("FORWARDBACKWARD", for: .normal)
                case .backwardforward:
                    self.patternButton.setTitle("BACKWARDFORWARD", for: .normal)
                }
                self.thumbnailCollectionView.reloadData()
                self.imageView.animationImages = resource.images
                self.imageView.animationDuration = TimeInterval(Float(resource.duration) / resource.speed)
                self.imageView.startAnimating()
            }).disposed(by: disposeBag)
    }
    
    private func loadResource() {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject else {
            let alert = UIAlertController(title: "Error", message: "Can't fetch photo asset.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: .cancel) { [weak self] (action) in
                self?.dismiss(animated: true, completion: nil)
            })
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.deactiveButtons()
        
        // load representative image
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default()
            .requestImage(for: asset,
                          targetSize: UIScreen.size,
                          contentMode: PHImageContentMode.default,
                          options: options) { [weak self] (image, info) in
                            guard let `self` = self, let image = image else { return }
                            self.imageView.image = image
                            var height = (image.size.height / image.size.width) * LivePhotoDetailViewController.contentWidth
                            if height > UIScreen.size.height / 2 {
                                height = UIScreen.size.height / 2
                            }
                            let width = image.size.width / image.size.height * height
                            self.imageView.snp.updateConstraints({ (make) in
                                make.width.equalTo(width)
                                make.height.equalTo(height)
                            })
        }
        let resources = PHAssetResource.assetResources(for: asset)
        var videoResource: PHAssetResource?
        for resource in resources {
            // pairedVideo: The resource provides the original video data component of a Live Photo asset.
            // fullSizePairedVideo: The resource provides the current video data component of a Live Photo asset.
            // adjustmentBasePairedVideo: The resource provides an unaltered version of the video data for a Live Photo asset for use in reconstructing recent edits.
            if resource.type == .pairedVideo {
                videoResource = resource
            }
        }
        if let videoResource = videoResource {
            // load video file from live photo
            ResourceManager.extractImages(from: videoResource,
                                          progress: { (progress) in
                                            // download progress from iCloud
                                            print(progress)
            },
                                          completion: { [weak self] (videoURL, images, duration, error) in
                                            guard let `self` = self, let videoURL = videoURL, let images = images, let duration = duration else { return }
                                            try? FileManager.default.removeItem(at: videoURL)
                                            self.resource.value = Resource(images: images,
                                                                           duration: duration,
                                                                           pattern: LivePhotoDetailViewController.patternList.first!,
                                                                           speed: LivePhotoDetailViewController.speedList.first!,
                                                                           fileName: videoResource.originalFilename.fileName)
                                            self.activeButtons()
            })
        } else {
            let alert = UIAlertController(title: "Error", message: "There are no resources.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: .cancel) { [weak self] (action) in
                self?.dismiss(animated: true, completion: nil)
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func activeButtons() {
        patternButton.isEnabled = true
        speedButton.isEnabled = true
        exportButton.isEnabled = true
    }
    
    private func deactiveButtons() {
        patternButton.isEnabled = false
        speedButton.isEnabled = false
        exportButton.isEnabled = false
    }
}

extension LivePhotoDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfVisibleFrames
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let resource = self.resource.value else { return UICollectionViewCell() }
        let cell = collectionView.deqeueResuableCell(forIndexPath: indexPath) as LivePhotoFrameImageCell
        var multiple = resource.images.count / numberOfVisibleFrames
        if multiple == 0 {
            multiple = 1
        }
        cell.imageView.image = resource.images[indexPath.row * multiple]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return LivePhotoFrameImageCell.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LivePhotoFrameImageCell.space
    }
    
    
}
