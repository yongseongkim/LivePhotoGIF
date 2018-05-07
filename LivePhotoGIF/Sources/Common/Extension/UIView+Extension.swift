//
//  UIView+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 7..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit

extension UIView {
    func isNear(position: CGPoint) -> Bool {
        return CGRect(x: self.frame.origin.x - 7,
                      y: self.frame.origin.y - 7,
                      width: self.frame.size.width + 14,
                      height: self.frame.size.height + 14).contains(position)
    }
}
