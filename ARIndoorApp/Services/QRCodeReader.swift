//
//  QRCodeReader.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 3/6/21.
//

import UIKit

protocol QRCodeReader {
    func readQRCode(image: CVPixelBuffer, completion: @escaping ((String?) -> Void))
}

final class QRCodeReaderImpl: QRCodeReader {
    
    func readQRCode(image: CVPixelBuffer, completion: @escaping ((String?) -> Void)) {
        qrQueue.async {
            let image = CIImage(cvPixelBuffer: image)
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
            let features = detector!.features(in: image)

            for feature in features {
                if let feature = feature as? CIQRCodeFeature {
                    DispatchQueue.main.async {
                        completion(feature.messageString)
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    private let qrQueue = DispatchQueue.init(label: "qr")
}
