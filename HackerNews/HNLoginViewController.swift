//
//  HNLoginViewController.swift
//  HackerNews
//
//  Created by deepak.go on 13/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

import UIKit

class HNLoginViewController: UIViewController {

    weak var loginManager:LoginManager! = LoginManager.sharedInstance()
    var loggedIn:Bool = false;
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var sidebarButtonItem: UIBarButtonItem!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func login(sender: UIButton) {
        self.spinner.startAnimating()
        
        self.loginManager.loginWithUsername(userNameTextField.text,
                                            password: passwordTextField.text,
                                            andExecuteOnSuccess: {
                                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                    self.spinner.stopAnimating()
                                                    if self.loginManager.loggedIn {
                                                        let username:String = self.loginManager.userName
                                                        let alert = UIAlertController(title: "Successful Login", message: "Welcome \(username)", preferredStyle: .Alert)
                                                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { (action:UIAlertAction!) in
                                                            
                                                            let controllerId = "Welcome"
                                                            let welcomeViewController: HNWelcomeViewController! = self.storyboard!.instantiateViewControllerWithIdentifier(controllerId) as! HNWelcomeViewController
                                                            self.navigationController?.pushViewController(welcomeViewController, animated: true)
                                                            
                                                        }))
                                                        self.presentViewController(alert, animated: true, completion: nil)
                                                    }
                                                })
                                            },
                                            onError: { (error:NSError!) in
                                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                    self.spinner.stopAnimating()
                                                    let alert = UIAlertController(title: "Try Again", message: error.localizedDescription, preferredStyle: .Alert)
                                                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                                                    self.presentViewController(alert, animated: true, completion: nil)
                                                })
                                            })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if (self.revealViewController() != nil) {
            self.sidebarButtonItem.target = self.revealViewController()
            self.sidebarButtonItem.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }

}
