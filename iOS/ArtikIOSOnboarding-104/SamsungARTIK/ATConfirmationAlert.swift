//
//  ATConfirmationAlert.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/15/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

protocol ATConfirmationAlertDelegate {
    func hideConfirmationAlert()
    func confirmButtonAction(action: String)
}

class ATConfirmationAlert: UIView {

    var delegate: ATConfirmationAlertDelegate?
    var titleLabel : UILabel!
    var transparentView : UIView!
    var passwordView : UIView!
    var message: String?
    var action: String?
    var title: String?

    init (frame : CGRect, message: String, action:String, title:String) {
        self.message = message
        self.action = action
        self.title = title

        super.init(frame : frame)
        addBehavior()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBehavior (){
        print("Add all the behavior here")
        
        transparentView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        transparentView.backgroundColor = UIColor.black
        transparentView.alpha = 0.8
        self.addSubview(transparentView)
        
        let subviewsDict: Dictionary = ["transparentView": transparentView];
        
        transparentView.translatesAutoresizingMaskIntoConstraints = false
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrYconstraints)
        
        passwordView = UIView(frame: CGRect(x: self.bounds.size.width/2-140, y: self.bounds.size.height/2-100, width: 280, height: 200))
        passwordView.layer.cornerRadius=5
        passwordView.backgroundColor = Constants.backgroundWhiteColor
        self.addSubview(passwordView)
        
        titleLabel = UILabel(frame:CGRect(x: 0, y: 5, width: passwordView.bounds.size.width, height: 35))
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = Constants.topBottomBarColor
        passwordView.addSubview(titleLabel)
        
        let attachment = NSTextAttachment()
        attachment.image = #imageLiteral(resourceName: "ATConfirmation")
        let offsetY: CGFloat = -0.0
        attachment.bounds = CGRect(x: CGFloat(0), y: offsetY, width: CGFloat((attachment.image?.size.width)!), height: CGFloat((attachment.image?.size.height)!))
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "")
        myString.append(attachmentString)
        let myString1 = NSMutableAttributedString(string: " " + title!)
        myString.append(myString1)
        print("\(myString.length)")
        myString.setAttributes([NSFontAttributeName:titleLabel.font!,NSBaselineOffsetAttributeName:5], range: NSRange(location:1,length:(title?.characters.count)!+1))
        titleLabel.attributedText = myString
        
        // Bottom line for title label
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = Constants.topBottomBarColor.cgColor
        border.frame = CGRect(x: 0, y: titleLabel.frame.size.height - width, width:  titleLabel.frame.size.width, height: 1)
        
        border.borderWidth = width
        titleLabel.layer.addSublayer(border)
        titleLabel.layer.masksToBounds = true
        
        let messagedLabel = UILabel(frame:CGRect(x: 10, y: passwordView.frame.size.height/2 - 50, width: passwordView.bounds.size.width-20, height: 100))
        messagedLabel.text = message
        messagedLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        messagedLabel.numberOfLines = 0
        messagedLabel.textAlignment = .center
        messagedLabel.font = UIFont.systemFont(ofSize: 18)
        messagedLabel.backgroundColor = UIColor.clear
        messagedLabel.textColor = Constants.topBottomBarColor
        passwordView.addSubview(messagedLabel)
        
        let lineView = UIView(frame: CGRect(x: 0, y: passwordView.bounds.size.height-41 , width: passwordView.bounds.size.width, height: 1))
        lineView.backgroundColor = Constants.topBottomBarColor
        passwordView.addSubview(lineView)
        
        let confirmButton = CustomButton(frame:CGRect(x: passwordView.bounds.size.width/2, y: passwordView.bounds.size.height-40, width: passwordView.bounds.size.width/2, height: 40))
        confirmButton.addTarget(self, action: #selector(enterButtonAction), for: UIControlEvents.touchUpInside)
        confirmButton.setTitle(NSLocalizedString("YES", comment: ""), for: .normal)
        confirmButton.backgroundColor = UIColor.clear
        confirmButton.setTitleColor(UIColor.black, for: .normal)
        passwordView.addSubview(confirmButton)
        confirmButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        confirmButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        confirmButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        let pathconfirmButton = UIBezierPath(roundedRect:confirmButton.bounds,
                                byRoundingCorners:[ .bottomRight],
                                cornerRadii: CGSize(width: 5, height:  5))
        let maskLayerconfirmButton = CAShapeLayer()
        maskLayerconfirmButton.path = pathconfirmButton.cgPath
        confirmButton.layer.mask = maskLayerconfirmButton
        
        let cancelButton = CustomButton(frame:CGRect(x: 0, y: passwordView.bounds.size.height-40, width: passwordView.bounds.size.width/2, height: 40))
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: UIControlEvents.touchUpInside)
        cancelButton.setTitle(NSLocalizedString("NO", comment: ""), for: .normal)
        cancelButton.backgroundColor = UIColor.clear
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        passwordView.addSubview(cancelButton)
        cancelButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        cancelButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        cancelButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        let path = UIBezierPath(roundedRect:cancelButton.bounds,
                                byRoundingCorners:[ .bottomLeft],
                                cornerRadii: CGSize(width: 5, height:  5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        cancelButton.layer.mask = maskLayer
        
        // Bottom line for title label
        let sideborder = CALayer()
        sideborder.borderColor = Constants.topBottomBarColor.cgColor
        sideborder.frame = CGRect(x: cancelButton.bounds.size.width-width, y: 0, width:  width, height: cancelButton.bounds.size.height)
        sideborder.borderWidth = width
        cancelButton.layer.addSublayer(sideborder)
        cancelButton.layer.masksToBounds = true
    }
    
    func cancelButtonAction() {
        self.delegate?.hideConfirmationAlert()
    }
    
    func enterButtonAction() {
        self.delegate?.confirmButtonAction(action: action!)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
