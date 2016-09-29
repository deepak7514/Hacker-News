//
//  HNWebViewController.m
//  HackerNews
//
//  Created by deepak.go on 26/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "HNWebViewController.h"

@interface HNWebViewController()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
- (IBAction)backButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopButton;

@end

@implementation HNWebViewController
{
    NSURL *_URLToLoad;
    BOOL pageDidFinishedLoading;
    NSTimer *progressTimer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self showActivityIndicators];
    
    [self.webView setDelegate:self];
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    //[self.webView setBackgroundColor:[UIColor clearColor]];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:_URLToLoad]];
}

- (void)loadURL:(NSURL *)URL
{
    _URLToLoad = URL;
}

#pragma mark - WebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [self hideActivityIndicators];
    [self toggleBackForwardButtons];
    
    pageDidFinishedLoading = false;
    self.progressView.progress = 0;
    //0.01667 is roughly 1/60, so it will update at 60 FPS
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    pageDidFinishedLoading = true;
    
    [self toggleBackForwardButtons];
}

#pragma mark - Helper Methods

- (void)timerCallback {
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

-(void) toggleBackForwardButtons {
    self.forwardButton.enabled = self.webView.canGoForward;
    self.stopButton.enabled = self.webView.loading;
}

-(void)showActivityIndicators {
    [self.spinner setHidden:NO];
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)hideActivityIndicators {
    [self.spinner setHidden:YES];
    [self.spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Button Actions

- (IBAction)backButton:(id)sender {
    
    if([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
}

@end
