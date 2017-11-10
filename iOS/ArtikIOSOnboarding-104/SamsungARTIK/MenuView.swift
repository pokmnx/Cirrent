//
//  MenuView.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/30/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
//import Crashlytics

protocol MenuDelegate {
    func selectedMenuItem(index: Int)
}

class MenuView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var delegate:MenuDelegate?
    var isFirstTime : Bool!
    var arrValues = [String]()
    var menuTableView: UITableView!
    var deviceTypes = [DeviceType]()
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        isFirstTime = true
        addBehavior()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    func updateDeviceTypes(items : [DeviceType]) {
        deviceTypes = items
    }
    
    func updateItems( items : [String]) {
        arrValues = items;
        menuTableView.reloadData()
    }
    
    func addBehavior () {
        print("Add all the behavior here")
        
        menuTableView = UITableView()
        menuTableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTableViewCell")
        menuTableView.tableFooterView = UIView()

        menuTableView.layoutMargins = UIEdgeInsets.zero
        menuTableView.separatorInset = UIEdgeInsets.zero

        menuTableView.separatorStyle = .none

        menuTableView.delegate = self
        menuTableView.dataSource = self
        menuTableView.translatesAutoresizingMaskIntoConstraints = false
        menuTableView.alwaysBounceVertical = false
        menuTableView.isScrollEnabled = true
        self.addSubview(menuTableView)


        let viewsDict: Dictionary = ["menuTableView": menuTableView];

        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[menuTableView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict)
        self.addConstraints(arrXconstraints)

        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[menuTableView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict)
        self.addConstraints(arrYconstraints)


    }

    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrValues.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell", for: indexPath) as! MenuTableViewCell


        cell.layoutMargins = UIEdgeInsets.zero
        let backgroundView = UIView()
        backgroundView.backgroundColor = Constants.topBottomBarColor
        cell.menuItemLabel.text = arrValues[indexPath.row]
        cell.rightArrowImageView.isHidden = false
        cell.menuItemLabel.adjustsFontSizeToFitWidth = true


        /* Update Icon */

        let row = indexPath.row

        if row == 0 {
            cell.rightArrowImageView.image = #imageLiteral(resourceName: "allblack")
            cell.rightArrowImageView.highlightedImage = #imageLiteral(resourceName: "allblack")
        } else if deviceTypes.count < row {
            cell.rightArrowImageView.image = #imageLiteral(resourceName: "devicegray")
            cell.rightArrowImageView.image = #imageLiteral(resourceName: "deviceblack")
        } else if deviceTypes[row - 1].cloudConnector  == 1 {
            cell.rightArrowImageView.image = #imageLiteral(resourceName: "cloudgray")
            cell.rightArrowImageView.highlightedImage = #imageLiteral(resourceName: "cloudblack")
        } else {
            if deviceTypes[row - 1].dtid == Constants.ARTIK_0_DTID {
                cell.rightArrowImageView.image = #imageLiteral(resourceName: "artik0Gray")
                cell.rightArrowImageView.highlightedImage = #imageLiteral(resourceName: "artik0Black")
            }
            else if deviceTypes[row - 1].dtid == Constants.ARTIK_5_DTID {
                cell.rightArrowImageView.image = #imageLiteral(resourceName: "artik5Gray")
            }
            else if deviceTypes[row - 1].dtid == Constants.ARTIK_7_DTID {
                cell.rightArrowImageView.image = #imageLiteral(resourceName: "artik7Gray")
            }
            else {
                cell.rightArrowImageView.image = #imageLiteral(resourceName: "devicegray")
                cell.rightArrowImageView.highlightedImage = #imageLiteral(resourceName: "deviceblack")
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFirstTime == true {
            isFirstTime = false
            tableView .reloadData()
        }
        
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
        self.delegate?.selectedMenuItem(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

}
