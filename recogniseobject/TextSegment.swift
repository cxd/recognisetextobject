//
//  TextSegment.swift
//  recogniseobject
//

import Foundation
import UIKit

class TextSegment {
    
    var rect:CGRect?
    
    var scaledRect:CGRect?
    
    var displayRect:CGRect?
    
    var charMapping:String?
    
    var isMapped:Bool = false
    
    /**
     a corresponding CIImage from the source that represents
     this particular segment.
     **/
    var image:CIImage?
    
    init() {
        
    }
    
    convenience init(inRect:CGRect, inScaledRect:CGRect) {
        self.init()
        rect = inRect
        scaledRect = inScaledRect
    }
    
    convenience init(inRect:CGRect, inScaledRect:CGRect, inText:String) {
        self.init()
        rect = inRect
        scaledRect = inScaledRect
        charMapping = inText
        isMapped = true
    }
    
    /**
     when results are finalised the mapping for the text is provided.
     **/
    func mapText(inText:String) {
        charMapping = inText
        isMapped = true
    }
    
    /**
     determine if a point is contained within the display rectangle
     **/
    func displayContains(point:CGPoint) -> Bool {
        if let rect = self.displayRect {
            let flag = rect.contains(point)
            var text=""
            if let t = self.charMapping {
                text=t
            }
            print("Debug: Rect (\(rect.origin.x), \(rect.origin.y), \(rect.size.width + rect.origin.x), \(rect.size.height + rect.origin.y)) contains \(flag) point:(\(point.x), \(point.y)) Text:\(text))")
            return flag
        }
        return false
    }
    
    
    
}
