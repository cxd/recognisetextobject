//
//  TextSegmentBatch.swift
//  recogniseobject
//


import Foundation
import UIKit
import CoreML
import Vision
import TesseractOCR

class TextSegmentBatch:NSObject, G8TesseractDelegate {
    
    var batch:Array<TextSegment>
    
    var textClassifier:G8Tesseract? = nil
    
    init(model:G8Tesseract) {
        textClassifier = model
        batch = Array<TextSegment>()
    }
    
    convenience init(model:G8Tesseract, inBatch:Array<TextSegment>) {
        self.init(model:model)
        self.batch = inBatch
    }
    /**
     determine whether the full set has been mapped.
     **/
    func isMapped() -> Bool {
        var flag = true
        for child in batch {
            flag = flag && child.isMapped
        }
        return flag
    }
    
    /**
     run the classification task on the text segment.
     **/
    func runClassification(segment:TextSegment) {
        guard let img = segment.image else {
            return
        }
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(img, from: img.extent)
        let charBlock = UIImage(cgImage:cgImage!)
        self.textClassifier.flatMap {
            classifier in
                classifier.image = charBlock
                classifier.recognize()
            
            guard let txt = classifier.recognizedText else {
                return
            }
            segment.mapText(inText:txt)
            print("Mapped: \(segment.charMapping!)")
        }
        
    }
    
    /**
     select text segments containing the point.
     **/
    func selectSegmentsContaining(point:CGPoint) -> Array<TextSegment> {
        return batch.filter { segment in
            return segment.displayContains(point: point)
        }
    }
    
}
