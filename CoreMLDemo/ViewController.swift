//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Sai Kambampati on 14/6/2017.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import CoreML
import  Photos


class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classifier: UILabel!
    var model: Inceptionv3!
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model = Inceptionv3();
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func camera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let status = PHPhotoLibrary.authorizationStatus()
        print("\(status)")
        
        if (status == PHAuthorizationStatus.authorized) {
            self.openimagepickerGallery()
        }
            
        else if (status == PHAuthorizationStatus.denied) {
            self.showerrormessageonGalleryopenRequest()
        }
            
        else if (status == PHAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    
                    self.openimagepickerGallery()
                }
                else {
                    
                    self.showerrormessageonGalleryopenRequest()
                }
            })
        }
            
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
      
    }
    
    func openimagepickerGallery(){
        let pickerController  = UIImagePickerController()
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: nil)
    }
    func showerrormessageonGalleryopenRequest(){
        
        let alert =  UIAlertController(title: "Access denied", message: "Please go to setting and give permission to access your photos to use our app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go To settings", style: .default) { action in
            
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
            
        })
        alert.addAction(UIAlertAction(title: ":Cancle", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        
    }

}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        classifier.text = "Analyzer Image .........."
        guard let image  = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        UIGraphicsBeginImageContextWithOptions( CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage  = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
         let context  =   CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imageView.image = newImage
        
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        classifier.text = "I think this is a \(prediction.classLabel)."
        
    }
}























