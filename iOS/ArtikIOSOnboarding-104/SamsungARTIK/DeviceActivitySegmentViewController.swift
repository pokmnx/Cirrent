//
//  DeviceActivitySegmentViewController.swift
//  SamsungARTIK
//
//  Created by Vaibhav Singh on 10/03/17.
//  Copyright © 2017 alimi shalini. All rights reserved.
//

import UIKit

class DeviceActivitySegmentViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private lazy var actionsViewController: ActionsViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "ActionsViewController") as! ActionsViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    private lazy var fieldsViewController: FieldsViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "FieldsViewController") as! FieldsViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()
    
    private lazy var messagesViewController: MessagesViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "MessagesViewController") as! MessagesViewController
        
        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)
        
        return viewController
    }()

    private func setupView() {
        setupSegmentedControl()
        
        updateView()
    }
    
    private func updateView() {
        if segmentControl.selectedSegmentIndex == 1 {
            remove(asChildViewController: fieldsViewController)
            remove(asChildViewController: messagesViewController)
            add(asChildViewController: actionsViewController)
        } else if segmentControl.selectedSegmentIndex == 0 {
            remove(asChildViewController: actionsViewController)
            remove(asChildViewController: messagesViewController)
            add(asChildViewController: fieldsViewController)
        } else {
            remove(asChildViewController: actionsViewController)
            remove(asChildViewController: fieldsViewController)
            add(asChildViewController: messagesViewController)
        }
    }
    
    private func setupSegmentedControl() {
        // Configure Segmented Control
        
        
        segmentControl.removeAllSegments()
        segmentControl.insertSegment(withTitle: "Actions", at: 1, animated: false)
        segmentControl.insertSegment(withTitle: "Fields", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: "Messages", at: 2, animated: false)
        segmentControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        
        // Select First Segment
        segmentControl.selectedSegmentIndex = 1
    }
    
    // MARK: - Actions
    
    func selectionDidChange(_ sender: UISegmentedControl) {
        updateView()
    }
    
    // MARK: - Helper Methods
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChildViewController(viewController)
        
        // Add Child View as Subview
        view.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParentViewController: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParentViewController: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParentViewController()
    }

  
}
