//
//  NewsItemContentVC.m
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItemContentVC.h"
#import "HNFetcher.h"
#import "CommentTVC.h"
#import "HNWebViewController.h"
#import <FormatterKit/FormatterKit.h>
#import "TFHpple.h"

@interface NewsItemContentVC ()<UISplitViewControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) NSString *html;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation NewsItemContentVC {
    int _currentFontSize;
    BOOL pageDidFinishedLoading;
    NSTimer *progressTimer;
    UIToolbar *toolBar;
    NSString *authToken; // token for making post requests
    NSString *hmacToken; // token for comment
}

enum actionSheetButtonIndex {
    kSafariButtonIndex,
    kChromeButtonIndex,
};

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // getting current Font Size from User Defaults
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ftsz"] == nil)
    {
        _currentFontSize = 100;
    }
    else
    {
        _currentFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"ftsz"];
    }
    
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.spinner startAnimating];
    
    if(self.html)
    {
        [self.webView loadHTMLString:[self.html description] baseURL:nil];
        [self.spinner stopAnimating];
    }
    
    [self initToolBar];
}

#pragma mark - Properties

- (void)setHtml:(NSString *)html
{
    self.newsItem.text = html;
    _html = html;
    [self.webView loadHTMLString:[html description] baseURL:nil];
    [self.spinner stopAnimating];
}

- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
    _webView.delegate = self;
    //_webView.backgroundColor = [UIColor clearColor];
}

#pragma mark  - Prepare WebView

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.progressView.progress = 0;
    pageDidFinishedLoading = false;
    //0.01667 is roughly 1/60, so it will update at 60 FPS
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    pageDidFinishedLoading = true;
}

-(void)timerCallback {
    if (pageDidFinishedLoading) {
        if (self.progressView.progress >= 1) {
            self.progressView.hidden = true;
            [progressTimer invalidate];
        }
        else {
            self.progressView.progress += 0.1;
        }
    }
    else {
        self.progressView.progress += 0.05;
        if (self.progressView.progress >= 0.95) {
            self.progressView.progress = 0.95;
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeReload)
    {
        NSLog(@"%@",request.URL);
    }
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [self performSegueWithIdentifier:@"Show Web" sender:request];
        return NO;
    }
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"Show Web"])
    {
        NSURLRequest *URLRequest = sender;
        HNWebViewController *webViewController = segue.destinationViewController;
        [webViewController loadURL:URLRequest.URL];
    } else if ([segue.identifier isEqualToString:@"Show Comments"]){
        if ([sender isKindOfClass:[UIBarButtonItem class]]) {
            // yes ... is the destination an NewsItemContentVC
            if ([segue.destinationViewController isKindOfClass:[CommentTVC class]]) {
                // yes ... then we know how to prepare for that segue!
                CommentTVC *vc = (CommentTVC *)segue.destinationViewController;
                vc.itemId = [ NSString stringWithFormat:@"%@", self.newsItem.unique ];
                vc.title = [ NSString stringWithFormat:@"Comments" ];
            }
        }
    }
}

#pragma mark - Setting the Text from the Item's URL

- (void)setNewsItem:(NewsItem *)newsItem
{
    _newsItem = newsItem;
    [self startDownloadingContent];
    [self fetchAuthTokenFromNewsItemId:newsItem.unique];
}

- (void)startDownloadingContent
{
    if (self.newsItem)
    {
        NSString *itemURL = [NSString stringWithFormat:@"news.ycombinator.com/item?id=%@",self.newsItem.unique];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[self.newsItem.time doubleValue]];
        TTTTimeIntervalFormatter *timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
        NSString *dateInterval = [timeIntervalFormatter stringForTimeInterval:[date timeIntervalSinceNow]];
        
        if(self.newsItem.url)
        {
            NSString *encodedURL = [self.newsItem.url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            NSURL *contentURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://readability.com/api/content/v1/parser?url=%@&token=b3e1c93a93f080bc01eb0480fffd6bdd3cb8a7fa",encodedURL]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:contentURL];
            
            // another configuration option is backgroundSessionConfiguration (multitasking API required though)
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            
            // create the session without specifying a queue to run completion handler on (thus, not main queue)
            // we also don't specify a delegate (since completion handler is all we need)
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            NSURLSessionDownloadTask *task =
                [session downloadTaskWithRequest:request
                    completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                        // this handler is not executing on the main queue, so we can't do UI directly here
                        if (!error) {
                            NSError *err = nil;
                            NSDictionary *propertyLists = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:localfile] options:0 error:&err];
                            if(err){
                                NSLog(@"Error Parsing JSON Data from url-%@ error-%@",contentURL, err);
                            }
                            NSString *htmlBody = [propertyLists valueForKey:@"content"];
                            //we must dispatch this back to the main queue
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if(htmlBody){
                                    NSString *html = [self getHTMLStringWithContent:htmlBody URL:self.newsItem.url title:self.newsItem.title domain:[[NSURL URLWithString:self.newsItem.url] host] itemID:self.newsItem.unique itemURL:itemURL author:self.newsItem.author dateInterval:dateInterval];
                                    self.html = html;
                                }
                                else {
                                    [self.spinner stopAnimating];
                                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.newsItem.url]];
                                    [self.webView loadRequest:request];
                                }
                            });
                        } else {
                            NSLog(@"Error Fetching JSON Data from url-%@ error-%@",contentURL, error);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.spinner stopAnimating];
                                NSString *htmlBody =
                                [NSString stringWithFormat:@"<div style=\"position:absolute; width:200px; height:200px; left:50%%; top:50%%; margin-left:-100px; margin-top:-100px;\"><p>Cannot connect to URL. Try after some time.</p></div>"];
                                NSString *html = [self getHTMLStringWithContent:htmlBody URL:self.newsItem.url title:self.newsItem.title domain:[[NSURL URLWithString:self.newsItem.url] host] itemID:self.newsItem.unique itemURL:itemURL author:self.newsItem.author dateInterval:dateInterval];
                                self.html = html;
                            });
                        }
                    }
                 ];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        } else {
            NSString *html = [self getHTMLStringWithContent:self.newsItem.text URL:@"#" title:self.newsItem.title domain:@"" itemID:self.newsItem.unique itemURL:itemURL author:self.newsItem.author dateInterval:dateInterval];
            self.html = html;

        }
    }
}

- (void)fetchAuthTokenFromNewsItemId:(NSNumber *)newsItemId
{
    
    NSString *itemURL = [NSString stringWithFormat:@"http://news.ycombinator.com/item?id=%@",newsItemId];
    NSURL *contentURL = [NSURL URLWithString:itemURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:contentURL];
    [request setValue:@"__cfduid=d056cbe7d5e82a9405b7e106b5431a0db1474726993; user=deepak7514&kPg1JqDQNn57Me1CH6Bl5x4fPXlMRLqI" forHTTPHeaderField:@"cookie"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task =
    [session downloadTaskWithRequest:request
                   completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                       // this handler is not executing on the main queue, so we can't do UI directly here
                       if (!error) {
                           NSString *hmac = nil;
                           NSString *auth = nil;
                           TFHpple *tutorialsParser = [TFHpple hppleWithHTMLData:[NSData dataWithContentsOfURL:localfile]];
                           
                           // Extracting Auth Token from ItemUrl
                           NSString *tutorialsXpathQueryString = [NSString stringWithFormat:@"//a[@id='up_%@']", self.newsItem.unique];
                           NSArray *tutorialsNodes = [tutorialsParser searchWithXPathQuery:tutorialsXpathQueryString];
                           for (TFHppleElement *element in tutorialsNodes) {
                               NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:[element objectForKey:@"href"]]
                                                                           resolvingAgainstBaseURL:NO];
                               NSArray *queryItems = urlComponents.queryItems;
                               auth = [self valueForKey:@"auth" fromQueryItems:queryItems];
                           }
                           
                           // Extracting Comment HMAC token from ItemUrl
                           tutorialsXpathQueryString = @"//form";
                           tutorialsNodes = [tutorialsParser searchWithXPathQuery:tutorialsXpathQueryString];
                           for (TFHppleElement *element in tutorialsNodes) {
                               //NSLog(@"%@", element);
                               for (TFHppleElement *child in element.children) {
                                   if ([child.tagName isEqualToString:@"input"] && [[child objectForKey:@"name"] isEqual:@"hmac"]) {
                                       hmac = [child  objectForKey:@"value"];
                                       break;
                                   }
                               }
                            }
                           
                           //we must dispatch this back to the main queue
                           dispatch_async(dispatch_get_main_queue(), ^{
                               authToken = auth;
                               hmacToken = hmac;
                           });
                       } else {
                           NSLog(@"Error Fetching JSON Data from url-%@ error-%@",contentURL, error);
                       }
                   }
     ];
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
}

- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

#pragma mark - ToolBar

-(void) initToolBar {
    
    CGSize viewSize = self.view.frame.size;
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, viewSize.height-44, viewSize.width, 44)];
    
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    toolBar.barStyle = UIBarStyleDefault;
    [self.view addSubview:toolBar];
    
    UIBarButtonItem *buttonUpVote = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"upvote.png"] style:UIBarButtonItemStylePlain target:self action:@selector(upvoteButtonTouchUp:)];
    
    UIBarButtonItem *buttonDownVote = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downvote.png"] style:UIBarButtonItemStylePlain target:self action:@selector(downvoteButtonTouchUp:)];
    
    UIBarButtonItem *buttonFavStory = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"favourite.png"] style:UIBarButtonItemStylePlain target:self action:@selector(likeStoryButtonTouchUp:)];
    
    UIBarButtonItem *buttonHideStory = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hide.png"] style:UIBarButtonItemStylePlain target:self action:@selector(hideStoryButtonTouchUp:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *buttonComment = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"comment.png"] style:UIBarButtonItemStylePlain target:self action:@selector(commentButtonTouchUp:)];
    
    UIBarButtonItem *buttonAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(buttonActionTouchUp:)];
    
    // Add butons to an array
    NSMutableArray *toolBarButtons = [[NSMutableArray alloc] init];
    [toolBarButtons addObject:buttonUpVote];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonDownVote];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonFavStory];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonHideStory];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonComment];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonAction];
    
    // Set buttons to tool bar
    [toolBar setItems:toolBarButtons animated:NO];
    [toolBar setTranslucent:NO];
}

#pragma mark - Action Sheet

- (void)showActionSheet {
    
    NSURL *theURL = [NSURL URLWithString:self.newsItem.url];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:self.newsItem.url message:nil preferredStyle:UIAlertControllerStyleActionSheet];
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
    [self presentViewController:actionSheet animated:YES completion:^{}];
}

#pragma mark - Button Actions
- (void)upvoteButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"vote?id=%@&how=up&auth=%@", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)downvoteButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"vote?id=%@&how=un&auth=%@", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)hideStoryButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"hide?id=%@&auth=%@", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)unHideStoryButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"hide?id=%@&auth=%@&un=t", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)likeStoryButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"fave?id=%@&auth=%@", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)unLikeStoryButtonTouchUp:(id)sender {
    NSString *url = [NSString stringWithFormat:@"fave?id=%@&auth=%@&un=t", self.newsItem.unique, authToken];
    [self sendGetRequest:url];
}

- (void)commentButtonTouchUp:(id)sender {
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
                                   NSString *postData = [NSString stringWithFormat:@"parent=%@&goto=item%%3Fid%%3D%@&hmac=%@&text=%@", self.newsItem.unique, self.newsItem.unique, hmacToken, [commentText.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]]];
                                   NSLog(@"Comment - %@, %@", commentText.text, postData);
                                   [self sendPostRequestForCommentWithData:[postData dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
                               }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)buttonActionTouchUp:(id)sender {
    [self showActionSheet];
}

- (void)sendPostRequestForCommentWithData:(NSData *)postData
{
    NSURL *contentURL = [NSURL URLWithString:@"https://news.ycombinator.com/comment"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:contentURL];
    [request setValue:@"__cfduid=d056cbe7d5e82a9405b7e106b5431a0db1474726993; user=deepak7514&kPg1JqDQNn57Me1CH6Bl5x4fPXlMRLqI"
   forHTTPHeaderField:@"cookie"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSLog(@"request - %@", postData);

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task =
    [session downloadTaskWithRequest:request
                   completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                       if (!error) {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               
                           });
                       } else {
                           NSLog(@"Error making POST request-%@ error-%@",request, error);
                       }
                   }
     ];
    [task resume];
}

- (void)sendGetRequest:(NSString *)action
{
    NSString *itemURL = [NSString stringWithFormat:@"https://news.ycombinator.com/%@", action];
    NSURL *contentURL = [NSURL URLWithString:itemURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:contentURL];
    [request setValue:@"__cfduid=d056cbe7d5e82a9405b7e106b5431a0db1474726993; user=deepak7514&kPg1JqDQNn57Me1CH6Bl5x4fPXlMRLqI"
   forHTTPHeaderField:@"cookie"];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task =
    [session downloadTaskWithRequest:request
                   completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                       if (!error) {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               
                           });
                       } else {
                           NSLog(@"Error making GET request-%@ error-%@",request, error);
                       }
                   }
     ];
    [task resume];
}

#pragma mark - UISplitViewControllerDelegate
- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}

#pragma mark - Helper Methods
- (NSString *)getHTMLStringWithContent:(NSString *)mainContent URL:(NSString *)url title:(NSString *)title domain:(NSString *)domain itemID:(NSNumber *)itemID itemURL:(NSString *)itemURL author:(NSString *)author dateInterval:(NSString *)dateInterval
{
    NSString *html = [NSString stringWithFormat:@"<html><head> <meta charset=\"utf-8\">  <style type=\"text/css\">  body {font-family: \"Helvetica Neue\", sans-serif  !Important;-webkit-text-size-adjust: %d;  font-size: 16px !Important;background-color:none;  color: #454545;  width:90%% !Important;  padding-top:15px !Important;  padding-bottom:20px !Important;  margin: 0 auto !Important;  word-wrap: break-word !Important;  line-height:170%% !Important;  overflow: hidden;  }  textarea {  display: none !important;  }  input {  display: none !important;  }   form {  display: none !important;  }  .title {  font-weight:bold !Important;  font-size: 1.4em !Important;  line-height:1.1em !Important;  margin-bottom: 10px;  }  .title a {  text-decoration: none !Important;  color:#333 !Important;  }table,thead,tbody{ table-layout: fixed; max-width:100%% !important; }  table, tr, td {  background-color: transparent !important;  }  h1,h2,h3 {  font-size:1.0em !important;  }  .info {  font-size: 0.9em;  color: #999;  }.info a{ text-decoration: none; color: #999;}  .article a {  text-decoration: none !Important;  color: #333;  border-bottom:1px dashed;  }table {width: 100%% !important;max-width 100%% !important;}  img {  max-width: 100%% !important;  width: auto !important;  height: auto !important;  margin: 0 auto !important;border: 1px solid #DDD;  display: block !important;  }  .article video,  .article embed,  .article object {  display: none;  }  .article pre,  .article code {  white-space: pre-line;  font-size: 0.9em;  }  .article .img-1,  .article .wp-smiley,  .article .feedflare img,  .article img[src*='/smilies/'],  .article img[src*='.feedburner.com/~ff/'],  .article img[data-src*='/smilies/'],  .article img[data-src*='.feedburner.com/~ff/'] {  border: 0 !important;  outline: 0 !important;  margin: 0 !important;  background-color: transparent !important;  }  .article img[src*='.feedburner.com/~r/'],  .article img[data-src*='.feedburner.com/~r/'] {  display: none;  }  </style>  </head><body><div class=\"info\"><a href=\"http://%@\">%@</a></div><div class=\"title\"><a href=\"%@\">%@</a></div><div class=\"info\" style=\"margin-top: -15px;\"> %@ by %@ <a href=\"https://%@\">#%@</a></div><div class=\"article\">%@</div></body></html>", _currentFontSize, domain, domain, url, title, dateInterval, author, itemURL, itemID, mainContent ];
    return html;
}
@end
