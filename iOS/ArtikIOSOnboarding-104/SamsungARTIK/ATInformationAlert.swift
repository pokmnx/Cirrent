//
//  ATConfirmationAlert.swift
//  SamsungARTIK
//
//  Created by Surendra on 12/15/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

protocol ATInformationAlertDelegate {
    func okButtonAction()
}

class ATInformationAlert: UIView {
    
    var delegate: ATInformationAlertDelegate?
    var titleLabel : UILabel!
    var transparentView : UIView!
    var passwordView : UIView!
    
    init (frame : CGRect, moduleDate : String , moduleName : String , moduleLocation : String) {
        super.init(frame : frame)
        addBehavior(moduleDate : moduleDate , moduleName : moduleName , moduleLocation : moduleLocation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getDate(unixdate: String) -> String {
        if Int(unixdate) == 0 {return ""}
        let date = NSDate(timeIntervalSince1970: TimeInterval(Int(unixdate)!))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "dd/MM/YYYY"
        dayTimePeriodFormatter.timeZone = TimeZone.current
        let dateString = dayTimePeriodFormatter.string(from: date as Date)
        return dateString
    }
    
    func addBehavior ( moduleDate : String , moduleName : String , moduleLocation : String){
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
        let myString1 = NSMutableAttributedString(string: " " + NSLocalizedString("Information", comment: ""))
        myString.append(myString1)
        print("\(myString.length)")
        myString.setAttributes([NSFontAttributeName:titleLabel.font!,NSBaselineOffsetAttributeName:5], range: NSRange(location:1,length:(NSLocalizedString("Information", comment: "").characters.count)+1))
        titleLabel.attributedText = myString
        
        // Bottom line for title label
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = Constants.topBottomBarColor.cgColor
        border.frame = CGRect(x: 0, y: titleLabel.frame.size.height - width, width:  titleLabel.frame.size.width, height: 1)
        
        border.borderWidth = width
        titleLabel.layer.addSublayer(border)
        titleLabel.layer.masksToBounds = true
        
        let count = 3
        var sum = 0
        let x:Int = 10
        var y:Int = Int(titleLabel.bounds.size.height) + 15
        
        for i in 1...count {
            sum += i
            
            let messagedLabel = UILabel(frame:CGRect(x: x, y: y, width: Int(passwordView.bounds.size.width - 20), height: 30))
            messagedLabel.textAlignment = .left
            messagedLabel.font = UIFont.systemFont(ofSize: 13)
            messagedLabel.backgroundColor = UIColor.clear
            messagedLabel.textColor = Constants.topBottomBarColor
            //messagedLabel.adjustsFontSizeToFitWidth = true
            passwordView.addSubview(messagedLabel)
            if i == 1 {
                messagedLabel.text = "Module registered date : \(self.getDate(unixdate: moduleDate))"
            }
            else if i == 2 {
                messagedLabel.text = "Module name : \(moduleName)"
            }
            else {
                messagedLabel.text = "Module location : \(moduleLocation)"
            }
            y = y+5+30
        }
                
        let lineView = UIView(frame: CGRect(x: 0, y: passwordView.bounds.size.height-41 , width: passwordView.bounds.size.width, height: 1))
        lineView.backgroundColor = Constants.topBottomBarColor
        passwordView.addSubview(lineView)
        
        let confirmButton = CustomButton(frame:CGRect(x: 0, y: passwordView.bounds.size.height-40, width: passwordView.bounds.size.width, height: 40))
        confirmButton.addTarget(self, action: #selector(okButtonAction), for: UIControlEvents.touchUpInside)
        confirmButton.setTitle(NSLocalizedString("OK", comment: ""), for: .normal)
        confirmButton.backgroundColor = UIColor.clear
        confirmButton.setTitleColor(UIColor.black, for: .normal)
        passwordView.addSubview(confirmButton)
        confirmButton.setTitleColor(Constants.topBottomBarColor, for: .normal)
        confirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        confirmButton.setBackgroundColor(color: Constants.listColor, forState: .highlighted)
        confirmButton.setTitleColor(Constants.backgroundWhiteColor, for: .highlighted)
        
        let path = UIBezierPath(roundedRect:confirmButton.bounds,
                                byRoundingCorners:[ .bottomLeft , .bottomRight],
                                cornerRadii: CGSize(width: 5, height:  5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        confirmButton.layer.mask = maskLayer
        
    }
    
    func okButtonAction() {
        self.delegate?.okButtonAction()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
