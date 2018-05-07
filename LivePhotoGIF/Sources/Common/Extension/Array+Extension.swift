//
//  Array+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 5. 7..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import Foundation

extension Array {
    func slices(from: Index, to:Index) -> Array<Element> {
        var arr = [Element]()
        for i in from..<to {
            arr.append(self[i])
        }
        return arr
    }
}
