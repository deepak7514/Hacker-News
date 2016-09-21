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

@interface NewsItemContentVC ()<UISplitViewControllerDelegate, UIWebViewDelegate>
@property (strong, nonatomic) NSString *html;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation NewsItemContentVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.spinner startAnimating];
    
    if(self.html)
    {
        [self.webView loadHTMLString:[self.html description] baseURL:nil];
        [self.spinner stopAnimating];
    }
}

#pragma mark - Properties

- (void)setHtml:(NSString *)html
{
    _html = html;
    [self.webView loadHTMLString:[html description] baseURL:nil];
    [self.spinner stopAnimating];
}

- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        // found it ... are we doing the Show Comments segue?
        if ([segue.identifier isEqualToString:@"Show Comments"]){
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
}

- (void)startDownloadingContent
{
    if (self.newsItem)
    {
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
                                    NSString *html =
                                        [NSString stringWithFormat:@"<html><head><title></title><style>img{max-width:100%%;height:auto !important;width:auto !important;};</style></head><body style=\"margin:20px; padding:0; background:transparent;\">%@</body></html>", htmlBody];
                                    self.html = html;
                                }
                                else {
                                    [self.spinner stopAnimating];
                                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:encodedURL]];
                                    [self.webView loadRequest:request];
                                }
                            });
                        } else {
                            NSLog(@"Error Fetching JSON Data from url-%@ error-%@",contentURL, error);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.spinner stopAnimating];
                                NSString *html =
                                [NSString stringWithFormat:@"<html><head><title></title><style>div{position:absolute;width:200px;height:200px;left:50%%;top:50%%;margin-left:-100px;margin-top:-100px;};</style></head><body><div><p>Cannot connect to URL. Try after some time.</p></div></body></html>"];
                                self.html = html;
                            });
                        }
                    }
                 ];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        } else {
            NSString *html =
            [NSString stringWithFormat:@"<html><head><title></title><style>img{max-width:100%%;height:auto !important;width:auto !important;};</style></head><body style=\"margin:20px; padding:0; background:transparent;\">%@</body></html>", self.newsItem.text];
            self.html = html;

        }
    }
}

#pragma mark - UISplitViewControllerDelegate

// this section added during Shutterbug demo

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


@end
