//
//  LivePhotoFrameImageCell.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 7..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit

class LivePhotoFramesBoundaryView: UIView {
    static var width: CGFloat {
        return 15
    }
    private let lineView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.gray145
        isUserInteractionEnabled = false
        lineView.layer.cornerRadius = 1.5
        lineView.backgroundColor = UIColor.white
        addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.centerX.equalTo(snp.centerX)
            make.centerY.equalTo(snp.centerY)
            make.width.equalTo(3)
            make.height.equalTo(15)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class LivePhotoFrameImageCell: UICollectionViewCell {
    static var space: CGFloat {
        return 0
    }
    static var numberOfCellInRow: CGFloat {
        return 8
    }
    static var size: CGSize {
        let width = floor((LivePhotoDetailViewController.thumbnailCollectionWidth - (LivePhotoFrameImageCell.space * (LivePhotoFrameImageCell.numberOfCellInRow - 1))) / LivePhotoFrameImageCell.numberOfCellInRow)
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

