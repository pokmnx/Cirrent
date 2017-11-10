//
//  PopOverView.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 12/1/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit

protocol popOverDelegate {
    func selectedMenuItemForNewArtikBoard(index: Int)
}


class PopOverView: UIView,UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var delegate:popOverDelegate?
    var transparentView : UIView!
    var arrValues: Array<String>!
    var addNewArtikTableView: UITableView!
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        addBehavior()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBehavior (){
        print("Add all the behavior here")
        
        arrValues = [NSLocalizedString("Mode Selection", comment: ""),NSLocalizedString("Use QR Code", comment: ""),NSLocalizedString("Manual Input", comment: ""),NSLocalizedString("ZipKey", comment: ""),NSLocalizedString("CANCEL", comment: "")]
        
        transparentView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        transparentView.backgroundColor = UIColor.black
        transparentView.alpha = 0.8
        self.addSubview(transparentView)
        
        transparentView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["transparentView": transparentView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[transparentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.addConstraints(arrYconstraints)
        
        addNewArtikTableView = UITableView(frame: CGRect(x: self.bounds.size.width/2-140, y: self.bounds.size.height/2-103, width: 280, height: 256))
        addNewArtikTableView.layer.cornerRadius=5
        addNewArtikTableView.register(UINib(nibName: "popOverTableViewCell", bundle: nil), forCellReuseIdentifier: "popOverTableViewCell")
        addNewArtikTableView.backgroundColor = UIColor(red: 64.0/255.0, green: 64.0/255.0, blue: 64.0/255.0, alpha: 1.0)
        addNewArtikTableView.delegate = self
        addNewArtikTableView.dataSource = self
        addNewArtikTableView.isScrollEnabled = false
        self.addSubview(addNewArtikTableView)
        
        addNewArtikTableView.tableFooterView = UIView()
        addNewArtikTableView.separatorColor = UIColor.gray
        addNewArtikTableView.layoutMargins = UIEdgeInsets.zero
        addNewArtikTableView.separatorInset = UIEdgeInsets.zero
        
    }
    
    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrValues.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "popOverTableViewCell", for: indexPath) as! popOverTableViewCell
        let backgroundView = UIView()
        backgroundView.backgroundColor = Constants.topBottomBarColor
        cell.selectedBackgroundView = backgroundView
        cell.layoutMargins = UIEdgeInsets.zero
        cell.cellTitle.text = arrValues[indexPath.row]
        cell.cellTitle.textColor = Constants.topBottomBarColor
        cell.cellTitle.highlightedTextColor = Constants.backgroundWhiteColor
        cell.cellImageView.highlightedImage = UIImage(named: "ATMenuSelectedSlider")
        
        let additionalSeparatorThickness = CGFloat(1)
        let additionalSeparator = UIView(frame: CGRect(x:0,
                                                       y:   cell.frame.size.height - additionalSeparatorThickness,
                                                       width:   cell.frame.size.width,
                                                       height: additionalSeparatorThickness))
        additionalSeparator.backgroundColor = Constants.topBottomBarColor
        cell.addSubview(additionalSeparator)
        
        if indexPath.row == 4 || indexPath.row==0 {
            cell.cellTitle.textAlignment = NSTextAlignment.center
            cell.cellImageView?.isHidden = true
            let backgroundView1 = UIView()
            backgroundView1.backgroundColor = Constants.listColor
            cell.selectedBackgroundView = backgroundView1
            
            if indexPath.row == 0 {
                cell.selectionStyle = UITableViewCellSelectionStyle.none
            }
            cell.cellTitle.font = UIFont.boldSystemFont(ofSize: 18)
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            
        }
        else{
            self.delegate?.selectedMenuItemForNewArtikBoard(index: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 4 {
            return 56.0
        }
        return 50.0
    }
    
}
