//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController {
    
    var uiView:UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        
        
        let uiImage = UIImage(named:"smashing-baby-yeah.jpg")
        
        self.uiView = UIImageView()
        uiView.image = uiImage
        
        let ciImage = CIImage(image: uiImage!)
        
        uiView.frame = CGRect(x:10,
                              y:100,
                              width:250,
                              height:200)
        view.addSubview(uiView)
        
        let newImg = ciImage!
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
            .applyingFilter("CIColorInvert", parameters:[:])
        
        uiView.image = UIImage(ciImage:newImg)
        
        
        var histView = UIImageView()
        
        histView.frame = CGRect(x:10,
                                y:350,
                                width:200,
                                height:100)
        histView.backgroundColor = UIColor.black
        
        view.addSubview(histView)
        
        let rect = newImg.extent
        
        let histImg = ciImage!.applyingFilter(
            "CIAreaHistogram",
            parameters:[
                "inputImage":newImg,
                "inputScale":1,
                "inputCount":256,
                "inputExtent":CIVector(cgRect:rect)
            ]).applyingFilter(
        "CIHistogramDisplayFilter")
        
        histView.image = UIImage(ciImage:histImg)
        
        self.view = view
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
