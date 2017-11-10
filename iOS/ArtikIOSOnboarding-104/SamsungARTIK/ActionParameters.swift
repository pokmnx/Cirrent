//
//  ActionParameters.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 20/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit

class ActionParameters: UIViewController, UITextFieldDelegate {


    @IBOutlet weak var actionDescriptionLabel: UILabel!
    @IBOutlet weak var actionNameLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!

    var params: NSDictionary!
    var finalParams = [String: NSObject]()

    var yAxis = 0
    var index = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        actionNameLabel.text = self.appDelegate().selectedActionName

        let actionObject = self.appDelegate().selectedActionObject as! NSDictionary
        actionDescriptionLabel.text = actionObject.object(forKey: "description") as? String
        params = actionObject.object(forKey: "parameters") as! NSDictionary

        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)

        for (key, value) in params {
            print("\(key) and value is \(value)")
            let child = value as! NSDictionary
            let type = child.object(forKey: "type") as! String?
            addSubParamView(key: key as! String, type: type!)
        }
        self.view.layoutSubviews()
    }


    func stateChanged(switchState: UISwitch) {

        let key = switchState.layer.value(forKey: "key") as! String
        if switchState.isOn {
            finalParams[key] = true as NSObject?
        } else {
            finalParams[key] = false as NSObject?
        }
    }



    func addSubParamView (key: String, type: String) {

        let propertyLabel = UILabel(frame: CGRect(x: 0, y : yAxis, width : 300, height: 40))
        yAxis += 40
        propertyLabel.text = key
        propertyLabel.textColor = UIColor.white
        scrollView.addSubview(propertyLabel)
        yAxis += 4

        switch type {
        case "Integer", "Double", "String", "Long":

            let textLabel = UITextField(frame: CGRect(x: 0, y : yAxis, width : 300, height: 40))
            textLabel.textColor = UIColor.cyan
            textLabel.attributedPlaceholder = NSAttributedString(string: "Enter here..",
                                                                   attributes: [NSForegroundColorAttributeName: UIColor.cyan])

            textLabel.delegate = self
            index += 1

            textLabel.layer.setValue(key, forKey: "key")
            textLabel.layer.setValue(type, forKey: "type")
            scrollView.addSubview(textLabel)
            yAxis += 40


            break
        case "Boolean":
            let switchLabel = UISwitch(frame: CGRect(x: 0, y : yAxis, width : 300, height: 40))
            index += 1
            switchLabel.layer.setValue(key, forKey: "key")
            switchLabel.layer.setValue(type, forKey: "type")
            switchLabel.addTarget(self, action: #selector(stateChanged(switchState:)), for: .valueChanged)
            scrollView.addSubview(switchLabel)
            yAxis += 40
            finalParams[key] = false as NSObject?
            break
        default:
            break

        }

        yAxis += 4

        let separator = UILabel(frame: CGRect(x: 0, y : yAxis, width : 300, height: 1))
        separator.backgroundColor = UIColor.gray
        scrollView.addSubview(separator)
        yAxis += 4


    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        let value = textField.text as String?
        let key = textField.layer.value(forKey: "key") as! String
        let type = textField.layer.value(forKey: "type") as! String

        switch type {
        case "String":
            finalParams[key] = value! as NSObject
            break
        case "Integer", "Long":
            finalParams[key] = Int((value!).trimmingCharacters(in: .whitespaces)) as NSObject?
            break
        case "Double":
            finalParams[key] = Double((value!).trimmingCharacters(in: .whitespaces)) as NSObject?
            break
        default:
            break

        }

        return true
    }
    

    @IBAction func sendAction(_ sender: UIButton){
        print("Sending \(finalParams)")
        self.appDelegate().actionParams = finalParams
        self.dismiss(animated: false, completion: nil)
    }

    @IBAction func cancelPush(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

    }


    func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }



}
