//
//  Capture.swift
//  recogniseobject
//


import Foundation
import AVKit
import MetalKit
import Vision

class Capture {
    
    /**
     initialise capture process and return the input and output devices.
     **/
    func startCapture(session:AVCaptureSession, targetView:UIImageView?, captureDevice:AVCaptureDevice) -> (inputDevice:AVCaptureDeviceInput,outputDevice:AVCaptureVideoDataOutput)? {
        return targetView.map { view in
            let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
            let deviceOutput = AVCaptureVideoDataOutput()
            deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            session.addInput(deviceInput)
            session.addOutput(deviceOutput)
            let imageLayer = AVCaptureVideoPreviewLayer(session: session)
            imageLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            imageLayer.frame = view.bounds
            view.layer.addSublayer(imageLayer)
            
            return (deviceInput, deviceOutput)
        }
    }
    
    /**
     read a CIImage from the sample buffer
     **/
    func readCIImage(sampleBuffer: CMSampleBuffer) -> (flag:Bool, requestOptions:[VNImageOption : Any], ciImage:CIImage) {
        var requestOptions:[VNImageOption : Any] = [:]
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return (false, requestOptions, CIImage())
        }
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return (true, requestOptions, ciImage)
    }
}
