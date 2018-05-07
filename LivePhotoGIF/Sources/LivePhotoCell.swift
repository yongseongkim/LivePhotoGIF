//
//  LivePhotoCell.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 7..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit

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
        clipsToBounds = true
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

