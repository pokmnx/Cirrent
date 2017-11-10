//
//  ProgressView.swift
//  Cirrent_New
//
//  Created by PSIHPOK on 12/17/16.
//  Copyright © 2016 PSIHPOK. All rights reserved.
//

import Foundation
import UIKit
import JGProgressHUD

class ProgressView {
    static let sharedView : ProgressView = ProgressView()
    var progressHUD:JGProgressHUD? = nil
    static let DEFAULT_DELAY:TimeInterval = 3.0
    
    init() {
        
    }
    
    func showToast(view:UIView, message:String, duration:TimeInterval = 0) {
        dismissProgressView()
        progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.indicatorView = nil
        progressHUD?.textLabel.text = message
        progressHUD?.show(in: view)
        if duration == 0 {
            progressHUD?.dismiss(afterDelay: ProgressView.DEFAULT_DELAY)
        }
        else {
            progressHUD?.dismiss(afterDelay: duration)
        }
    }
    
    func changeMessage(message:String) {
        if progressHUD != nil {
            progressHUD?.textLabel.text = message
        }
    }
    
    func showProgressView(view:UIView, message:String? = nil) {
        dismissProgressView()
        progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = message
        progressHUD?.show(in: view)
    }
    
    @objc func dismissProgressView(completion:(() -> Void)? = nil) {
        if progressHUD != nil {
            progressHUD?.dismiss()
            
            if completion != nil {
                completion!()
            }
        }
    }
    
    func showAlert(viewController:UIViewController, title:String? = nil, message:String, activeTitle:String? = nil, activeAction: ((UIAlertAction) -> Void)? = nil, deactiveTitle:String? = nil, deactiveAction: ((UIAlertAction) -> Void)? = nil, completion:(() -> Void)? = nil) {
        dismissProgressView()
        let alertController:UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if activeTitle != nil {
            let active = UIAlertAction(title: activeTitle, style: .default, handler: activeAction)
            alertController.addAction(active)
        }
        
        if deactiveTitle != nil {
            let deactive = UIAlertAction(title: deactiveTitle, style: .cancel, handler: deactiveAction)
            alertController.addAction(deactive)
        }
        
        if activeTitle == nil && deactiveTitle == nil {
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
        }
        
        viewController.present(alertController, animated: true, completion: completion)
    }
}
