//
//  LivePhotoDetailSelectButton.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 6. 2..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SwiftyImage

class LivePhotoDetailSelectButton: UIView {
    fileprivate let leftButton = UIButton()
    fileprivate let rightButton = UIButton()
    private let titleLabel = UILabel()
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    var titleColor: UIColor = .black {
        didSet {
            if isEnabled {
                titleLabel.textColor = titleColor
            }
        }
    }
    var disabledTitleColor: UIColor = .gray220 {
        didSet {
            if !isEnabled {
                titleLabel.textColor = disabledTitleColor
            }
        }
    }
    var isEnabled = true {
        didSet {
            titleLabel.textColor = isEnabled ? titleColor : disabledTitleColor
            leftButton.isEnabled = isEnabled
            rightButton.isEnabled = isEnabled
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self)
        }
        let rightArrow = UIImage(named: "arrow_44pt")!
        let disabledRightArrow = rightArrow.with(color: UIColor.gray220)
        leftButton.setImage(UIImage(cgImage: rightArrow.cgImage!, scale: rightArrow.scale, orientation: UIImageOrientation.upMirrored), for: .normal)
        leftButton.setImage(UIImage(cgImage: disabledRightArrow.cgImage!, scale: disabledRightArrow.scale, orientation: UIImageOrientation.upMirrored), for: .disabled)
        addSubview(leftButton)
        leftButton.snp.makeConstraints { (make) in
            make.top.left.bottom.equalTo(self)
            make.width.equalTo(44)
        }
        rightButton.setImage(rightArrow, for: .normal)
        rightButton.setImage(disabledRightArrow, for: .disabled)
        addSubview(rightButton)
        rightButton.snp.makeConstraints { (make) in
            make.top.right.bottom.equalTo(self)
            make.width.equalTo(44)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Reactive where Base: LivePhotoDetailSelectButton {
    var leftTap: Observable<Void> {
        return base.leftButton.rx.tap.asObservable()
    }
    var rightTap: Observable<Void> {
        return base.rightButton.rx.tap.asObservable()
    }
}
