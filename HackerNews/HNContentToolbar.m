//
//  HNContentToolbar.m
//  HackerNews
//
//  Created by deepak.go on 12/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "HNContentToolbar.h"
#import "NetworkManager.h"
#import "LoginManager.h"
#import "HackerNews-Swift.h"

@interface HNContentToolbar()

@property (nonatomic) UIBarButtonItem *buttonUpVote;
@property (nonatomic) UIBarButtonItem *buttonDownVote;
@property (nonatomic) UIBarButtonItem *buttonFavStory;
@property (nonatomic) UIBarButtonItem *buttonHideStory;
@property (nonatomic) UIBarButtonItem *buttonComment;
@property (nonatomic) UIBarButtonItem *buttonAction;
@property (nonatomic) UIBarButtonItem *flexibleSpace;

@property (nonatomic) BOOL itemVoted;
@property (nonatomic) BOOL itemHidden;
@property (nonatomic) BOOL itemLiked;

@property (nonatomic) BOOL userLoggedIn;
@property (nonatomic) NSString *cookieToken;
@property (nonatomic) NSNumber *newsItemId;
@property (nonatomic) NSString *newsItemURL;
@property (nonatomic) NSString *authToken;
@property (nonatomic) NSString *hmacToken;

@end

@implementation HNContentToolbar

- (instancetype)initWithNewsItemId:(NSNumber *)newsitemId itemURL: (NSString *)newsItemURL
{
    self = [super init];
    if (self) {
        self.newsItemId = newsitemId;
        self.newsItemURL = newsItemURL;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.barStyle = UIBarStyleDefault;
        
        self.buttonUpVote = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"upvote.png"] style:UIBarButtonItemStylePlain target:self action:@selector(upvoteButtonTouchUp:)];
        self.buttonDownVote = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downvote.png"] style:UIBarButtonItemStylePlain target:self action:@selector(downvoteButtonTouchUp:)];
        self.buttonDownVote.enabled = NO;
        self.buttonFavStory = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"like.png"] style:UIBarButtonItemStylePlain target:self action:@selector(likeStoryButtonTouchUp:)];
        self.buttonHideStory = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hide.png"] style:UIBarButtonItemStylePlain target:self action:@selector(hideStoryButtonTouchUp:)];
        self.buttonComment = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"comment.png"] style:UIBarButtonItemStylePlain target:self action:@selector(commentButtonTouchUp:)];
        self.buttonAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(buttonActionTouchUp:)];
        self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        // Add butons to an array
        NSMutableArray *toolBarButtons = [[NSMutableArray alloc] init];
        [toolBarButtons addObject:self.buttonUpVote];
        [toolBarButtons addObject:self.flexibleSpace];
        [toolBarButtons addObject:self.buttonDownVote];
        [toolBarButtons addObject:self.flexibleSpace];
        [toolBarButtons addObject:self.buttonFavStory];
        [toolBarButtons addObject:self.flexibleSpace];
        [toolBarButtons addObject:self.buttonHideStory];
        [toolBarButtons addObject:self.flexibleSpace];
        [toolBarButtons addObject:self.buttonComment];
        [toolBarButtons addObject:self.flexibleSpace];
        [toolBarButtons addObject:self.buttonAction];
        
        // Set buttons to tool bar
        [self setItems:toolBarButtons animated:NO];
        [self setTranslucent:NO];
    }
    return self;
}

- (NSString *)cookieToken
{
    if (_cookieToken != nil && ![_cookieToken isEqualToString:@""]) {
        return _cookieToken;
    }
    _cookieToken = [[LoginManager sharedInstance] cookieToken];
    return _cookieToken;
}

- (BOOL)userLoggedIn
{
    if (_userLoggedIn) {
        return _userLoggedIn;
    }
    _userLoggedIn = [[LoginManager sharedInstance] loggedIn];
    return _userLoggedIn;
}

- (void)updateToolBarWithAuthToken:(NSString *)authToken
                         hmacToken:(NSString *)hmacToken
           andNewsItemMarkedHidden:(BOOL)hidden
                         favourite:(BOOL)liked
                             voted:(BOOL)voted
{
    self.authToken = authToken;
    self.hmacToken = hmacToken;
    self.itemHidden = hidden;
    self.itemLiked = liked;
    self.itemVoted = voted;
}

- (void)setItemHidden:(BOOL)itemHidden
{
    _itemHidden = itemHidden;
    if (itemHidden) {
        [self.buttonHideStory setAction:@selector(unHideStoryButtonTouchUp:)];
        [self.buttonHideStory setImage:[UIImage imageNamed:@"unhide.png"]];
    } else {
        [self.buttonHideStory setAction:@selector(hideStoryButtonTouchUp:)];
        [self.buttonHideStory setImage:[UIImage imageNamed:@"hide.png"]];
    }
}

- (void)setItemLiked:(BOOL)itemLiked
{
    _itemLiked = itemLiked;
    if (itemLiked) {
        [self.buttonFavStory setAction:@selector(unLikeStoryButtonTouchUp:)];
        [self.buttonFavStory setImage:[UIImage imageNamed:@"unlike.png"]];
    } else {
        [self.buttonFavStory setAction:@selector(likeStoryButtonTouchUp:)];
        [self.buttonFavStory setImage:[UIImage imageNamed:@"like.png"]];
    }
}

- (void)setItemVoted:(BOOL)itemVoted
{
    self.buttonUpVote.enabled = !itemVoted;
    self.buttonDownVote.enabled = itemVoted;
}

#pragma mark - Button Actions
- (void)upvoteButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/vote"
                                           params:@{@"id":self.newsItemId,
                                                    @"how":@"up",
                                                    @"auth":self.authToken
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemVoted = YES;
    } else {
        [self presentLoggedInError];
    }
}

- (void)downvoteButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/vote"
                                           params:@{@"id":self.newsItemId,
                                                    @"how":@"un",
                                                    @"auth":self.authToken
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemVoted = NO;
    } else {
        [self presentLoggedInError];
    }
}

- (void)hideStoryButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/hide"
                                           params:@{@"id":self.newsItemId,
                                                    @"auth":self.authToken
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemHidden = YES;
    } else {
        [self presentLoggedInError];
    }
}

- (void)unHideStoryButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/hide"
                                           params:@{@"id":self.newsItemId,
                                                    @"auth":self.authToken,
                                                    @"un":@"t"
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemHidden = NO;
    } else {
        [self presentLoggedInError];
    }
}

- (void)likeStoryButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/fave"
                                           params:@{@"id":self.newsItemId,
                                                    @"auth":self.authToken
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemLiked = YES;
    } else {
        [self presentLoggedInError];
    }
}

- (void)unLikeStoryButtonTouchUp:(id)sender {
    if (self.userLoggedIn) {
        [NetworkManager makeHTMLRequestWithMethod:@"GET"
                                        URLString:@"https://news.ycombinator.com/fave"
                                           params:@{@"id":self.newsItemId,
                                                    @"auth":self.authToken,
                                                    @"un":@"t"
                                                    }
                                           cookie:self.cookieToken
                         andExecuteBlockOnSuccess:nil
                                        onFailure:nil];
        self.itemLiked = NO;
    } else {
        [self presentLoggedInError];
    }
}

- (void)commentButtonTouchUp:(id)sender {
    
    if (self.userLoggedIn) {
    
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Add Comment"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = NSLocalizedString(@"Comment", @"Enter Comment");
         }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                           NSLog(@"Cancel action");
                                       }];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Submit", @"Submit Comment")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       UITextField *commentText = alertController.textFields.firstObject;
                                       [NetworkManager makeHTMLRequestWithMethod:@"POST"
                                                                       URLString:@"https://news.ycombinator.com/comment"
                                                                          params:@{@"parent":self.newsItemId,
                                                                                   @"goto":[NSString stringWithFormat:@"item%%3Fid%%3D%@", self.newsItemId],
                                                                                   @"hmac":self.hmacToken,
                                                                                   @"text":commentText.text
                                                                                   }
                                                                          cookie:self.cookieToken
                                                        andExecuteBlockOnSuccess:nil
                                                                       onFailure:nil];
                                   }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [(UIViewController *)[self.superview nextResponder] presentViewController:alertController animated:YES completion:^{}];
    } else {
        [self presentLoggedInError];
    }
}

- (void)buttonActionTouchUp:(id)sender {
    [self showActionSheet];
}

#pragma mark - Action Sheet

- (void)showActionSheet {
    
    NSURL *theURL = [NSURL URLWithString:self.newsItemURL];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:self.newsItemURL message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        // Cancel button tappped do nothing.
        
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // safari button tapped.
        [[UIApplication sharedApplication] openURL:theURL];
    }]];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        // Chrome is installed, add the option to open in chrome.
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Open in Chrome" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *scheme = theURL.scheme;
            
            // Replace the URL Scheme with the Chrome equivalent.
            NSString *chromeScheme = nil;
            if ([scheme isEqualToString:@"http"]) {
                chromeScheme = @"googlechrome";
            } else if ([scheme isEqualToString:@"https"]) {
                chromeScheme = @"googlechromes";
            }
            
            // Proceed only if a valid Google Chrome URI Scheme is available.
            if (chromeScheme) {
                NSString *absoluteString = [theURL absoluteString];
                NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
                NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
                NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
                NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
                
                // Open the URL with Chrome.
                [[UIApplication sharedApplication] openURL:chromeURL];
            }
        }]];
    }
    [(UIViewController *)[self.superview nextResponder] presentViewController:actionSheet animated:YES completion:^{}];
}

- (void)presentLoggedInError
{
    UIViewController *superViewController = (UIViewController *)[self.superview nextResponder];
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@""
                                          message:@"Please Login"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", @"Ok")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action){
                                       HNLoginViewController *loginVC = [superViewController.storyboard instantiateViewControllerWithIdentifier:@"HNLoginViewcontroller"];
                                       [superViewController.navigationController pushViewController:loginVC animated:YES];
                                   }];
    [alertController addAction:cancelAction];
    [superViewController presentViewController:alertController animated:YES completion:^{}];
}

@end
