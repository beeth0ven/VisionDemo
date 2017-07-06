//
//  CanGetImage.swift
//  Vision
//
//  Created by luojie on 2017/7/4.
//  Copyright © 2017年 LuoJi. All rights reserved.
//


import UIKit
import BNKit
import RxSwift
import RxCocoa
import ImageIO

public protocol CanGetImage {}
extension CanGetImage where Self: UIViewController {
    
    public func getImage(sourceType: UIImagePickerControllerSourceType = .photoLibrary) -> Observable<UIImage?> {
        let vc = UIImagePickerController()
        vc.sourceType = sourceType
        vc.allowsEditing = true
        Queue.main.execute { self.present(vc, animated: true, completion: nil) }
        let didCancel = vc.rx.didCancel.flatMapLatest { _ in Observable<UIImage?>.empty() }
        let didFinish = vc.rx.didFinishPickingMediaWithInfo
            .map { $0[UIImagePickerControllerEditedImage] as? UIImage }
        return Observable.of(didCancel, didFinish)
            .merge()
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}




