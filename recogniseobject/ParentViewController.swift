//
//  ViewController.swift
//  recogniseobject
//


import UIKit
import MetalKit
import AVFoundation
import Vision
import TesseractOCR
import AudioToolbox.AudioServices

class ParentViewController:
UIViewController,
AVCaptureVideoDataOutputSampleBufferDelegate,
WithLock {
    
   
    @IBOutlet var navBar:UINavigationBar!
    
    @IBOutlet var streamView:UIImageView!
    
    @IBOutlet weak var imagePreview:UIImageView!
    
    @IBOutlet weak var textView:UITextView!
    
    /**
     the capture device.
     **/
    lazy var captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    
    /**
     the av capture session.
     **/
    let session = AVCaptureSession()
    
    /**
     the device speech synthesizer
     **/
    let speech = AVSpeechSynthesizer()
    
    /**
     selection feedback is used to indicate to the user that their touches have moved into a word boundary.
     **/
    let selectFeedback = UISelectionFeedbackGenerator()
    
    let context = CIContext()
    
    let capture:Capture =  Capture()
    
    /**
     iOS Tesseract OCR library
     default language is english
     **/
    var tesseract:G8Tesseract = G8Tesseract(language:"eng")
    
    /**
     Internal lock used to prevent multiple batches queueing.
     Note a queue construct would be suitable to use in queuing batches.
     **/
    var lockObj:NSLock = NSLock()
    
    
    /**
     a flag used to indicate is a batch is actively being processed.
     note a queue would be a better mechanism for this purpose.
     **/
    var batchActive:Bool = false
    
    /**
     internal mutable collection of active batches of word segments.
     **/
     var batches = Array<TextSegmentBatch>()
    
    /**
     this is the default capture orientation of the device.
     when processing images they are processed with respect to this orientation
     **/
    let defaultCaptureOrientation:CGImagePropertyOrientation = .right
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "Recognise Text Object"
        
        let (input, output) = captureDevice.flatMap {
            device in
            return capture.startCapture(session: session,
                                                   targetView: streamView,
                                                   captureDevice: device)
            
            }!
     output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
     session.startRunning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.selectFeedback.prepare()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach {
            touch in
            let loc = touch.location(in:self.streamView)
            let selectFn = self.withLock {
                let temp = Array<TextSegmentBatch>(self.batches)
                let matches = temp.filter {
                    batch in
                    let candidates = batch.selectSegmentsContaining(point: loc)
                    return candidates.count > 0
                }
                if (matches.count > 0) {
                    let vibrate = SystemSoundID(kSystemSoundID_Vibrate)
                    AudioServicesPlaySystemSound(vibrate)
                    self.selectFeedback.selectionChanged()
                }
            }
        }
    }
    
    /**
     if the user touches the screen where there is an active word selection area
     then the device should read the text and announce it.
     **/
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach {
            touch in
            let loc = touch.location(in: self.streamView)
            let selectFn = self.withLock {
                let temp = Array<TextSegmentBatch>(self.batches)
                temp.forEach {
                    batch in
                    let candidates = batch.selectSegmentsContaining(point: loc)
                    self.transcribeAndAnnounce(parentBatch:batch, segments:candidates)
                }
            }
            selectFn()
        }
    }
    
    /**
     using the image perform OCR extract the text and announce it if it is available.
     **/
    func transcribeAndAnnounce(parentBatch:TextSegmentBatch, segments:Array<TextSegment>) {
        let transcriptions:Array<String> = segments.map {
            segment in
            parentBatch.runClassification(segment: segment)
            if let text = segment.charMapping {
                segment.image.flatMap {
                    img in
                    self.transferSegmentToImagePreview(segment:segment,newImg: img)
                }
                // there is a character mapping then put it on the tts queue.
                return text
            } else { return "" }
        }
        let displayText = ""+transcriptions.filter {
            text in
            return !text.isEmpty
        }.joined(separator:" ")
        // update and announcement.
        DispatchQueue.main.async {
            self.textView!.text = displayText
            self.textView!.setNeedsDisplay()
            
            if (!displayText.isEmpty && displayText != " ") {
                print("Debug Speak: \(displayText)")
                let utterance = AVSpeechUtterance(string: displayText)
                self.speech.speak(utterance)
            }
        }
       
    }
    
    /**
     Implementation of the AVCaptureVideoDataOutputSampleBufferDelegate method
     for captured frames.
     **/
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let (flag, requestOptions, ciImage) = capture.readCIImage(sampleBuffer: sampleBuffer)
        // perform the image recognition for text.
        if (!flag) {
            return;
        }
        let pixelBuffer = ciImage.pixelBuffer
        
        //let orient = imageOrientation(forDevicePosition: captureDevice!.position, deviceOrientation: UIDevice.current.orientation)
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!,
                                                        orientation: self.defaultCaptureOrientation,
                                                        options: requestOptions)
        
        do {
            let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler(ciImage: ciImage))
            textRequest.reportCharacterBoxes = true
            try imageRequestHandler.perform([textRequest])
        } catch {
            print(error)
        }
    }
   
    
    func textRectangleToSegment(boxRect:CGRect) -> TextSegment {
        var uiRect = CGRect()
        var uiTransform = CGAffineTransform(scaleX:1, y:1)
        DispatchQueue.main.sync() {
            uiRect = self.streamView!.layer.sublayers![0].bounds
        }
        
        let scaleX = uiRect.width
        let scaleY = uiRect.height
        
        // we want the scaled rectangle for the drawing area.
        // the input rect is actually a normalised rectangle with values 0 <= i <= 1.
        // when we use the full bounds below, this scales the rect as a proportion of the
        // full bounds.
        // ordinarily we'd need to calculate the proportions and scale by proportions, however
        // in this case the proportion is the rectangle being scaled.
        let transform = CGAffineTransform(scaleX:CGFloat(scaleX), y:CGFloat(scaleY))
        
        let tempRect = boxRect.applying(transform)
        let scaledRect = CGRect(x:tempRect.origin.x,
                                y:tempRect.origin.y,
                                width:tempRect.width,
                                height:tempRect.height)
 
        let debug = String(format:"x:%f y:%f width:%f height:%f",
                           boxRect.minX,
                           boxRect.minY,
                           boxRect.width,
                           boxRect.height)
        
        print(debug)
        
        let debug2 = String(format:"SCALED: x:%f y:%f width:%f height:%f",
                            scaledRect.minX,
                            scaledRect.minY,
                            scaledRect.width,
                            scaledRect.height)
        
        print(debug2)
        
        return TextSegment(inRect: boxRect, inScaledRect: scaledRect)
    }
    
    
    func textRectangleToSegment(box:VNRectangleObservation) -> TextSegment {
       let boxRect = box.boundingBox
        return self.textRectangleToSegment(boxRect:boxRect)
    }
    
    
    /**
     extract the character froom the source image and preprocess it.
     **/
    func extractSegment(segment:TextSegment, image:CIImage) -> CIImage? {
        // rotate to default capture orientation which is right
        let temp = image.oriented(self.defaultCaptureOrientation)
        
        let sourceBounds = temp.extent
        let transform = CGAffineTransform(scaleX:CGFloat(sourceBounds.width), y:CGFloat(sourceBounds.height))
        let sampleRect = segment.rect!.applying(transform)
        
        let newImg = temp
            .cropped(to:sampleRect)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 0.5
                ])
            .applyingFilter("CIMaximumComponent")
            .applyingFilter("CIColorPosterize",
                            parameters: [
                                "inputLevels": 6.0
                ])
            .applyingFilter("CIColorMonochrome",
                            parameters: [
                                "inputColor":CIColor.white,
                                "inputIntensity":1.1
                ])
            
            // TODO: determine if image requires invert based on dominant colour (dark or light)
            .applyingFilter("CIColorInvert", parameters:[:])
        
        
        
        guard let scaled = self.context.createCGImage(newImg, from: newImg.extent) else {
            return nil
        }
        
        return CIImage(cgImage: scaled)
    }
    
    /**
     display the word boundary on the av image.
     **/
    func transferSegmentToWordBoundary(segment:TextSegment, borderCol:CGColor = UIColor.blue.cgColor,
                                       fillCol:CGColor? = nil) {
        // update the ui
        DispatchQueue.main.async() {
            // scale the original bounds by the current view transform
            var bounds = self.streamView!.layer.sublayers![0].bounds
            
            let newFrame = CGRect(x:segment.scaledRect!.origin.x,
                                  y:bounds.height - segment.scaledRect!.origin.y - segment.scaledRect!.height,
                                  width:segment.scaledRect!.width,
                                  height:segment.scaledRect!.height)
            
            segment.displayRect = newFrame
            
            let outline = CALayer()
            outline.frame = newFrame
            outline.borderWidth = 1.0
            outline.borderColor = borderCol
            
            fillCol.map {
                col in
                outline.backgroundColor = col
            }
            
            self.streamView!.layer.addSublayer(outline)
        }
    }
    
    // extract the character from the supplied image and display it in the image preview
    func transferSegmentToImagePreview(segment:TextSegment, newImg:CIImage) {
        
        guard let scaled = self.context.createCGImage(newImg, from: newImg.extent) else {
            return
        }
        // update the ui
        DispatchQueue.main.async() {
            
            let img = UIImage(cgImage:scaled)
            self.imagePreview.image = img
        }
    }
    
    /**
     process the word segment.
     **/
    func processSegment(ciImage:CIImage, segment:VNTextObservation?, accum:Array<TextSegmentBatch>) -> TextSegmentBatch {
        let localBatch = TextSegmentBatch(model:self.tesseract)
        // read the image for the bounding box.
        guard let word = segment?.boundingBox else {
            return localBatch
        }
        let wordSegment = self.textRectangleToSegment(boxRect:word)
        
        guard let wordImg = self.extractSegment(segment:wordSegment, image:ciImage) else {
            return localBatch
        }
        wordSegment.image = wordImg
        
        let bgCol = Optional(
            UIColor(red:1.0, green:0.0, blue:0.0, alpha:0.5).cgColor )
        
        self.transferSegmentToWordBoundary(segment: wordSegment,
                                           borderCol:UIColor.red.cgColor,
                                           fillCol:bgCol)
        
        // store it in the batch.
        localBatch.batch.append(wordSegment)
        return localBatch
    }
    
    /**
     next step is to process the text rectangles.
     extract each character and display it in the image preview.
     
     after that move onto the MNist recognition stage.
     
     Each recognition result contains a single word.
     
     **/
    func detectTextHandler(ciImage:CIImage) -> (VNRequest, Error?) -> Void {
        return  { (_ request: VNRequest, _ error: Error?) in
            
            let runInLock = self.withLock {
                if (self.batchActive)
                {
                    // do not process recognition results if we are already busy
                    // processing the last batch.
                    return
                }
                
                DispatchQueue.main.sync() {
                    self.streamView!.layer.sublayers?.removeSubrange(1...)
                }
                
                guard let eventResults = request.results else {
                    return
                }
                let textSegments = eventResults.map { result in
                    result as? VNTextObservation
                    }.filter { (_ test:VNTextObservation?) in
                        return (test != Optional.none)
                }
                self.batchActive = true
                self.batches = Array<TextSegmentBatch>()
                for segment in textSegments {
                    let localBatch = self.processSegment(ciImage:ciImage,
                                        segment:segment,
                                        accum:self.batches)
                    
                    
                    if (localBatch.batch.count > 0) {
                        // processing segments
                        self.batches.append(localBatch)
                        // TODO: we need to accumulate the results of each batch for feedback in the UI.
                    }
                }
                self.batchActive = false
            }
            runInLock()
        }
    }
    

}

extension UIViewController {
    
    
}

