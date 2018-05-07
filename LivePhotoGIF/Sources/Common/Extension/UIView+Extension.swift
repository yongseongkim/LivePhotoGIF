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
        return CGRect(x: self.frame.origin.x - 10,
                      y: self.frame.origin.y - 10,
                      width: self.frame.size.width + 20,
                      height: self.frame.size.height + 20).contains(position)
    }
}
