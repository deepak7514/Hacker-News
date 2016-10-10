//
//  LoginViewController.m
//  HackerNews
//
//  Created by deepak.go on 03/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "LoginViewController.h"
#import "SWRevealViewController.h"

@interface LoginViewController()

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)loginAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation LoginViewController

@synthesize delegate;

-(void)viewDidLoad {
    [super viewDidLoad];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    [self.textView setHidden:YES];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)setUsername:(NSString *)username
{
    _username = username;
    [self displayPageForLoggedInUser:username];
}

- (IBAction)loginAction:(UIButton *)sender {
    [self.spinner startAnimating];
    NSString *userName = self.userNameField.text;
    NSString *password = self.passwordField.text;
    NSLog(@"Username - %@, password - %@", userName, password);
    
    NSString *postData = [NSString stringWithFormat:@"acct=%@&pw=%@", [userName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]], [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]]];
    [self sendPostRequestForLoginWithData:[postData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] forUser:userName];
}

- (void)sendPostRequestForLoginWithData:(NSData *)postData forUser:(NSString *)userName
{
    NSURL *contentURL = [NSURL URLWithString:@"https://news.ycombinator.com/login"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:contentURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    //NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                       if (!error) {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self.spinner stopAnimating];
                               NSString *cookieToken =@"";
                               BOOL logged_in = NO;
                               NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
                               for (int i = 0; i < [cookies count]; i++) {
                                   NSHTTPCookie *cookie = [cookies objectAtIndex:i];
                                   if([[cookie name] isEqualToString:@"user"]){
                                       logged_in = YES;
                                   }
                                   cookieToken = [cookieToken stringByAppendingString:[NSString stringWithFormat:@"%@=%@;", [cookie name], [cookie value]]];
                               }
                               NSLog(@"%@", cookieToken);
                               if(logged_in) {
                                   UIAlertController *alertController = [UIAlertController
                                                                         alertControllerWithTitle:@""
                                                                         message:@"Successful Login"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                   UIAlertAction *cancelAction = [UIAlertAction
                                                                  actionWithTitle:NSLocalizedString(@"Ok", @"Ok")
                                                                  style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction *action){
                                                                      [self displayPageForLoggedInUser:userName];
                                                                  }];
                                   [alertController addAction:cancelAction];
                                   [self presentViewController:alertController animated:YES completion:^{}];
                                   [self.delegate addItemViewController:self didFinishEnteringCookie:cookieToken UserName:userName];
                               } else {
                                   UIAlertController *alertController = [UIAlertController
                                                                         alertControllerWithTitle:@""
                                                                         message:@"Invalid Combination of username and password"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                   UIAlertAction *cancelAction = [UIAlertAction
                                                                  actionWithTitle:NSLocalizedString(@"Ok", @"Ok")
                                                                  style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction *action){}];
                                   [alertController addAction:cancelAction];
                                   [self presentViewController:alertController animated:YES completion:^{}];
                               }
                           });
                       } else {
                           NSLog(@"Error making POST request-%@ error-%@",request, error);
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self.spinner stopAnimating];
                               UIAlertController *alertController = [UIAlertController
                                                                     alertControllerWithTitle:@""
                                                                     message:@"Internet Connectivity Issue"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
                               UIAlertAction *cancelAction = [UIAlertAction
                                                              actionWithTitle:NSLocalizedString(@"Ok", @"Ok")
                                                              style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action){}];
                               [alertController addAction:cancelAction];
                               [self presentViewController:alertController animated:YES completion:^{}];
                           });
                       }
                   }
     ];
    [task resume];
}

- (void)displayPageForLoggedInUser:(NSString *)userName
{
    [self.textView setHidden:NO];
    [self.textView setText:[ NSString stringWithFormat:@"Welcome, %@", userName]];
    [self.textView setFont:[UIFont boldSystemFontOfSize:14]];
    [self.textView setTextAlignment:NSTextAlignmentCenter];
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(self.textView.bounds.size.width, CGFLOAT_MAX)];
    CGFloat topCorrection = (self.textView.bounds.size.height - contentSize.height * self.textView.zoomScale) / 2.0;
    self.textView.contentOffset = CGPointMake(0, -topCorrection);
}

@end
