//
//  LivePhotoDetailViewController.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit
import Photos
import Then
import SnapKit
import RxSwift
import RxCocoa
import AVKit
import SwiftyGif

class LivePhotoFrameImageCell: UICollectionViewCell {
    static var space: CGFloat {
        return 0
    }
    static var numberOfCellInRow: CGFloat {
        return 8
    }
    static var size: CGSize {
        let width = (LivePhotoDetailViewController.contentWidth - (LivePhotoFrameImageCell.space * (LivePhotoFrameImageCell.numberOfCellInRow - 1))) / LivePhotoFrameImageCell.numberOfCellInRow
        return CGSize(width: width, height: width)
    }
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LivePhotoDetailViewController: UIViewController {
    static var contentWidth: CGFloat {
        return UIScreen.width * 0.85
    }
    static var patternList: [PlayPattern] {
        return [.forward, .backward, .forwardbackward, .backwardforward]
    }
    static var speedList: [Float] {
        return [1.0, 1.5, 2.0, 0.5]
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
    private let closeButton = UIButton(frame: .zero)
    private let imageView = UIImageView(image: nil)
    private let thumbnailCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let optionView = UIView()
    private let patternButton = UIButton()
    private let speedButton = UIButton()
    private let exportButton = UIButton()
    
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
    private var gifURL:URL? {
        didSet {
            imageView.setGifFromURL(gifURL)
        }
    }
    
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
    
    private func configureUI() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(view)
        }
        mainView.backgroundColor = UIColor.clear
        mainView.clipsToBounds = true
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
        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(mainView)
            make.height.equalTo(100).priority(.low)
        }
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(contentView)
            make.height.equalTo(LivePhotoDetailViewController.contentWidth)
        }
        contentView.addSubview(closeButton)
        closeButton.setImage(UIImage(named: "btn_common_x_44pt"), for: .normal)
        closeButton.snp.makeConstraints { (make) in
            make.top.right.equalTo(contentView)
            make.width.height.equalTo(44)
        }
        thumbnailCollectionView.dataSource = self
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.allowsMultipleSelection = false
        (thumbnailCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        thumbnailCollectionView.register(LivePhotoFrameImageCell.self)
        contentView.addSubview(thumbnailCollectionView)
        thumbnailCollectionView.snp.makeConstraints { (make) in
            make.left.right.equalTo(contentView)
            make.height.equalTo(LivePhotoFrameImageCell.size.height)
            make.top.equalTo(imageView.snp.bottom)
        }
        contentView.addSubview(optionView)
        optionView.backgroundColor = UIColor.white
        optionView.snp.makeConstraints { (make) in
            make.top.equalTo(thumbnailCollectionView.snp.bottom)
            make.left.right.bottom.equalTo(contentView)
            make.height.equalTo(44)
        }
        optionView.addSubview(patternButton)
        patternButton.setTitle("FORWARD", for: .normal)
        patternButton.setTitleColor(UIColor.black, for: .normal)
        patternButton.setTitleColor(UIColor.gray220, for: .disabled)
        patternButton.contentEdgeInsets.left = 15
        patternButton.contentEdgeInsets.right = 15
        patternButton.contentHuggingPriority(for: .horizontal)
        patternButton.contentCompressionResistancePriority(for: .horizontal)
        patternButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(optionView)
            make.width.equalTo(80).priority(.low)
        }
        
        optionView.addSubview(speedButton)
        speedButton.setTitle("1.0", for: .normal)
        speedButton.setTitleColor(UIColor.black, for: .normal)
        speedButton.setTitleColor(UIColor.gray220, for: .disabled)
        speedButton.contentEdgeInsets.left = 20
        speedButton.contentEdgeInsets.right = 20
        patternButton.contentHuggingPriority(for: .horizontal)
        patternButton.contentCompressionResistancePriority(for: .horizontal)
        speedButton.snp.makeConstraints { (make) in
            make.top.bottom.right.equalTo(optionView)
            make.width.equalTo(80).priority(.low)
        }
        mainView.addSubview(exportButton)
        exportButton.setTitle("EXPORT", for: .normal)
        exportButton.setTitleColor(UIColor.black, for: .normal)
        exportButton.setTitleColor(UIColor.gray220, for: .disabled)
        exportButton.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        exportButton.contentEdgeInsets.left = 15
        exportButton.contentEdgeInsets.right = 15
        exportButton.backgroundColor = UIColor.white
        exportButton.layer.cornerRadius = 8
        exportButton.contentHuggingPriority(for: .horizontal)
        exportButton.contentCompressionResistancePriority(for: .horizontal)
        exportButton.snp.makeConstraints { (make) in
            make.width.equalTo(50).priority(.low)
            make.height.equalTo(44)
            make.centerX.equalTo(mainView.snp.centerX)
            make.top.equalTo(contentView.snp.bottom).offset(15)
            make.bottom.equalTo(mainView)
        }
    }
    
    private func bind() {
        // UI Binding
        closeButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        exportButton.rx.tap.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self, let gifURL = self.gifURL, let data = try? Data(contentsOf: gifURL) else { return }
            let items = [data]
            let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
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
                self.loadGIF(with: resource)
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
        let resources = PHAssetResource.assetResources(for: asset)
        var photoResource: PHAssetResource?
        var videoResource: PHAssetResource?
        for resource in resources {
            // pairedVideo: The resource provides the original video data component of a Live Photo asset.
            // fullSizePairedVideo: The resource provides the current video data component of a Live Photo asset.
            // adjustmentBasePairedVideo: The resource provides an unaltered version of the video data for a Live Photo asset for use in reconstructing recent edits.
            if resource.type == .photo {
                photoResource = resource
            }
            if resource.type == .pairedVideo {
                videoResource = resource
            }
        }
        if let photoResource = photoResource, let videoResource = videoResource {
            // load representative image
            ResourceManager.representativPhoto(from: photoResource) { [weak self] (image, error) in
                if let error = error {
                    print(error)
                }
                guard let `self` = self, let image = image else { return }
                self.imageView.image = image
                self.imageView.snp.updateConstraints({ (make) in
                    make.height.equalTo((image.size.height / image.size.width) * LivePhotoDetailViewController.contentWidth)
                })
            }
            // make GIF by video file
            ResourceManager.extractImages(from: videoResource,
                                          progress: { (progress) in
                                            // download progress from iCloud
                                            print(progress)
            },
                                          completion: { [weak self] (images, duration, error) in
                                            guard let `self` = self, let images = images, let duration = duration else { return }
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
    
    private func loadGIF(with resource: Resource) {
        self.deactiveButtons()
        let duration = (Float(resource.duration) / resource.speed)
        let fileName = String.init(format: "%@_%f", resource.fileName, resource.speed * 10)
        ResourceManager.createGIF(with: GIFResource(images: resource.images,
                                                    delayTime: duration / Float(resource.images.count),
                                                    loopCount: 0,
                                                    pattern: resource.pattern,
                                                    detinationFileName: fileName)) { [weak self] (url, error) in
                                                        // TODO: error handling
                                                        self?.gifURL = url
                                                        self?.activeButtons()
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
