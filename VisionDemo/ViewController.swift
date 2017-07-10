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
import TesseractOCR

class ViewController: UIViewController, CanGetImage {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem!.rx.tap
            .flatMapLatest { [unowned self] _ in self.getImage(sourceType: .photoLibrary) }
            .filterNil()
            .bind(to: getTextAction.inputs)
            .disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem!.rx.tap
            .flatMapLatest { [unowned self] _ in self.getImage(sourceType: .camera) }
            .filterNil()
            .bind(to: getTextAction.inputs)
            .disposed(by: disposeBag)
        
        getTextAction.elements
//            .debug("elements")
            .observeOnMainScheduler()
            .map { $0 ?? "nil" }
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)
        
        getTextAction.executing
            //            .debug("elements")
            .filter { $0 }
            .observeOnMainScheduler()
            .map { _ in "loading" }
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)
        
        getTextAction.errors
//            .debug("errors")
            .observeOnMainScheduler()
            .map { "\($0)" }
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    let getBarcodeTextAction: Action<UIImage, String?> = Action { uiImage in
        return VNDetectBarcodesRequest.rx.data(uiImage: uiImage)
            .map { String(data: $0, encoding: .utf8) }
    }
    
    let getTextAction: Action<UIImage, String?> = Action { uiImage in
        return VNDetectTextRectanglesRequest.rx.boxes(uiImage: uiImage)
            .debug("boxes")
            .map { $0.filter { $0.width > 5 } }
            .map { rects in rects.map { VNDetectTextRectanglesRequest.rx.recognizedText(uiImage: uiImage, rect: $0) } }
            .flatMap(Observable.zip)
            .take(1)
            .map { (texts) in texts.flatMap { $0 }.reduce("", +) }
            .debug("recognizedText")
    }
}

extension Reactive where Base: VNDetectTextRectanglesRequest {
    
    public static func boxes(uiImage: UIImage) -> Observable<[CGRect]> {
        
        return Observable<[CGRect]>.create { (observer) in
            
            let handler = VNImageRequestHandler(cgImage: uiImage.cgImage!, options: [:])
            do {
                try handler.perform([
                    VNDetectTextRectanglesRequest { (request, error) in
                        switch (request.results, error) {
                        case let (_, error?):
                            observer.onError(error)
                        case let (results, _):
                            let boxes = (results as? [VNTextObservation] ?? [])
                                .map { $0.boundingBox }
                                .map {
                                    CGRect(
                                        x: $0.origin.x * uiImage.size.width,
                                        y: $0.origin.y * uiImage.size.height,
                                        width: $0.size.width * uiImage.size.width,
                                        height: $0.size.height * uiImage.size.height
                                    )
                            }.reversed()
                            observer.onNext(Array(boxes))
                            observer.onCompleted()
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
    
    public static func recognizedText(uiImage: UIImage, rect: CGRect) -> Observable<String?> {
        return Observable.create { (observer) in
            let tesseract = G8Tesseract(language: "eng")!
            tesseract.image = uiImage
            tesseract.rect = rect
            tesseract.recognize()
            print(tesseract.recognizedText)
            observer.onNext(tesseract.recognizedText)
            observer.onCompleted()
            return Disposables.create()
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
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



