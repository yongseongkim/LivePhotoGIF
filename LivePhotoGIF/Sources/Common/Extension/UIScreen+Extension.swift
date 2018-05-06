//
//  UIScreen+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit

extension UIScreen {
    static var size: CGSize {
        return UIScreen.main.bounds.size
    }
    static var width: CGFloat {
        return UIScreen.size.width
    }
    static var height: CGFloat {
        return UIScreen.size.height
    }
}
