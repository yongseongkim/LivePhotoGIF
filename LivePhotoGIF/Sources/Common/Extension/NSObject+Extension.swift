//
//  NSObject+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import Foundation

extension NSObject {
    static var className: String {
        return String(describing: self)
    }
}
