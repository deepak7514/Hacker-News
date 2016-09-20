//
//  CommentTVC.m
//  HackerNews
//
//  Created by deepak.go on 17/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "CommentTVC.h"

#import "HN Fetcher/HNFetcher.h"
#import <FormatterKit/FormatterKit.h>

#import "RATreeView.h"
#import "RADataObject.h"
#import "RATableViewCell.h"

@interface CommentTVC () <RATreeViewDelegate, RATreeViewDataSource>

@property (strong, nonatomic) NSArray *data;
@property (weak, nonatomic) RATreeView *treeView;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation CommentTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RATreeView *treeView = [[RATreeView alloc] initWithFrame:self.view.bounds];
    
    treeView.delegate = self;
    treeView.dataSource = self;
    treeView.treeFooterView = [UIView new];
    treeView.separatorStyle = RATreeViewCellSeparatorStyleSingleLine;
    
    [treeView setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1.0]];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor blueColor];
    self.spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/3);
    self.spinner.hidesWhenStopped = YES;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    
    self.treeView = treeView;
    self.treeView.frame = self.view.bounds;
    self.treeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:treeView atIndex:0];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    [self.treeView registerNib:[UINib nibWithNibName:NSStringFromClass([RATableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([RATableViewCell class])];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    int systemVersion = [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue];
    if (systemVersion >= 7 && systemVersion < 8) {
        CGRect statusBarViewRect = [[UIApplication sharedApplication] statusBarFrame];
        float heightPadding = statusBarViewRect.size.height+self.navigationController.navigationBar.frame.size.height;
        self.treeView.scrollView.contentInset = UIEdgeInsetsMake(heightPadding, 0.0, 0.0, 0.0);
        self.treeView.scrollView.contentOffset = CGPointMake(0.0, -heightPadding);
    }
    
    self.treeView.frame = self.view.bounds;
}

#pragma mark TreeView Delegate methods

- (CGFloat)treeView:(RATreeView *)treeView heightForRowForItem:(id)item
{
    RADataObject *cell = (RADataObject *)item;
    NSInteger level = [self.treeView levelForCellForItem:item];
    if(cell.commentText)
    {
        NSAttributedString *attributedText =
        [[NSAttributedString alloc] initWithString:cell.commentText attributes:@{ NSFontAttributeName: [UIFont italicSystemFontOfSize:12]}];
        return 20 + [attributedText boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - (5 + 15*level), CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                 context:nil].size.height;
    } else {
        return 44;
    }
}

- (BOOL)treeView:(RATreeView *)treeView canEditRowForItem:(id)item
{
    return NO;
}

- (void)treeView:(RATreeView *)treeView willExpandRowForItem:(id)item
{
    RADataObject *obj = (RADataObject *)item;
    if([obj.children count])
    {
        RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item];
        cell.customTitleLabel.text = [NSString stringWithFormat:@"[-]%@",[cell.customTitleLabel.text substringFromIndex:3]];
    }
}

- (void)treeView:(RATreeView *)treeView willCollapseRowForItem:(id)item
{
    RADataObject *obj = (RADataObject *)item;
    if([obj.children count])
    {
        RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item];
        cell.customTitleLabel.text = [NSString stringWithFormat:@"[+]%@",[cell.customTitleLabel.text substringFromIndex:3]];
    }
}

- (void)treeView:(RATreeView *)treeView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowForItem:(id)item
{
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    RADataObject *parent = [self.treeView parentForItem:item];
    NSInteger index = 0;
    
    if (parent == nil) {
        index = [self.data indexOfObject:item];
        NSMutableArray *children = [self.data mutableCopy];
        [children removeObject:item];
        self.data = [children copy];
        
    } else {
        index = [parent.children indexOfObject:item];
        [parent removeChild:item];
    }
    
    [self.treeView deleteItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent withAnimation:RATreeViewRowAnimationRight];
    if (parent) {
        [self.treeView reloadRowsForItems:@[parent] withRowAnimation:RATreeViewRowAnimationNone];
    }
}

#pragma mark TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item
{
    RADataObject *dataObject = item;
    
    NSInteger level = [self.treeView levelForCellForItem:item];
    NSUInteger children = [dataObject.children count];
    BOOL expanded = [self.treeView isCellForItemExpanded:item];
    NSString *detailText = [NSString localizedStringWithFormat:@"%@ %@ %@", (children>0)?(expanded?@"[-]":@"[+]"):@" ", dataObject.userName, dataObject.dateInterval];
    
    RATableViewCell *cell = [self.treeView dequeueReusableCellWithIdentifier:NSStringFromClass([RATableViewCell class])];
    [cell setupWithTitle:detailText detailText:dataObject.commentText level:level];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)treeView:(RATreeView *)treeView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.data count];
    }
    
    RADataObject *data = item;
    return [data.children count];
}

- (id)treeView:(RATreeView *)treeView child:(NSInteger)index ofItem:(id)item
{
    RADataObject *data = item;
    if (item == nil) {
        return [self.data objectAtIndex:index];
    }
    
    return data.children[index];
}

#pragma mark - Helpers

- (void)setItemId:(NSString *)itemId
{
    _itemId = itemId;
    [self startDownloadingContent];
}

- (void)startDownloadingContent
{
    if (self.itemId)
    {
        NSURL *contentURL = [HNFetcher URLforComments:self.itemId];
        
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
                               //we must dispatch this back to the main queue
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   self.data = [self loadComments:[propertyLists objectForKey:@"children"]];
                                   [self.spinner stopAnimating];
                                   [self.treeView reloadData];
                               });
                           } else {
                               NSLog(@"Error Fetching JSON Data from url-%@ error-%@",contentURL, error);
                           }
                       }
         ];
        [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    }
}

- (NSArray *)loadComments:(NSDictionary *)data
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if([data count])
    {
        for (NSDictionary* comment in data) {
            RADataObject *obj = nil;
            if([comment objectForKey:@"text"])
            {
                NSAttributedString* attrString =
                [[NSAttributedString alloc] initWithData:[[comment objectForKey:@"text"] dataUsingEncoding:NSUTF8StringEncoding]
                                                 options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                           NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                      documentAttributes:nil error:nil];
                
                NSDateFormatter *dateStringParser = [[NSDateFormatter alloc] init];
                [dateStringParser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.000Z"];
                
                NSDate *date = [dateStringParser dateFromString:[comment objectForKey:@"created_at"]];
                TTTTimeIntervalFormatter *timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
                NSString *dateInterval = [timeIntervalFormatter stringForTimeInterval:[date timeIntervalSinceNow]];
                
                obj = [RADataObject dataObjectWithUserName:[comment objectForKey:@"author"] dateInterval:dateInterval CommentText:[attrString string] children:[self loadComments:[comment objectForKey:@"children"]]];
            } else {
                obj = [RADataObject dataObjectWithUserName:@" " dateInterval:@" " CommentText:@"[Deleted comment]" children:[self loadComments:[comment objectForKey:@"children"]]];
            }
            [result addObject:obj];
        }
    }
    return [result copy];
}

@end

