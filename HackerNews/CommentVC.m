//
//  CommentVC.m
//  HackerNews
//
//  Created by deepak.go on 05/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "CommentVC.h"

@interface CommentVC ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation CommentVC

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    [self.spinner startAnimating];
    
    NSString *url = [NSString stringWithFormat:@"https://news.ycombinator.com/item?id=%@", self.itemId];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.spinner stopAnimating];
    [self.webView loadRequest:request];
}

#pragma mark - Properties

- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
    _webView.delegate = self;
    _webView.backgroundColor = [UIColor clearColor];
}

@end
