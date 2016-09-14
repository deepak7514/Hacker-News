//
//  NewsItemContentVC.m
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItemContentVC.h"
#import "CommentVC.h"
#import "HNFetcher.h"

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
}

#pragma mark - Properties

- (void)setHtml:(NSString *)html
{
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
            if ([segue.destinationViewController isKindOfClass:[CommentVC class]]) {
                // yes ... then we know how to prepare for that segue!
                CommentVC *vc = (CommentVC *)segue.destinationViewController;
                NSLog(@"Title %@ %@", self.title, [self.title class]);
                vc.itemId = self.title;
                vc.title = [NSString stringWithFormat:@"Comments"];
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
                                    self.html = @"";
                                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:encodedURL]];
                                    [self.webView loadRequest:request];
                                }
                            });
                        } else {
                            NSLog(@"Error Fetching JSON Data from url-%@ error-%@",contentURL, error);
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
