//
//  ATAlertView.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/15/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

@objc protocol ATAlertViewDelegate {
    func hideAlert()
}

class ATAlertView: UIView {
    
    var delegate: ATAlertViewDelegate?
    var transparentView : UIView!
    var alertView : UIView!
    var message: String?
    var cancelButtonTitle: String?
    var confirmButtonTitle: String?
    
    init(frame: CGRect, message: String, cancelButtonTitle: String, confirmButtonTitle: String) {
        super.init(frame: frame)

        self.message = message
        self.cancelButtonTitle = cancelButtonTitle
        self.confirmButtonTitle = confirmButtonTitle
        
        addBehavior()
    }
    
    required init(coder aDecoder: NSCoder) {
        //super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBehavior() {
        print("Add all the behavior here")
        
        self.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        
        transparentView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        transparentView.backgroundColor = UIColor.black
        transparentView.alpha = 0.8
        self.addSubview(transparentView)
        
        //Setting up constraints
        let subviewsDict: Dictionary = ["transparentView": transparentView]
        
        transparentView.translatesAutoresizingMaskIntoConstraints = false
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrYconstraints)
        
        alertView = UIView(frame: CGRect(x: self.bounds.size.width/2-150, y: self.bounds.size.height/2-120, width: 300, height: 260))
        alertView.layer.cornerRadius=5
        alertView.backgroundColor = Constants.topBottomBarColor
        self.addSubview(alertView)
        
        let alertImageView = UIImageView(frame: CGRect(x: alertView.frame.size.width/2 - 12, y: 5, width: 30, height: 34))
        alertImageView.image = #imageLiteral(resourceName: "ATError")
        alertView.addSubview(alertImageView)
        
        let alertContentView = UIView(frame: CGRect(x: 0, y: alertImageView.frame.size.height + alertImageView.frame.origin.y + 5, width: alertView.frame.size.width, height: 165))
        alertContentView.backgroundColor = UIColor.white
        alertView.addSubview(alertContentView)
        
        let alertMessageLabel = UILabel(frame: CGRect(x: 20, y: alertContentView.frame.origin.y + 5, width: alertContentView.frame.size.width - 40, height: 155))
        alertMessageLabel.textAlignment = .center
        alertMessageLabel.numberOfLines = 0
        alertMessageLabel.baselineAdjustment = .alignCenters
        alertMessageLabel.text = message
        alertMessageLabel.font = UIFont.systemFont(ofSize: 18.0)
        alertMessageLabel.textColor = Constants.topBottomBarColor
        alertView.addSubview(alertMessageLabel)
        
        let cancelButton = CustomButton(frame:CGRect(x: alertView.frame.size.width/2 - 80, y: alertContentView.frame.size.height + alertContentView.frame.origin.y + 5, width: 160, height: 40))
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: UIControlEvents.touchUpInside)
        cancelButton.setTitle(cancelButtonTitle, for: .normal)
        cancelButton.layer.cornerRadius = 5
        cancelButton.backgroundColor = UIColor.white
        cancelButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        alertView.addSubview(cancelButton)
        cancelButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        cancelButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        let path = UIBezierPath(roundedRect:cancelButton.bounds,
                                byRoundingCorners:[ .bottomLeft , .bottomRight, .topLeft, .topRight],
                                cornerRadii: CGSize(width: 5, height:  5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        cancelButton.layer.mask = maskLayer
        
        if confirmButtonTitle != "" {
            cancelButton.frame = CGRect(x: 10, y: alertContentView.frame.size.height + alertContentView.frame.origin.y + 5, width: alertView.frame.size.width/2 - 20, height: 40)
            
            let confirmButton = CustomButton(frame:CGRect(x: alertView.frame.size.width/2 + 10, y: cancelButton.frame.origin.y, width: cancelButton.frame.size.width, height: 40))
            confirmButton.addTarget(self, action: #selector(confirmButtonAction), for: UIControlEvents.touchUpInside)
            confirmButton.setTitle(confirmButtonTitle, for: .normal)
            confirmButton.layer.cornerRadius = 5
            confirmButton.backgroundColor = UIColor.white
            confirmButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
            confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            alertView.addSubview(confirmButton)
            confirmButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
            confirmButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
            let path = UIBezierPath(roundedRect:confirmButton.bounds,
                                    byRoundingCorners:[ .bottomLeft , .bottomRight, .topLeft, .topRight],
                                    cornerRadii: CGSize(width: 5, height:  5))
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            confirmButton.layer.mask = maskLayer
        }
    }
    
    func cancelButtonAction() {
        self.delegate?.hideAlert()
    }
    
    func confirmButtonAction() {
        self.delegate?.hideAlert()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
}
