//
//  UserProfileViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 1/23/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper


class UserProfileViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    let cellReuseIdentifier = "cell"
    var arrValues: Array<String>!
    var arrDefaultValues: Array<String>!

   
    @IBOutlet weak var dataTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = KeychainWrapper.standard
        let fullName = defaults.string(forKey: Constants.USER_PROFILE_FULLNAME)
        let email = defaults.string(forKey: Constants.USER_PROFILE_EMAIL)
        let createdon : NSNumber = defaults.integer(forKey: Constants.USER_PROFILE_CREATED)! as NSNumber
        let modifiedon : NSNumber = defaults.integer(forKey: Constants.USER_PROFILE_MODIFIED)! as NSNumber
        
        
        // converting it from  millisecons divided by 1000
        let startDate = NSDate(timeIntervalSince1970: TimeInterval(createdon)/1000)
        let modifiedDate = NSDate(timeIntervalSince1970: TimeInterval(modifiedon)/1000)

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone.local
        
        arrValues = [ fullName! , email!, dateFormatter.string(from: startDate as Date)  , dateFormatter.string(from: modifiedDate as Date)]
        arrDefaultValues = ["Fullname : " ,"Email : " , "Created on : " ,"Modified on : "]
        
        dataTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        dataTableView.tableFooterView = UIView()
        dataTableView.separatorColor = UIColor.gray
        dataTableView.layoutMargins = UIEdgeInsets.zero
        dataTableView.separatorInset = UIEdgeInsets.zero
        dataTableView.isScrollEnabled = false

        // Do any additional setup after loading the view.
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 //cell height
    }
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return arrValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)

        let normalText = arrValues![indexPath.row]
        
        let boldText  = arrDefaultValues![indexPath.row]
        
        let attributedString = NSMutableAttributedString(string:normalText)
        
        let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 15)]
        let boldString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        boldString.append(attributedString)
        cell.textLabel?.attributedText = boldString
        
        cell.textLabel?.textColor = Constants.topBottomBarColor
        cell.textLabel?.textAlignment = .left
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DropdownSelectedIndex"), object: indexPath.row)
        self.dismiss(animated: true, completion: nil)
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
