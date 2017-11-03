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
     it appears that the larger the image, the longer the process takes to operate.
     note also, it is better to pass a whole word image into the library
     as it seems to have some ability to model likely sequences of characters.
     However it would also be interesting to post process the result using perhaps a spell checker
     that could also allocate scores to likely occurances of words in sequence, such as a sliding
     bigram or trigram model.
     One facility that is available is the UITextChecker that may provide some assistance recommendations
     for a supplied text range.
     A bigram or trigram model may need to be constructed independently and loaded as a resource on the device
     in order to obtain scores.
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
