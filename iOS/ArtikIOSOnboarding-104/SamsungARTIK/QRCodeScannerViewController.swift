//
//  QRCodeScannerViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/2/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ATAlertViewDelegate {
    
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var titleTextField: TitlesTextField!
    var alertView: ATAlertView!
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var UUIDString: String!
    let supportedBarCodes = [AVMetadataObjectTypeQRCode]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        bottomLabel.text = NSLocalizedString("Center the QR code in the window.\nThe UUID will be captured automatically.", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.startReading()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if videoPreviewLayer != nil {
            videoPreviewLayer?.frame = scannerView.bounds
        }
    }
    
    func startReading() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = scannerView.bounds
            scannerView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
        } catch {
            print(error)
            return
        }
    }
    
    func stopReading() {
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer?.removeFromSuperlayer()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            print("No QR code is detected")
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedBarCodes.contains(metadataObj.type) {
            //let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            
            if metadataObj.stringValue != nil {
                self.stopReading()
                let infoStr = metadataObj.stringValue
                print("QR code value is : \(infoStr)")
                
                let valArray = infoStr?.components(separatedBy: ",")
                UUIDString = valArray?.last
                if ATUtilities.validateQR(qrString: infoStr!) == true {
                    print("Valid QR code")
                    
                    let artikIdentifiedControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "ArtikModuleIdentifiedViewController") as! ArtikModuleIdentifiedViewController
                    artikIdentifiedControllerObj.isFromManual = false
                    artikIdentifiedControllerObj.uuidString = infoStr
                    artikIdentifiedControllerObj.bleMac = UUIDString
                    self.navigationController!.pushViewController(artikIdentifiedControllerObj, animated: true)
                }
                else {
                    self.showAlert()
                }
            }
        }
    }
    
    func hideAlert() {
        self.startReading()
        alertView.removeFromSuperview()
    }
    
    func showAlert() {
        
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: NSLocalizedString("Your QR code is incorrect. Please scan again!", comment: "") , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
        alertView.delegate = self
        alertView.backgroundColor = UIColor.clear
        self.view.addSubview(alertView)
        
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["alertView": alertView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[alertView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
