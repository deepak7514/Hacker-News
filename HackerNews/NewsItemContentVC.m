//
//  NewsItemContentVC.m
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItemContentVC.h"
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
 {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Setting the Text from the Item's URL

- (void)setItemURL:(NSURL *)ItemURL
{
    _itemURL = ItemURL;
    [self startDownloadingContent];
}

- (void)startDownloadingContent
{
    if (self.itemURL)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.itemURL];
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // create the session without specifying a queue to run completion handler on (thus, not main queue)
        // we also don't specify a delegate (since completion handler is all we need)
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                            // this handler is not executing on the main queue, so we can't do UI directly here
                                                            if (!error) {
                                                                if ([request.URL isEqual:self.itemURL]) {
                                                                    NSError *e = nil;
                                                                    NSString *htmlBody = nil;
                                                                    NSDictionary *propertyLists = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:localfile] options:0 error:NULL];
                                                                    NSString *urlEncoded = [[propertyLists valueForKey:HN_NEWSITEM_URL] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                                                                    NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://readability.com/api/content/v1/parser?url=%@&token=b3e1c93a93f080bc01eb0480fffd6bdd3cb8a7fa",urlEncoded]] options:0 error:&e];
                                                                    if(e)
                                                                    {
                                                                        NSLog(@"Error Fetching JSON Data from url-%@ error-%@",[propertyLists valueForKey:HN_NEWSITEM_URL], e);
                                                                        htmlBody = @"<div><p style=\"font-size: 40px;text-align: center;\">Cannot Parse Content. Try to Open in External Browser.</p></div>";
                                                                    }
                                                                    else
                                                                    {
                                                                    NSDictionary *jsonContent = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&e];
                                                                    if(e){NSLog(@"Error Parsing JSON Data from url-%@ error-%@",[propertyLists valueForKey:HN_NEWSITEM_URL], e);}
                                                                    htmlBody = [jsonContent valueForKey:@"content"];
                                                                    }
                                                                    //token=b3e1c93a93f080bc01eb0480fffd6bdd3cb8a7fa
                                                                    //we must dispatch this back to the main queue
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        NSString *html =
                                                                        [NSString stringWithFormat:@"<html><head><title></title><style>img{max-width:100%%;height:auto !important;width:auto !important;};</style></head><body style=\"margin:20px; padding:0; background:transparent;\">%@</body></html>", htmlBody];
                                                                        self.html = html;
                                                                    });
                                                                }
                                                            } else
                                                            {
                                                                NSLog(@"Background Task failed : %@", error);
                                                            }
                                                        }];
        [task resume]; // don't forget that all NSURLSession tasks start out suspended!
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
