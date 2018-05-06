//
//  UICollectionView+Extension.swift
//  LivePhotoGIF
//
//  Created by YongSeong Kim on 2018. 4. 29..
//  Copyright © 2018년 YongSeong Kim. All rights reserved.
//

import UIKit

extension UICollectionView {
    func register<T: UICollectionViewCell>(_: T.Type) {
        let nibName = String(describing: T.self)
        if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
            let nib = UINib(nibName: nibName, bundle: nil)
            register(nib, forCellWithReuseIdentifier: nibName)
            return
        }
        register(T.self, forCellWithReuseIdentifier: nibName)
    }
    
    func registerHeader<T: UICollectionReusableView>(_: T.Type) {
        let nibName = String(describing: T.self)
        if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
            let nib = UINib(nibName: nibName, bundle: nil)
            register(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: nibName)
            return
        }
        register(T.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: nibName)
    }
    
    func deqeueResuableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(String(describing: T.self))")
        }
        return cell
    }
    
    func deqeueResuableHeader<T: UICollectionReusableView>(forIndexPath indexPath: IndexPath) -> T {
        guard let header = dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("Could not dequeue header with identifier: \(String(describing: T.self))")
        }
        return header
    }
}

