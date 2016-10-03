//
//  LoginViewController.h
//  HackerNews
//
//  Created by deepak.go on 03/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;
@protocol LoginViewControllerDelegate <NSObject>
- (void)addItemViewController:(LoginViewController *)controller didFinishEnteringCookie:(NSString *)cookie UserName:(NSString *)userName;
@end

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (nonatomic, weak) id <LoginViewControllerDelegate> delegate;

@end
