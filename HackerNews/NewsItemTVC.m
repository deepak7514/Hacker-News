//
//  NewsItemTVC.m
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItemTVC.h"
#import "NewsItemContentVC.h"
#import "HNFetcher.h"
#import "AppDelegate.h"

@interface NewsItemTVC ()

@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end


@implementation NewsItemTVC

// whenever our Model is set, must update our View
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.contentInset = UIEdgeInsetsMake(0, -10, 0, 0);
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor blueColor];
    self.spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/3);
    self.spinner.hidesWhenStopped = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    
//    NSLayoutConstraint *xconstraint = [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
//    NSLayoutConstraint *yconstraint = [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
//    [self.view addConstraints:@[xconstraint, yconstraint]];
    
    //NSLayoutConstraint *xCenterConstraint = [NSLayoutConstraint constraintWithItem:self.spinner attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    //[self.view addConstraint:xCenterConstraint];
    
    //NSLayoutConstraint *yCenterConstraint = [NSLayoutConstraint constraintWithItem:self.spinner attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    //[self.view addConstraint:yCenterConstraint];
    
    [self.spinner startAnimating];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    // Do your job, when done:
    [self startDownloadingContent];
}

- (void)reloadData
{
    // Reload table data
    [self.tableView reloadData];
    
    // End the refreshing
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

- (void)setNewsItems:(NSArray *)newsItems
{
    _newsItems = newsItems;
    //self.tableView.backgroundView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self reloadData];
    [self.spinner stopAnimating];
}

#pragma mark - UITableViewDataSource

// the methods in this protocol are what provides the View its data
// (remember that Views are not allowed to own their data)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    if(self.newsItems)
//    {
//        return 1;
//    }
//    else
//    {
//        // Display a message when the table is empty
//        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
//        
//        messageLabel.text = @"No data is currently available. Please pull down to refresh.";
//        messageLabel.textColor = [UIColor blackColor];
//        messageLabel.numberOfLines = 0;
//        messageLabel.textAlignment = NSTextAlignmentCenter;
//        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
//        [messageLabel sizeToFit];
//        
//        self.tableView.backgroundView = messageLabel;
//        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section (we only have one)
    return [self.newsItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we must be sure to use the same identifier here as in the storyboard!
    static NSString *CellIdentifier = @"News Item Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        //cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        //cell.textLabel.numberOfLines = 0;
        //cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0];
    }
    // Configure the cell...
    
    // get the photo out of our Model
    NSDictionary *newsItem = [self fetchNewsItem:[self.newsItems objectAtIndex:indexPath.row]];
    
    // update UILabels in the UITableViewCell
    // valueForKeyPath: supports "dot notation" to look inside dictionaries at other dictionaries
    cell.textLabel.text = [newsItem valueForKeyPath:HN_NEWSITEM_TITLE];
    cell.detailTextLabel.text = [newsItem valueForKeyPath:HN_NEWSITEM_URL];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellText = @"Go get some text for your cell.";
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:16.0];
    
    NSAttributedString *attributedText =
    [[NSAttributedString alloc] initWithString:cellText attributes:@{ NSFontAttributeName: cellFont }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return rect.size.height + 40;
}

#pragma mark - UITableViewDelegate

// when a row is selected and we are in a UISplitViewController,
//   this updates the Detail ImageViewController (instead of segueing to it)
// knows how to find an ImageViewController inside a UINavigationController in the Detail too
// otherwise, this does nothing (because detail will be nil and not "isKindOfClass:" anything)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the Detail view controller in our UISplitViewController (nil if not in one)
    id detail = self.splitViewController.viewControllers[1];
    // if Detail is a UINavigationController, look at its root view controller to find it
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController *)detail).viewControllers firstObject];
    }
    // is the Detail is an NewsItemContentVC?
    if ([detail isKindOfClass:[NewsItemContentVC class]]) {
        // yes ... we know how to update that!
        [self prepareNewsItemContentVC:detail toDisplayNewsItem:self.newsItems[indexPath.row]];
    }
}

#pragma mark - Navigation

// prepares the given ImageViewController to show the given photo
// used either when segueing to an ImageViewController
//   or when our UISplitViewController's Detail view controller is an ImageViewController

- (void)prepareNewsItemContentVC:(NewsItemContentVC *)vc toDisplayNewsItem:(NSString *)newsItemId
{
    vc.itemURL = [HNFetcher URLforItem:newsItemId];
    vc.title = [NSString stringWithFormat:@"Item Number: %@", newsItemId];
}

// In a story board-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        // find out which row in which section we're seguing from
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            // found it ... are we doing the Show Detail segue?
            if ([segue.identifier isEqualToString:@"Show Detail"]) {
                // yes ... is the destination an NewsItemContentVC
                if ([segue.destinationViewController isKindOfClass:[NewsItemContentVC class]]) {
                    // yes ... then we know how to prepare for that segue!
                    [self prepareNewsItemContentVC:segue.destinationViewController toDisplayNewsItem:[self.newsItems objectAtIndex:indexPath.row]];
                }
            }
        }
    }
}

- (NSDictionary *)fetchNewsItem:(NSString *)itemId
{
    NSURL *url = [HNFetcher URLforItem:itemId];
    // fetch the JSON data from HackerNews
    NSError *error = nil;
    NSData *jsonResults = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if(error){NSLog(@"Error Fetching JSON Data from url-%@ error-%@",url, error);}
    // convert it to a Property List (NSArray and NSDictionary)
    NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults options:0 error:&error];
    if(error){NSLog(@"Error Parsing JSON Data from url-%@ error-%@",url, error);}
    return propertyListResults;
}

#pragma mark - Setting the NewsItems from the StoryType's URL

- (void)setStoryTypeURL:(NSURL *)storyTypeURL
{
    _storyTypeURL = storyTypeURL;
    [self startDownloadingContent];
}

- (void)startDownloadingContent
{
    if (self.storyTypeURL)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.storyTypeURL];
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // create the session without specifying a queue to run completion handler on (thus, not main queue)
        // we also don't specify a delegate (since completion handler is all we need)
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        
        NSURLSessionDownloadTask *task = [session
                                            downloadTaskWithRequest:request
                                                completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error)
                                                {
                                                    // this handler is not executing on the main queue, so we can't do UI directly here
                                                    if (!error)
                                                    {
                                                        if ([request.URL isEqual:self.storyTypeURL])
                                                        {
                                                            NSError *error = nil;
                                                            NSData *jsonData = [NSData dataWithContentsOfURL:localfile options:0 error:&error];
                                                            if(error){NSLog(@"Error Fetching JSON Data from url-%@ error-%@",self.storyTypeURL, error);}
                                                            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
                                                            if(error){NSLog(@"Error Parsing JSON Data from url-%@ error-%@",self.storyTypeURL, error);}
                                                            //we must dispatch this back to the main queue
                                                            dispatch_async(dispatch_get_main_queue(), ^{ self.newsItems = jsonArray;});
                                                        }
                                                    } else
                                                    {
                                                        NSLog(@"Background Task failed : %@", error);
                                                    }
                                                }];
        [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    }
}

@end
