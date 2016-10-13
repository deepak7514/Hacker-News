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
#import "NetworkManager.h"
#import "HNContentToolbar.h"
#import "LoginManager.h"

@interface NewsItemContentVC ()<UISplitViewControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) NSString *html;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) HNContentToolbar *toolBar;
@property (nonatomic) NSString *cookieToken;
@end

@implementation NewsItemContentVC {
    NSInteger _currentFontSize;
    BOOL pageDidFinishedLoading;
    NSTimer *progressTimer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _currentFontSize = 100;
    
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.spinner startAnimating];
    
    if(self.html)
    {
        [self.webView loadHTMLString:[self.html description] baseURL:nil];
        [self.spinner stopAnimating];
    }
    
    self.cookieToken = [[LoginManager sharedInstance] cookieToken];
    [self fetchAuthTokenFromNewsItemId:self.newsItem.unique];
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
}

#pragma mark  - Prepare WebView

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.progressView.progress = 0;
    pageDidFinishedLoading = false;
    //0.01667 is roughly 1/60, so it will update at 60 FPS
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    pageDidFinishedLoading = true;
}

-(void)timerCallback:(NSTimer *)timer {
    if (pageDidFinishedLoading) {
        self.progressView.hidden = true;
        [progressTimer invalidate];
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
    self.toolBar = [[HNContentToolbar alloc] initWithNewsItemId:self.newsItem.unique itemURL:self.newsItem.url];
    CGSize viewSize = self.view.frame.size;
    self.toolBar.frame = CGRectMake(0, viewSize.height-44, viewSize.width, 44);
    
    [self.view addSubview:self.toolBar];
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
            [NetworkManager makeDataRequestWithMethod:@"GET"
                                            URLString:@"http://readability.com/api/content/v1/parser"
                                               params:@{@"url":self.newsItem.url,
                                                        @"token":@"b3e1c93a93f080bc01eb0480fffd6bdd3cb8a7fa"
                                                        }
                                               cookie:self.cookieToken
                             andExecuteBlockOnSuccess:^(id responseObject, NSURLResponse *response) {
                                 NSDictionary *propertyLists = (NSDictionary *)responseObject;
                                 NSString *htmlBody = [propertyLists valueForKey:@"content"];
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
                             }
                                            onFailure:^(NSError *error) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self.spinner stopAnimating];
                                                    NSString *htmlBody =
                                                    [NSString stringWithFormat:@"<div style=\"position:absolute; width:200px; height:200px; left:50%%; top:50%%; margin-left:-100px; margin-top:-100px;\"><p>Cannot connect to URL. Try after some time.</p></div>"];
                                                    NSString *html = [self getHTMLStringWithContent:htmlBody URL:self.newsItem.url title:self.newsItem.title domain:[[NSURL URLWithString:self.newsItem.url] host] itemID:self.newsItem.unique itemURL:itemURL author:self.newsItem.author dateInterval:dateInterval];
                                                    self.html = html;
                                                });
                                            }];
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
    [request setValue:self.cookieToken forHTTPHeaderField:@"cookie"];
    
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
                           BOOL itemVoted = NO;
                           BOOL itemHidden = NO;
                           BOOL itemLiked = NO;
                           NSString *hmacToken = nil;
                           NSString *authToken = nil;
                           TFHpple *parser = [TFHpple hppleWithHTMLData:[NSData dataWithContentsOfURL:localfile]];
                           
                           // Extracting Auth Token from ItemUrl
                           NSString *xpathQueryString = [NSString stringWithFormat:@"//a[@id='up_%@']", self.newsItem.unique];
                           NSArray *nodes = [parser searchWithXPathQuery:xpathQueryString];
                           for (TFHppleElement *element in nodes) {
                               if ([[element objectForKey:@"class"] isEqualToString:@"nosee"]) {
                                   itemVoted = YES;
                               }
                               NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[NSURL URLWithString:[element objectForKey:@"href"]]
                                                                           resolvingAgainstBaseURL:NO];
                               NSArray *queryItems = urlComponents.queryItems;
                               authToken = [self valueForKey:@"auth" fromQueryItems:queryItems];
                           }
                           
                           // Extracting Comment HMAC token from ItemUrl
                           xpathQueryString = @"//form";
                           nodes = [parser searchWithXPathQuery:xpathQueryString];
                           for (TFHppleElement *element in nodes) {
                               //NSLog(@"%@", element);
                               for (TFHppleElement *child in element.children) {
                                   if ([child.tagName isEqualToString:@"input"] && [[child objectForKey:@"name"] isEqual:@"hmac"]) {
                                       hmacToken = [child  objectForKey:@"value"];
                                       break;
                                   }
                               }
                            }
                           
                           // Extracting Item Info from ItemUrl
                           xpathQueryString = @"//td[@class='subtext']";
                           nodes = [parser searchWithXPathQuery:xpathQueryString];
                           for (TFHppleElement *element in nodes) {
                               NSLog(@"%@", [element content]);
                               for (TFHppleElement *child in element.children) {
                                    if([[child content] isEqualToString:@"unvote"]) {
                                        itemVoted = YES;
                                    } else if([[child content] isEqualToString:@"un-hide"]) {
                                        itemHidden = YES;
                                    }  else if([[child content] isEqualToString:@"un-favorite"]) {
                                        itemLiked = YES;
                                    }
                               }
                           }
                           
                           //we must dispatch this back to the main queue
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self.toolBar updateToolBarWithAuthToken:authToken hmacToken:hmacToken andNewsItemMarkedHidden:itemHidden favourite:itemLiked voted:itemVoted];
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

#pragma mark - Helper Methods
- (NSString *)getHTMLStringWithContent:(NSString *)mainContent URL:(NSString *)url title:(NSString *)title domain:(NSString *)domain itemID:(NSNumber *)itemID itemURL:(NSString *)itemURL author:(NSString *)author dateInterval:(NSString *)dateInterval
{
    NSString *html = [NSString stringWithFormat:@"<html><head> <meta charset=\"utf-8\">  <style type=\"text/css\">  body {font-family: \"Helvetica Neue\", sans-serif  !Important;-webkit-text-size-adjust: %d;  font-size: 16px !Important;background-color:none;  color: #454545;  width:90%% !Important;  padding-top:15px !Important;  padding-bottom:20px !Important;  margin: 0 auto !Important;  word-wrap: break-word !Important;  line-height:170%% !Important;  overflow: hidden;  }  textarea {  display: none !important;  }  input {  display: none !important;  }   form {  display: none !important;  }  .title {  font-weight:bold !Important;  font-size: 1.4em !Important;  line-height:1.1em !Important;  margin-bottom: 10px;  }  .title a {  text-decoration: none !Important;  color:#333 !Important;  }table,thead,tbody{ table-layout: fixed; max-width:100%% !important; }  table, tr, td {  background-color: transparent !important;  }  h1,h2,h3 {  font-size:1.0em !important;  }  .info {  font-size: 0.9em;  color: #999;  }.info a{ text-decoration: none; color: #999;}  .article a {  text-decoration: none !Important;  color: #333;  border-bottom:1px dashed;  }table {width: 100%% !important;max-width 100%% !important;}  img {  max-width: 100%% !important;  width: auto !important;  height: auto !important;  margin: 0 auto !important;border: 1px solid #DDD;  display: block !important;  }  .article video,  .article embed,  .article object {  display: none;  }  .article pre,  .article code {  white-space: pre-line;  font-size: 0.9em;  }  .article .img-1,  .article .wp-smiley,  .article .feedflare img,  .article img[src*='/smilies/'],  .article img[src*='.feedburner.com/~ff/'],  .article img[data-src*='/smilies/'],  .article img[data-src*='.feedburner.com/~ff/'] {  border: 0 !important;  outline: 0 !important;  margin: 0 !important;  background-color: transparent !important;  }  .article img[src*='.feedburner.com/~r/'],  .article img[data-src*='.feedburner.com/~r/'] {  display: none;  }  </style>  </head><body><div class=\"info\"><a href=\"http://%@\">%@</a></div><div class=\"title\"><a href=\"%@\">%@</a></div><div class=\"info\" style=\"margin-top: -15px;\"> %@ by %@ <a href=\"https://%@\">#%@</a></div><div class=\"article\">%@</div></body></html>", _currentFontSize, domain, domain, url, title, dateInterval, author, itemURL, itemID, mainContent ];
    return html;
}

@end
