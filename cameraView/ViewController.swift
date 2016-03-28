//
//  ViewController.swift
//  cameraView
//
//  Created by Chojaeyoung on 2016. 2. 19..
//  Copyright © 2016년 Chojaeyoung. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

//https://sungkipyung.wordpress.com/2014/10/16/ios-ciimage-cgimage-uiimage-%EC%B0%A8%EC%9D%B4%EC%A0%90/
//https://medium.com/@ranleung/uiimage-vs-ciimage-vs-cgimage-3db9d8b83d94#.6z97n8f5d
//UIImage, CGImage, ,CIImage


//  1. [!]bitmap정보를 먼저 얻는게 우선.
//      - 동영상 filter관련 소스를 참고 하면 좋다.
//  2. 주변 값들의 평균을 내주어야 한다.
//  3. 시간상의 평균도 내주어야 한다. 프레임 단위.
//  4. 성능을 높이려면 스레드로 사용해도 좋다.


enum currentStatus: Int {
    case Preview, Still
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var cameraQueue : dispatch_queue_t?
    
    @IBOutlet weak var previewView: UIView!
//    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureSession: AVCaptureSession?
    //이미지 캡처를 위해 객체 생성
    var stillImageOutput: AVCaptureStillImageOutput?
    
    @IBOutlet weak var rgbaLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var stillImageView: UIImageView!
    
    @IBOutlet weak var stilllButton: UIButton!
    
    //카메라의 현재 상태를 알기 위해, status 변수 사용.
    var status: currentStatus = .Preview
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  z포지션을 주어 imageView 레이어의 포지션을 위로 변경.
        self.imageView.layer.zPosition = 1.0
//                    addSubview(pointImageView)
        self.stillImageView.alpha = 0.0
        self.previewView.alpha = 1.0
        self.stilllButton.layer.zPosition = 1.0
        
    }
    
    //시점으로 인해, viewDidAppear함수에서 addPreviewLayer함수를 호출.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        addPreviewLayer()
        print("subviews=",self.view.subviews)
        print("preview=",previewView)
        
        let pointImage = UIImage(named: "point.png")
        print("pointImage=",pointImage)
        let pointImageView = UIImageView(image:pointImage)
        
        let x = self.view.frame.size.width / 2
        let y = self.view.frame.size.height / 2
        pointImageView.center.x = x
        pointImageView.center.y = y
        previewView.addSubview(pointImageView)
    }
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addPreviewLayer() {
        //AVCapture 객체생성
        captureSession = AVCaptureSession()
        
        //캡처사진을 설정
        //captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        captureSession!.sessionPreset = AVCaptureSessionPreset640x480
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
            captureSession!.beginConfiguration()
            // Remove an existing capture device.
            // Add a new capture device.
            // Reset the preset.
            
            self.addStillImageOutput()

            captureSession!.commitConfiguration()
            captureSession!.addInput(input)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait

            previewLayer?.frame = previewView.bounds
            previewView.layer.addSublayer(previewLayer!)
            
            print("preview width=",previewView.frame.size.width,"preview height=",previewView.frame.size.height)
            
//            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//            view.layer.addSublayer(previewLayer)
            /* ======================================================================================== */
            
            let videoOutput = AVCaptureVideoDataOutput()
            cameraQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
            videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
            
            //[Q]아래 코드는 무엇을 하는 코드인가?
            //RGBA타입으로 하면 에러 발생.
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : UInt(kCVPixelFormatType_32BGRA)]
   
            //[Q]아래 코드는 무엇을 하는 코드인가?
            //->아래 코드는 vieodOutput을 동작시키는 코드
            if captureSession!.canAddOutput(videoOutput)
            {
                captureSession!.addOutput(videoOutput)
            }
        
            /* ======================================================================================== */
            captureSession!.startRunning()
            
            
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        //CIImage를 얻었으니 UIImage로 변환가능.
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        print("CIImage",cameraImage)
        
        //UIImage로 변환.
        let cameraUIImage = UIImage(CIImage: cameraImage)
        
        //CIcontext를 이용해서 하는 방법을 찾아 보자.

        print(cameraUIImage)
        print("capture output test1")
        
        let image = imageFromSampleBuffer(sampleBuffer)

        print("return is image=",image)
        //preview 사이즈는 320, 568이다. 그러나 이미지의 사이즈는 852,640이다.
        //왜 이미지의 사이즈가 커진 것인가?
        //[A]size가 커진게 아니라, 비율탓인듯. 
        //비율을 계산해보니, width는 2:1로 크고 height 는 3:2로 크다?
        //그렇다면 값을 얻어올 좌표도 비율로 계산이 되어야 한다.
        
        //-> AVcapture옵션을 변경하니 바뀌었다. 640x480
    
        let scalePixelPoint = CGPoint(x: 320, y: 476)
//        let gotUIColorValue :UIColor = getPixelColor(image,pos: scalePixelPoint)
//        let gotUIColorValue2 = colorForPixel(image,x: 320,y: 476)
        let gotUIColorValue2 = colorForPixel(image,x: 320,y: 240)
        
        print("rgbaLabel",gotUIColorValue2)
        print("capture output test3, color_tmp=",gotUIColorValue2)
        
        dispatch_async(dispatch_get_main_queue())
        {
            
                 self.imageView.backgroundColor = gotUIColorValue2
        }
    }
    
    //기존에 사용하던 버퍼를 사용해 이미지를 가져와 표현하도록 하자.
    
    @IBAction func cameraStillButton(sender: AnyObject) {
        if self.status == .Preview {
//            UIView.animateWithDuration(0.225, animations: { () -> Void in
                self.previewView.alpha = 0.0;
//            })
            
            captureStillImage({ (image) -> Void in
                print("catureImage test image=",image)
                if image != nil {
                    print("###################################################")
                    print("in if image")
                    self.stillImageView.image = image;
                    
//                    UIView.animateWithDuration(0.225, animations: { () -> Void in
                        self.stillImageView.layer.zPosition = 1.0
                        self.stillImageView.alpha = 1.0;
                        
//                    })
                    self.status = .Still
                }
            })
        }
    }
    
    func captureStillImage(completed: (image: UIImage?) -> Void) {
        if let imageOutput = self.stillImageOutput {
            dispatch_async(self.cameraQueue!, { () -> Void in
                print("test1")
                var videoConnection: AVCaptureConnection?
                for connection in imageOutput.connections {
                    print("test2")
                    let c = connection as! AVCaptureConnection
                    print("test3 c=",c)
                    for port in c.inputPorts {
                        print("test4 c=",c)
                        let p = port as! AVCaptureInputPort
                        if p.mediaType == AVMediaTypeVideo {
                            videoConnection = c;
                            break
                        }
                    }
                    print("test5 videoConnection=",videoConnection)
                    if videoConnection != nil {
                        break
                    }
                }
                
                if videoConnection != nil {
                    imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (imageSampleBuffer: CMSampleBufferRef!, error) -> Void in
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        let image: UIImage? = UIImage(data: imageData!)!
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completed(image: image)
                        }
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completed(image: nil)
                    }
                }
            })
        } else {
            completed(image: nil)
        }
    }

    
    func addStillImageOutput() {
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if self.captureSession!.canAddOutput(stillImageOutput) {
            captureSession!.addOutput(stillImageOutput)
        }
    }
    
    /* 인자로 받은 UIImage의 특정좌표의 값의 컬러를 반환하는 함수 */
    func getPixelColor(Image:UIImage, pos: CGPoint) -> UIColor {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(Image.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let imageWidth = CGImageGetWidth(Image.CGImage)
        let imageHeight = CGImageGetHeight(Image.CGImage)
        let bytePerPixel = CGImageGetBitsPerPixel(Image.CGImage) / 8
        
        print("bytePerPixel=",bytePerPixel, "imageWidth=",imageWidth,"imageHeight=",imageHeight)
        //아래 계산식, 왜 저렇게 되는 걸까? * 4는 왜 하는 것일까?
        //[A] * 4의 의미는 컬러 성분들의 개수.
        let pixelInfo: Int = ((Int(Image.size.width) * Int(pos.y)) + Int(pos.x)) * 4
//        let pixelInfo:Int = data + (imageWidth * (imageHeight - Int(pos.y)) + Int(pos.x)) * bytePerPixel
        
        
        //bgra
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /* 수석님 함수 */
    func colorForPixel(image: UIImage, x: Int, y: Int) -> UIColor {
        let cgImage =  image.CGImage
        
        let imageWidth = CGImageGetWidth(cgImage)
        let imageHeight = CGImageGetHeight(cgImage)
        let bytesPerPixel = CGImageGetBitsPerPixel(cgImage) / 8
        print("bytesPerPixel=",bytesPerPixel, "imageWidth=",imageWidth,"imageHeight=",imageHeight)
        //print("\(imageWidth) x \(imageHeight) x \(bytesPerPixel)")
        
        let pixelData:CFData! = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
        let data:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        // CGImage is flipped. So (imageHeight - y) is needed.
        let pixelValue = data + (imageWidth * (imageHeight - y) + x) * bytesPerPixel
//        let pixelValue = data + ((imageWidth * y) + x) * bytesPerPixel
        
        // kCVPixelFormatType_32BGRA
        let blue  = CGFloat(pixelValue[0])
        let green = CGFloat(pixelValue[1])
        let red   = CGFloat(pixelValue[2])
        let alpha = CGFloat(pixelValue[3])
        
        return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha / 255)
    }

    /* 수석님 함수 */
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer:CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        print("수석님 코드 테스트1")
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        print("수석님 코드 테스트2")
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddress(imageBuffer)
        print("수석님 코드 테스트3")
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        print("수석님 코드 테스트4")
        let width = CVPixelBufferGetWidth(imageBuffer)
        print("수석님 코드 테스트5")
        let height = CVPixelBufferGetHeight(imageBuffer)
        print("수석님 코드 테스트6")
        print("width=",width,"height=",height)
        //width가 852, height가 640이다. [Q]왜?
        
        //점을 찍어서 테스트를 해보아도 된다.
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        print("수석님 코드 테스트7")
        
        // Create a bitmap graphics context with the sample buffer data
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
                print("수석님 코드 테스트8")
        let quartzImage = CGBitmapContextCreateImage(context)
                print("수석님 코드 테스트9")
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
                print("수석님 코드 테스트10")
        
        // Create an image object from the Quartz image
        let image = UIImage(CGImage:quartzImage!)
                print("수석님 코드 테스트11")
        
        return (image);
    }

}