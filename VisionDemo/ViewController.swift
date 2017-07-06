//
//  ViewController.swift
//  VisionDemo
//
//  Created by luojie on 2017/7/5.
//  Copyright © 2017年 LuoJie. All rights reserved.
//


import UIKit
//import BNKit
import RxSwift
import RxCocoa
import Vision
import ImageIO
import Action

class ViewController: UIViewController, CanGetImage {
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem!.rx.tap
            .flatMapLatest { [unowned self] _ in self.getImage(sourceType: .camera) }
            .filterNil()
            .bind(to: getTextAction.inputs)
            .disposed(by: disposeBag)
        
        getTextAction.elements
            .debug("elements")
            .observeOnMainScheduler()
            .map { $0 ?? "nil" }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
        
        getTextAction.errors
            .debug("errors")
            .observeOnMainScheduler()
            .map { "\($0)" }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    let getTextAction: Action<UIImage, String?> = Action { uiImage in
        return VNDetectBarcodesRequest.rx.data(uiImage: uiImage)
            .map { String(data: $0, encoding: .utf8) }
    }
}

// Input -> RequestInput -> Results -> MyResult

extension Reactive where Base: VNDetectBarcodesRequest {
    
    public static func data(uiImage: UIImage) -> Observable<Data> {
        
        return Observable.create { (observer) in
            guard let ciImage = CIImage(image: uiImage) else {
                observer.onError("Can't convert image to CIImage.")
                return Disposables.create()
            }
            
            let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: Int32(orientation.rawValue))
            do {
                try handler.perform([
                    VNDetectBarcodesRequest { (request, error) in
                        switch (request.results?.first, error) {
                        case let (_, error?):
                            observer.onError(error)
                        case (nil, _):
                            observer.onError("Can't find any QRCode.")
                        case let (observation, _) as (VNBarcodeObservation, Error?):
                            let descriptor = observation.barcodeDescriptor as! CIQRCodeDescriptor
                            observer.onNext(descriptor.errorCorrectedPayload)
                            observer.onCompleted()
                        default:
                            observer.onError("Unknown Error.")
                        }
                    }
                    ])
            } catch {
                observer.onError(error)
                print(error)
            }
            return Disposables.create()
        }
    }
}

//public protocol IsVNRequest {
//    init(completionHandler: Vision.VNRequestCompletionHandler?)
//}
//
//extension VNRequest: IsVNRequest {}



