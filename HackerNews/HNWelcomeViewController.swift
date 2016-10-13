//
//  HNWelcomeViewController.swift
//  HackerNews
//
//  Created by deepak.go on 13/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

import UIKit

class HNWelcomeViewController: UIViewController {

    @IBOutlet weak var welcomeTextView: UITextView!
    @IBOutlet weak var sidebarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.automaticallyAdjustsScrollViewInsets = false;

        self.welcomeTextView.text = "Welcome \(LoginManager.sharedInstance().userName)"
        self.welcomeTextView.font = UIFont.boldSystemFontOfSize(14)
        self.welcomeTextView.textAlignment = NSTextAlignment.Center
        let contentSize:CGSize = self.welcomeTextView.sizeThatFits(CGSizeMake(self.welcomeTextView.bounds.size.width, CGFloat.max))
        let topCorrection:CGFloat = (self.welcomeTextView.bounds.size.height - contentSize.height * self.welcomeTextView.zoomScale) / 2.0
        self.welcomeTextView.contentOffset = CGPointMake(0, -topCorrection)
        
        if (self.revealViewController() != nil) {
            self.sidebarButtonItem.target = self.revealViewController()
            self.sidebarButtonItem.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }

}
