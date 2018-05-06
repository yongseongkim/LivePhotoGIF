//
//  RootViewController.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Photos

class LivePhotoCell: UICollectionViewCell {
    static var space: CGFloat {
        return 4
    }
    static var numberOfCellInRow: CGFloat {
        return 4
    }
    static var size: CGSize {
        let width = (UIScreen.width - CGFloat(LivePhotoCell.space * LivePhotoCell.numberOfCellInRow - 1)) / LivePhotoCell.numberOfCellInRow
        return CGSize(width: width, height: width)
    }
    
    let imageView = UIImageView()
    var assetIdentifier: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RootViewController: UIViewController {
    
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then { (view) in
        view.backgroundColor = UIColor.white
    }
    private var fetchResult: PHFetchResult<PHAsset>!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(LivePhotoCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(view)
        }
        try? FileManager.default.removeItem(atPath: ResourceManager.gifDirPath)
        PHPhotoLibrary.shared().register(self)
        if fetchResult == nil {
            let onlyLivePhotoOptions = PHFetchOptions()
            onlyLivePhotoOptions.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
            onlyLivePhotoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: onlyLivePhotoOptions)
        }
    }
}

extension RootViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.deqeueResuableCell(forIndexPath: indexPath) as LivePhotoCell
        let asset = fetchResult.object(at: indexPath.row)
        cell.assetIdentifier = asset.localIdentifier
        PHImageManager.default().requestImage(for: asset, targetSize: LivePhotoCell.size, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.assetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            } else {
                cell.imageView.image = nil
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return LivePhotoCell.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LivePhotoCell.space
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LivePhotoCell.space
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = fetchResult.object(at: indexPath.row)
        let detailViewController = LivePhotoDetailViewController(assetIdentifier: asset.localIdentifier)
        detailViewController.modalPresentationStyle = .custom
        detailViewController.modalTransitionStyle = .crossDissolve
        self.present(detailViewController, animated: true, completion: nil)
    }
}

extension RootViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
        DispatchQueue.main.sync {
            fetchResult = changes.fetchResultAfterChanges
            collectionView.reloadData()
        }
    }
}
