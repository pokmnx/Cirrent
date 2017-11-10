//
//  DashBoardViewController.swift
//  SamsungARTIK
//
//  Created by alimi shalini on 11/29/16.
//  Copyright © 2016 alimi shalini. All rights reserved.
//

import UIKit
import CoreData
import ArtikCloud
import SwiftKeychainWrapper
import KCFloatingActionButton
import CirrentSDK

class DashBoardViewController: UIViewController,UITableViewDelegate,UITableViewDataSource, UIScrollViewDelegate, MenuDelegate, popOverDelegate,UIGestureRecognizerDelegate, ATConfirmationAlertDelegate, KCFloatingActionButtonDelegate, ATInformationAlertDelegate, ATAlertViewDelegate,ATAboutViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var noModuleDataLabel: UILabel!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var titleTextField: TitlesTextField!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var RegisteredBoardTableView: UITableView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    var alertView: ATAlertView!
    var isFromLinkModuleScreen: Bool! = false
    @IBOutlet weak var blurEffectView: UIView!
    var menuView: MenuView!
    var menuViewLeadingconstraint: NSLayoutConstraint!
    let dropDownMenu = ["User Profile", "ZipKey Profile", "About", "Logout" ]
    var arrValues : [String] = ["ALL"]
    var modulesArray : [Module] = [Module]()
    var moduleIndexs = [IndexPath]()
    var popOverView: PopOverView!
    var confirmationAlert: ATConfirmationAlert!
    var informationAlert: ATInformationAlert!
    var isMenuPresent: Bool!
    var selectedIndexPath : IndexPath!
    var TouchedFlag: Int = 0
    var refreshControl: UIRefreshControl?
    var aboutView : ATAboutView!
    var deviceTypes = [DeviceType]()
    var isScrolling : Bool = false
    var reloadTableView : Bool = false
    var isFirstTime : Bool = true
    var isRefreshing : Bool = false

    var addNewButton = KCFloatingActionButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        initAddNewModule()
        isMenuPresent = false
        self.view.backgroundColor = UIColor.black
        
        if isFromLinkModuleScreen == false {
            //ATUtilities.showIndicator(message:"Fetching the registered modules")
        }
        
        RegisteredBoardTableView.register(UINib(nibName: "RegisteredBoardsTableViewCell", bundle: nil), forCellReuseIdentifier: "RegisteredBoardsTableViewCell")
        RegisteredBoardTableView.tableFooterView = UIView()
        RegisteredBoardTableView.separatorColor = UIColor.gray
      //  RegisteredBoardTableView.layoutMargins = UIEdgeInsets.zero
        RegisteredBoardTableView.separatorInset = UIEdgeInsets.zero
        
        //Pull down to refresh
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(DashBoardViewController.refresh), for: UIControlEvents.valueChanged)
        RegisteredBoardTableView.addSubview(refreshControl!)
        
        //Pan gesture for animation
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        panGesture.delegate = self
        mainView.addGestureRecognizer(panGesture)
        
        if ATReachability.sharedInstance.isNetworkReachable == false {
            self.networkChange()
        }
    }
    
    func refresh() {
        
        if ATReachability.sharedInstance.isNetworkReachable == true {
            print("Refreshing device list")
            RegisteredBoardTableView.isScrollEnabled = false
            isScrolling = false
            isRefreshing = true
            ATUtilities.showIndicator(message:"Fetching the registered modules")
            self.appDelegate().getModules(isFromPullDown:true)
        }
        else {
            self.showAlert(message: NSLocalizedString("No Internet connection. Cannot fetch devices.", comment: ""))
            refreshControl?.endRefreshing()
        }
        
    }

    /**
     Delegate Callbacks for Floating Action Button (+ sign)
     */
    func KCFABOpened(_ fab: KCFloatingActionButton) {

        addNewButton.close()

        if self.isMenuPresent == true {
            self.menuButtonAction(menuButton)
        }

        menuView.isHidden = true

        popOverView = PopOverView(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        popOverView.delegate = self
        popOverView.backgroundColor = UIColor.clear
        self.view.addSubview(popOverView)

        popOverView.translatesAutoresizingMaskIntoConstraints = false

        let subviewsDict: Dictionary = ["popOverView": popOverView];

        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)

        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[popOverView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)

    }

    func KCFABClosed(_ fab: KCFloatingActionButton) {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.addObservers()
        isFirstTime = true

        if isFromLinkModuleScreen == false {
            if self.appDelegate().isFirstTimeLogin == true {
                DispatchQueue.global(qos: .background).async {
                    self.appDelegate().getModules(isFromPullDown:false)
                }
                self.appDelegate().isFirstTimeLogin = false
            }
        }

        fetchDeviceTypes()
    }

    func isCloudConnector(dtid : String) -> Bool {

        for deviceType in deviceTypes {
            if deviceType.dtid == dtid && deviceType.cloudConnector == 1 {
                return true
            }
        }
        return false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        NotificationCenter.default.removeObserver(self)
        
        if let popOver = popOverView {
            popOver.removeFromSuperview()
        }
        if isMenuPresent == true {
            self.animateMenuView()
        }
        
    }

    func initAddNewModule() {
        addNewButton.buttonColor = UIColorFromRGB(rgbValue: 0xf7941d)
        addNewButton.plusColor = UIColor.white
      //  addNewButton.buttonImage = UIImage(named: "add")
        addNewButton.addItem("Add new module", icon: UIImage(named: "add")!)
        addNewButton.autoCloseOnTap = true
        addNewButton.fabDelegate = self
        self.view.addSubview(addNewButton)
    }

    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.loadMenuView()
        self.showDevices(index:self.appDelegate().selectedMenuItemInd)
    }

    func fetchDeviceTypes() {

        deviceTypes = ATDatabaseManager.getAllDeviceType()
        var localarrValues = [String]()
        localarrValues.append("ALL")
        for deviceType in deviceTypes {
            localarrValues.append(deviceType.name!)
        }
        arrValues = localarrValues
        menuView?.updateDeviceTypes(items: deviceTypes)
        menuView?.updateItems(items: arrValues)

    }

    func fetchDevicePresence(offset: Int, count: Int) {

        /* TODO Remove */
        //return
        
        var index = offset

        while index < offset + count {
            if index >= modulesArray.count {
                break
            }
            let device = modulesArray[index]
            self.appDelegate().getDevicePresence(deviceId: device.id!)

            index += 1
        }

    }

    func updateDevicePresence() {

        /* In general, if the user is scrolling do not update table data or it will cause lag in the roll down animation */
        if isScrolling {
            reloadTableView = true
        } else  {
            RegisteredBoardTableView.reloadData()
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchDevices), name: NSNotification.Name(rawValue: "fetch_dashboard_data"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange), name: NSNotification.Name(rawValue: Constants.NETWORK_CONNECTION_CHANGED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchDevices), name: NSNotification.Name(rawValue: Constants.MODULE_DELETED_NOTIF), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteFailed), name: NSNotification.Name(rawValue: Constants.MODULE_DELETE_FAILED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DropdownSelectedAction(note:)), name: NSNotification.Name(rawValue: "DropdownSelectedIndex"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchDeviceTypes), name: NSNotification.Name(rawValue: "fetch_devicetypes"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDevicePresence), name: NSNotification.Name(rawValue: "refresh_presence"), object: nil)
    }

    func DropdownSelectedAction(note:Notification) {
        let index = note.object as! Int
        
        if index == 3 {
            self.showConfirmationAlert(message: NSLocalizedString("Are you sure to logout?", comment: "") , action: "logout",title: NSLocalizedString("Confirmation", comment: ""))
        }
        else if index == 2 {
            self.showAboutView()
        }
        else if index == 1 {
            let zipkeyProfileController = self.storyboard!.instantiateViewController(withIdentifier: "ZipKeyProfileController") as! ZipKeyProfileController
            self.navigationController!.pushViewController(zipkeyProfileController, animated: true)
        }
        else{
            let userProfileControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
            self.navigationController!.pushViewController(userProfileControllerObj, animated: true)
        }
    }
    
    func showAboutView() {

        aboutView = ATAboutView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        aboutView.delegate = self
        aboutView.backgroundColor = UIColor.clear
        self.view.addSubview(aboutView)
        
        aboutView.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["aboutView": aboutView];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[aboutView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[aboutView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    func okButtonActionAbout() {
        aboutView.removeFromSuperview()
    }
    
    public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func networkChange() {
        if ATReachability.sharedInstance.isNetworkReachable == true {
            if alertView != nil {
                self.hideAlert()
            }
            if confirmationAlert != nil {
                confirmationAlert.removeFromSuperview()
            }
            if popOverView != nil {
                popOverView.removeFromSuperview()
            }
            if informationAlert != nil {
                informationAlert.removeFromSuperview()
            }
            if isMenuPresent == true {
                self.menuButtonAction(menuButton)
            }
            ATUtilities.showIndicator(message:"Fetching the registered modules")
            self.appDelegate().getModules(isFromPullDown:false)

        }
        else {
            ATUtilities.hideIndicator()
            self.fetchDevices()
            if alertView != nil {
                self.hideAlert()
            }
            if confirmationAlert != nil {
                self.hideConfirmationAlert()
            }
            if popOverView != nil {
                popOverView .removeFromSuperview()
            }
            if informationAlert != nil {
                self.okButtonAction()
            }
            self.showAlert(message: NSLocalizedString("No Internet connection. Cannot fetch devices.", comment: ""))
        }
    }
    
    func deleteFailed(notification: Notification) {
        ATUtilities.hideIndicator()
        guard let userInfo = notification.userInfo else { return }
        if let errorMsg = userInfo["errorDesc"] as? String {
            self.showAlert(message: errorMsg)
        }
    }
    
    func showAlert(message: String) {
        alertView = ATAlertView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message , cancelButtonTitle: NSLocalizedString("OK", comment: ""), confirmButtonTitle: "")
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
    
    // MARK: - ATAlertView Delegates
    
    func hideAlert() {
        alertView.removeFromSuperview()
    }
    
    func fetchDevices() {

        isRefreshing = false
        RegisteredBoardTableView.isScrollEnabled = true
        if !isScrolling {
            self.showDevices(index:self.appDelegate().selectedMenuItemInd)
        } else {
            reloadTableView = true
        }
    }

    @IBAction func logoutAction(_ sender: UIButton) {

        if self.isMenuPresent == true {
            self.menuButtonAction(menuButton)
        }
        
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DropDownViewController")
        let viewController = popController as? DropDownViewController
        viewController?.updateItems(items: dropDownMenu)
        // set the presentation style
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        // set up the popover presentation controller
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = sender // button
        popController.preferredContentSize = CGSize(width: 150, height: 200)
        popController.popoverPresentationController?.sourceRect = sender.bounds
        // present the popover
        self.present(popController, animated: true, completion: nil)
       
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func loadMenuView() -> Void {
        menuView = MenuView.init(frame: CGRect.zero)
        menuView.delegate = self
        menuView.deviceTypes = deviceTypes
        menuView.updateItems(items: arrValues)

        self.view.addSubview(menuView)

        menuView.translatesAutoresizingMaskIntoConstraints = false


        let viewsDict: Dictionary = ["menuView": menuView, "topView": topView, "bottomView" : bottomView];
        
        let arrYConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[topView]-0-[menuView]-0-[bottomView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict)
        self.view.addConstraints(arrYConstraints)

        
        menuViewLeadingconstraint = NSLayoutConstraint(item: menuView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0)
        self.view.addConstraint(menuViewLeadingconstraint)
        
        let widthConstraint = NSLayoutConstraint(item: menuView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 0.75, constant: 0.0)
        self.view.addConstraint(widthConstraint)
        self.view.layoutIfNeeded()
        
        menuViewLeadingconstraint.constant = -menuView.frame.size.width - 3
 
        self.view.layoutIfNeeded()
    }


    func showDevices(index: Int) {

        var localIndex = index
        self.appDelegate().selectedMenuItemInd = index

        if isMenuPresent == true {
            self.menuButtonAction(menuButton)
        }

        if index >= arrValues.count {
            localIndex = 0
            self.appDelegate().selectedMenuItemInd = localIndex
        }
        titleTextField.text = arrValues[localIndex]

        if isScrolling {
            reloadTableView = true
        } else {

            if localIndex == 0 {
                modulesArray = ATDatabaseManager.getAllModules()
            } else {
                modulesArray = ATDatabaseManager.filterModulesBy(module: deviceTypes[localIndex - 1].dtid!)
            }

            if modulesArray.count == 0 {
                noModuleDataLabel.isHidden = false
            }
            else {
                noModuleDataLabel.isHidden = true
            }

            RegisteredBoardTableView.reloadData()

            updateVisibleItemsActivity()
        }
        ATUtilities.hideIndicator()
        refreshControl?.endRefreshing()

    }

    
    // MARK: - MenuDelegate
    
    func selectedMenuItem(index: Int) {

        isScrolling = false
        showDevices(index: index)

    }

    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 //cell height
    }

    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return modulesArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisteredBoardsTableViewCell", for: indexPath) as! RegisteredBoardsTableViewCell
     //   cell.layoutMargins = UIEdgeInsets.zero
        tableView.separatorStyle = .singleLine
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = UITableViewCellSelectionStyle.default

        
        if indexPath.row  != modulesArray.count {

            cell.backgroundColor = UIColor.black
            cell.layer.cornerRadius = 5
            
            let module:Module = modulesArray[indexPath.row]
            let strModuleName: String? = module.name


            /* Update Icon */

            if (isCloudConnector(dtid: module.dtid!)) {
                cell.artikImageView.image = #imageLiteral(resourceName: "cloud")
            } else {

                if module.dtid == Constants.ARTIK_0_DTID {
                    cell.artikImageView.image = #imageLiteral(resourceName: "artik0")
                }
                else if module.dtid == Constants.ARTIK_5_DTID {
                    cell.artikImageView.image = #imageLiteral(resourceName: "artik5")
                }
                else if module.dtid == Constants.ARTIK_7_DTID {
                    cell.artikImageView.image = #imageLiteral(resourceName: "artik7")
                }
                else {
                    cell.artikImageView.image = #imageLiteral(resourceName: "device")
                }
            }
            
            cell.moduleNameLabel.text = strModuleName

            /* Update Device Presence */
            let timeInterval = Int64(Date().timeIntervalSince1970)*1000 - Int64(module.lastSeen)

            if module.lastSeen == -1 {

                cell.deviceStatusIcon.image = #imageLiteral(resourceName: "red")
                cell.deviceStatusLabel.text = "Never Connected"
                cell.deviceStatusIcon.isHidden = false
                cell.moduleLocationLabel.isHidden = true

            } else if module.lastSeen == 0 {

                cell.deviceStatusLabel.text = "Never Connected"
                cell.deviceStatusIcon.isHidden = true
                cell.moduleLocationLabel.isHidden = true

            } else if timeInterval < 60*60*1000 {

                cell.deviceStatusLabel.text = "Last Activity"
                cell.deviceStatusIcon.image = #imageLiteral(resourceName: "green")
                cell.deviceStatusIcon.isHidden = false
                cell.moduleLocationLabel.isHidden = false
                cell.moduleLocationLabel.text = ATUtilities.timeSinceFormat(timestamp: module.lastSeen, numericDates: true)

            } else if timeInterval > 60*60*1000 && timeInterval < 60*60*24*1000 {
                cell.deviceStatusLabel.text = "Last Activity"
                cell.deviceStatusIcon.image = #imageLiteral(resourceName: "yellow")
                cell.deviceStatusIcon.isHidden = false
                cell.moduleLocationLabel.text = ATUtilities.timeSinceFormat(timestamp: module.lastSeen, numericDates: true)
                cell.moduleLocationLabel.isHidden = false

            } else {

                cell.deviceStatusLabel.text = "Last Activity"
                cell.deviceStatusIcon.image = #imageLiteral(resourceName: "red")
                cell.deviceStatusIcon.isHidden = false
                cell.moduleLocationLabel.text = ATUtilities.timeSinceFormat(timestamp: module.lastSeen, numericDates: true)
                cell.moduleLocationLabel.isHidden = false

            }

            cell.artikImageView.isHidden = false
            
        } else {
            cell.isHidden = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == modulesArray.count {
            return
        }

        self.appDelegate().selectedDevice(module: modulesArray[indexPath.row])
        let deviceControlView = self.storyboard!.instantiateViewController(withIdentifier: "DeviceActivityViewController") as! DeviceActivityViewController
        self.navigationController!.pushViewController(deviceControlView, animated: true)

    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("scrolling..")
        isScrolling = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("End Dragging ")
        if !scrollView.isDragging && !scrollView.isDecelerating  && !isRefreshing {
            self.isScrolling = false
            print("End Dragging - Reload")
            reloadTable()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        self.isScrolling = false
        print("End Decelerating")
        if !isRefreshing {
            reloadTable()
        }
    }

    func reloadTable() {

        if reloadTableView {
            reloadTableView = false
            self.showDevices(index:self.appDelegate().selectedMenuItemInd)
        } else {
            updateVisibleItemsActivity()
        }
    }

    func updateVisibleItemsActivity()  {
        let indexPaths = RegisteredBoardTableView.indexPathsForVisibleRows

        if indexPaths != nil && (indexPaths?.count)! > 0 {
            print("Updating presence of  item number \(indexPaths?[0].row)")
            self.fetchDevicePresence(offset: (indexPaths?[0].row)!, count: 10)
        }
        
    }

    // MARK: - Alerts
    func deleteModuleAction(_ sender : Any) {
        selectedIndexPath = RegisteredBoardTableView.indexPathForView(view: sender as! UIView)! as IndexPath
        self.showConfirmationAlert(message: NSLocalizedString("Are you sure to delete?", comment: "") , action: "delete",title: NSLocalizedString("Delete", comment: ""))
    }
    
    func presentDeviceControlView(_ sender : Any) {
        
        selectedIndexPath = RegisteredBoardTableView.indexPathForView(view: sender as! UIView)! as IndexPath
        self.appDelegate().selectedDevice(module: modulesArray[selectedIndexPath.row])
        let deviceControlView = self.storyboard!.instantiateViewController(withIdentifier: "DeviceActivityViewController") as! DeviceActivityViewController
        self.navigationController!.pushViewController(deviceControlView, animated: true)
    }
    
    func showConfirmationAlert(message: String, action: String,title:String) {
        
        confirmationAlert = ATConfirmationAlert(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), message: message, action: action, title:title )
        confirmationAlert.delegate = self
        confirmationAlert.backgroundColor = UIColor.clear
        self.view.addSubview(confirmationAlert)
        
        confirmationAlert.translatesAutoresizingMaskIntoConstraints = false
        
        let subviewsDict: Dictionary = ["confirmationAlert": confirmationAlert];
        
        let arrXconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[confirmationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrXconstraints)
        
        let arrYconstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[confirmationAlert]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: subviewsDict)
        self.view.addConstraints(arrYconstraints)
    }
    
    func hideConfirmationAlert() {
        confirmationAlert.removeFromSuperview()
    }
    
    func confirmButtonAction(action: String) {
        if ATReachability.sharedInstance.isNetworkReachable == true {
            if action == "logout" {
                menuView.isHidden = true
                
                let defaults = KeychainWrapper.standard
                defaults.removeObject(forKey: Constants.ACCESS_TOKEN)
                defaults.removeObject(forKey: Constants.REFRESH_TOKEN)
                defaults.removeObject(forKey: Constants.USER_PROFILE_NAME)
                defaults.removeObject(forKey: Constants.USER_PROFILE_EMAIL)
                defaults.removeObject(forKey: Constants.USER_PROFILE_CREATED)
                defaults.removeObject(forKey: Constants.USER_PROFILE_MODIFIED)
                defaults.removeObject(forKey: Constants.USER_PROFILE_FULLNAME)

                
                //Clearing the database when logout
                ATDatabaseManager.truncateEntity()

                NotificationCenter.default.removeObserver(self)
                
                let loginViewControllerObj = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = loginViewControllerObj
            }
            else if action == "delete" {
                let moduleDict = modulesArray[selectedIndexPath.row]
                self.appDelegate().deleteModule(deviceId: moduleDict.id! as String)
            }
        }
        else {
            if action == "logout" {
                self.showAlert(message: NSLocalizedString("Logout Failed. No internet connection.", comment: ""))
            }
            else if action == "delete" {
                self.showAlert(message: NSLocalizedString("Delete Failed. No internet connection.", comment: ""))
            }
        }
        
        confirmationAlert.removeFromSuperview()
    }

    func okButtonAction() {
        informationAlert.removeFromSuperview()
    }
    
    // MARK: - PopoverDelegate
    
    func selectedMenuItemForNewArtikBoard(index: Int) {
        menuView.isHidden = false
        
        if index == 1 {
            let qrCodeControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "QRCodeScannerViewController") as! QRCodeScannerViewController
            self.navigationController!.pushViewController(qrCodeControllerObj, animated: true)
        }
        else if index == 2 {
            let manualInputControllerObj = self.storyboard!.instantiateViewController(withIdentifier: "ManualInputViewController") as! ManualInputViewController
            self.navigationController!.pushViewController(manualInputControllerObj, animated: true)
        }
        else if index == 3 {
            popOverView.removeFromSuperview()
            ATUtilities.showIndicator1(message: "Finding ARTIK modules...")
            self.noModuleDataLabel.isHidden = true
            CirrentService.sharedService.findDevice(tokenMethod: SampleCloudService.sharedService.getToken, completion: {
                result, devices in
                
                DispatchQueue.main.async {
                    if result == FIND_DEVICE_RESULT.SUCCESS {
                        for dev in devices! {
                            if dev.getDeviceType() == Constants.ARTIK_DEVICE_TYPE {
                                self.goToConnectScreen(device: dev)
                                return
                            }
                        }
                    }
                    
                    self.noModuleDataLabel.isHidden = false
                    ATUtilities.hideIndicator1()
                    let failedController:ZipKeyFailedController = self.storyboard!.instantiateViewController(withIdentifier: "ZipKeyFailedController") as! ZipKeyFailedController
                    self.navigationController!.pushViewController(failedController, animated: true)
                }
            })
        }
        else if index == 4 {
            popOverView.removeFromSuperview()
        }
        
    }
    
    func goToConnectScreen(device:Device) {
        _ = CirrentService.sharedService.selectDevice(deviceID: device.getDeviceID())
        SampleCloudService.sharedService.bindDevice(deviceID: device.getDeviceID(), friendlyName: nil, completion: {
            token, result in
            
            if result == .SUCCESS {
                CirrentService.sharedService.getDeviceStatus(tokenMethod: SampleCloudService.sharedService.getToken, deviceID: device.getDeviceID(), uptime: false, completion: {
                    response, status in
                    
                    if response != .SUCCESS {
                        DispatchQueue.main.async {
                            self.noModuleDataLabel.isHidden = false
                            ATUtilities.hideIndicator1()
                            ProgressView.sharedView.showToast(view: self.view, message: "There is some problem on the device. Try again.")
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            let provider = CirrentService.sharedService.model?.getProviderNetwork()
                            if provider != nil {
                                if CirrentService.sharedService.model?.getSSID() != nil && CirrentService.sharedService.model?.getSSID()! == provider!.getSSID() {
                                    ATUtilities.hideIndicator1()
                                    let providerController:ProviderConnectController = self.storyboard!.instantiateViewController(withIdentifier: "ProviderConnectController") as! ProviderConnectController
                                    self.navigationController!.pushViewController(providerController, animated: true)
                                    return
                                }
                            }
                            
                            self.noModuleDataLabel.isHidden = false
                            ATUtilities.hideIndicator1()
                            let privateController:PrivateNetworkConnectController = self.storyboard!.instantiateViewController(withIdentifier: "PrivateNetworkConnectController") as! PrivateNetworkConnectController
                            privateController.networks = (CirrentService.sharedService.model?.getNetworks())!
                            self.navigationController!.pushViewController(privateController, animated: true)
                        }
                    }
                })
            }
        })
    }
    
    // MARK: - Menu button action
    
    @IBAction func menuButtonAction(_ sender: Any) {
        self.animateMenuView()
    }
    
    func animateMenuView() -> Void {
        
        UIView.animate(withDuration: Constants.ANIMATION_DURATION, delay: 0.0, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
            if self.isMenuPresent == false {
                self.menuViewLeadingconstraint.constant = 0;
                self.view.layoutIfNeeded()
                
                self.isMenuPresent = true
                self.blurEffectView.alpha = 0.8
                self.RegisteredBoardTableView.isUserInteractionEnabled = false
            }
            else {
                self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3
                self.view.layoutIfNeeded()
                
                self.isMenuPresent = false
                self.blurEffectView.alpha = 0.0
                self.RegisteredBoardTableView.isUserInteractionEnabled = true
                
            }
            
        }, completion: {
            (value: Bool) in
            
        })
    }
    
    func handlePan(gesture: UIPanGestureRecognizer) {
        var translate: CGPoint = gesture.translation(in: gesture.view)
        translate.y = 0.0
        
        if gesture.state == UIGestureRecognizerState.began && TouchedFlag==0
        {
            TouchedFlag=1;
            //PAN openration
            
            let percentage = translate.x/self.view.frame.size.width
            
            if translate.x > 0.0 && self.menuViewLeadingconstraint.constant < self.menuView.frame.size.width {
                if self.isMenuPresent == false {
                    if self.menuViewLeadingconstraint.constant < 0 {
                        self.blurEffectView.alpha = percentage
                        self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3 + translate.x
                        
                        if self.menuViewLeadingconstraint.constant > 0 {
                            self.menuViewLeadingconstraint.constant = 0
                        }
                        
                        self.view.layoutIfNeeded()
                    }
                }
            }
            else if translate.x < 0.0 {
                if self.isMenuPresent == true {
                    self.blurEffectView.alpha = 0.8 + percentage
                    self.menuViewLeadingconstraint.constant = translate.x
                    self.view.layoutIfNeeded()
                }
            }
        }
        else if gesture.state == UIGestureRecognizerState.began && TouchedFlag==1 {
        }
        else if gesture.state == UIGestureRecognizerState.cancelled || gesture.state == UIGestureRecognizerState.failed {
            self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3
            self.view.layoutIfNeeded()
            self.isMenuPresent = false
            self.blurEffectView.alpha = 0.0
            self.RegisteredBoardTableView.isUserInteractionEnabled = true
        }
        else if gesture.state == UIGestureRecognizerState.ended {
            let velocity: CGPoint = gesture.velocity(in: gesture.view)
            TouchedFlag = 0
            
            if translate.x > 0.0 && (translate.x + velocity.x * 0.25) > ((gesture.view?.bounds.size.width)! / 4.0) {
                //Show menu
                var animation_duration = 0.4 * 100 / -self.menuViewLeadingconstraint.constant
                
                if animation_duration > 0.4 {
                    animation_duration = 0.2
                }
                
                UIView.animate(withDuration: TimeInterval(animation_duration), delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    self.menuViewLeadingconstraint.constant = 0
                    self.view.layoutIfNeeded()
                    
                    self.isMenuPresent = true
                    self.blurEffectView.alpha = 0.8
                    self.RegisteredBoardTableView.isUserInteractionEnabled = false
                    
                }, completion: {
                    (value: Bool) in
                    
                })
            }
            else if translate.x < 0.0 && (translate.x + velocity.x * 0.25) < -((gesture.view?.frame.size.width)! / 5.0) {
                //Hide menu
                let animation_duration = 0.4 * 100 / self.menuViewLeadingconstraint.constant
                
                UIView.animate(withDuration: TimeInterval(animation_duration), delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3
                    self.view.layoutIfNeeded()
                    
                    self.isMenuPresent = false
                    self.blurEffectView.alpha = 0.0
                    self.RegisteredBoardTableView.isUserInteractionEnabled = true
                    
                }, completion: {
                    (value: Bool) in
                    
                })
            }
            else {
                
                if isMenuPresent == true {
                    //Show menu
                    
                    UIView.animate(withDuration: 0.10, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.menuViewLeadingconstraint.constant = 0
                        self.view.layoutIfNeeded()
                        
                        self.isMenuPresent = true
                        self.blurEffectView.alpha = 0.8
                        self.RegisteredBoardTableView.isUserInteractionEnabled = false
                        
                    }, completion: {
                        (value: Bool) in
                        
                    })
                }
                else {
                    //Hide menu
                    
                    UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3
                        self.view.layoutIfNeeded()
                        
                        self.isMenuPresent = false
                        self.blurEffectView.alpha = 0.0
                        self.RegisteredBoardTableView.isUserInteractionEnabled = true
                        
                    }, completion: {
                        (value: Bool) in
                        
                    })
                }
            }
        }
        else if gesture.state == UIGestureRecognizerState.changed {
            let percentage = translate.x/self.view.frame.size.width
            
            if translate.x > 0.0 && self.menuViewLeadingconstraint.constant < self.menuView.frame.size.width {
                if isMenuPresent == false {
                    if self.menuViewLeadingconstraint.constant < 0 {
                        self.blurEffectView.alpha = percentage
                        self.menuViewLeadingconstraint.constant = -self.menuView.frame.size.width - 3 + translate.x
                        if self.menuViewLeadingconstraint.constant > 0 {
                            self.menuViewLeadingconstraint.constant = 0
                        }
                        
                        self.view.layoutIfNeeded()
                    }
                }
            }
            else if translate.x < 0.0 {
                if isMenuPresent == true {
                    self.blurEffectView.alpha = 0.8 + percentage
                    self.menuViewLeadingconstraint.constant = translate.x
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - All Extensions
// MARK: - UITableView
extension UITableView {
    func indexPathForView (view : UIView) -> NSIndexPath? {
        let location = view.convert(CGPoint.zero, to:self)
        return indexPathForRow(at: location) as NSIndexPath?
    }
}

extension UITextField {
    
    func underlined(width: CGFloat){
        
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x:0.0, y:self.frame.size.height - width, width:self.frame.width, height:width)
        bottomLine.backgroundColor = UIColor.gray.cgColor
        self.borderStyle = UITextBorderStyle.none
        self.layer.addSublayer(bottomLine)
        
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        
        let rect = CGRect(x: 0, y: 0, width: (colorImage?.size.width)!, height: (colorImage?.size.height)!)
        
        UIBezierPath(roundedRect: rect, cornerRadius: 5).addClip()
        colorImage?.draw(in: rect)
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}

extension UIImageView {
    func blink() {
        self.alpha = 0.0;
        UIView.animate(withDuration: 0.8, //Time duration you want,
            delay: 0.0,
            options: [.curveEaseInOut, .autoreverse, .repeat],
            animations: { [weak self] in self?.alpha = 1.0 },
            completion: { [weak self] _ in self?.alpha = 0.0 })
    }
}

extension UIView {
    func addDashedLine(color: UIColor = Constants.backgroundWhiteColor) {
        self.backgroundColor = UIColor.clear
        let cgColor = color.cgColor
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.name = "DashedTopLine"
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = cgColor
        shapeLayer.lineWidth = 8
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.lineDashPattern = [7, 7]
        shapeLayer.cornerRadius = 4
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: self.frame.width, y: 0.0))
        shapeLayer.path = path
        
        self.layer.addSublayer(shapeLayer)
    }
}

extension UIColor {
    class var artGreyish: UIColor {
        return UIColor(white: 168.0 / 255.0, alpha: 1.0)
    }
}

// Text styles

extension UIFont {
    class func artTextStyleFont() -> UIFont? {
        return UIFont(name: ".SFNSDisplay-Regular", size: 9.33)
    }

    class func artTextStyle2Font() -> UIFont? {
        return UIFont(name: "Roboto-Regular", size: 9.33)
    }
}

