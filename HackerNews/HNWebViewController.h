//
//  HNWebViewController.h
//  HackerNews
//
//  Created by deepak.go on 26/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNWebViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;
- (void)loadURL:(NSURL *)URL;

@end
