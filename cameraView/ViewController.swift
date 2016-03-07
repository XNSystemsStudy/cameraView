//
//  ViewController.swift
//  cameraView
//
//  Created by Chojaeyoung on 2016. 2. 19..
//  Copyright © 2016년 Chojaeyoung. All rights reserved.
//

import UIKit
import AVFoundation

extension UIView {
    func getColourFromPoint(uiView:UIView, point:CGPoint) -> UIColor {
        let colorSpace:CGColorSpace? = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.rawValue.fromRaw(CGImageAlphaInfo.PremultipliedLast.toRaw())!

        var pixelData:[UInt8] = [0, 0, 0, 0]
        
        let context = CGBitmapContextCreate(&pixelData, 1, 1, 8, 4, colorSpace, bitmapInfo)
        CGContextTranslateCTM(context, -point.x, -point.y);
        self.layer.renderInContext(context)
        
        var red:CGFloat = CGFloat(pixelData[0])/CGFloat(255.0)
        var green:CGFloat = CGFloat(pixelData[1])/CGFloat(255.0)
        var blue:CGFloat = CGFloat(pixelData[2])/CGFloat(255.0)
        var alpha:CGFloat = CGFloat(pixelData[3])/CGFloat(255.0)
        
        var color:UIColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
}

//  1. [!]bitmap정보를 먼저 얻는게 우선.
//      - 동영상 filter관련 소스를 참고 하면 좋다.
//  2. 주변 값들의 평균을 내주어야 한다.
//  3. 시간상의 평균도 내주어야 한다. 프레임 단위.
//  4. 성능을 높이려면 스레드로 사용해도 좋다.

class ViewController: UIViewController, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var previewView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var captureSession: AVCaptureSession?
    
    @IBOutlet weak var previewSmallView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //z포지션을 주어 previewSmallView 레이어의 포지션을 위로 변경.
        self.previewSmallView.layer.zPosition = 1.0
    }
    
    //시점으로 인해, viewDidAppear함수에서 addPreviewLayer함수를 호출.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        addPreviewLayer()
    }
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addPreviewLayer() {
        print("test")
        //AVCapture 객체생성
        captureSession = AVCaptureSession()
        //캡처사진을 설정
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        print("test222")
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        print("test333")
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        print("test4444")
        if error == nil && captureSession!.canAddInput(input) {
            captureSession?.beginConfiguration()
            // Remove an existing capture device.
            // Add a new capture device.
            // Reset the preset.
            captureSession?.commitConfiguration()
            

            captureSession!.addInput(input)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
            
            previewLayer?.frame = previewView.bounds
            previewView.layer.addSublayer(previewLayer!)
            
            captureSession!.startRunning()
            
            
        }
    }
    
}


