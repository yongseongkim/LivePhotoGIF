//
//  String+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 1..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import Foundation

extension String {
    var fileName: String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
    
    var fileExtension: String {
        return URL(fileURLWithPath: self).pathExtension
    }
}
