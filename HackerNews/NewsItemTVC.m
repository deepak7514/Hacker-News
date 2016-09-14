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
#import "NewsItem+Create.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@interface NewsItemTVC ()

@property (nonatomic, strong) NSArray *newsItems; // of News Items IDs
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
- (IBAction)refresh:(UIRefreshControl *)sender;
@end


@implementation NewsItemTVC

// whenever our Model is set, must update our View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Default Story Type
    //self.storyTypeURL = [HNFetcher URLforNewsItem:@"top"];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, -10, 0, 0);
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"unique"
                                                              ascending:YES
                                                               selector:@selector(compare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil cacheName:nil];
    
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor blueColor];
    self.spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/3);
    self.spinner.hidesWhenStopped = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if(_managedObjectContext == nil)
    {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = appDelegate.managedObjectContext;
    }
    return _managedObjectContext;
}

- (void)setNewsItems:(NSArray *)newsItems
{
    _newsItems = newsItems;
    [NewsItem loadNewsItemsFromArray:newsItems];
    [self.spinner stopAnimating];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    //[self.tableView reloadData];
    
}

#pragma mark - UITableViewDataSource

// the methods in this protocol are what provides the View its data
// (remember that Views are not allowed to own their data)

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    // Return the number of rows in the section (we only have one)
//    return [self.newsItems count];
//}

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
    //NewsItem *newsItem = [NewsItem newsItemWithNewsItemId:[self.newsItems objectAtIndex:indexPath.row] inManagedObjectContext:self.managedObjectContext];
    NewsItem *newsItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // update UILabels in the UITableViewCell
    cell.textLabel.text = newsItem.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@-%@", newsItem.unique, newsItem.url];
    
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

- (void)prepareNewsItemContentVC:(NewsItemContentVC *)vc toDisplayNewsItem:(NewsItem *)newsItem
{
    vc.newsItem = newsItem;
    vc.title = [NSString stringWithFormat:@"%@", newsItem.unique];
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
                    [self prepareNewsItemContentVC:segue.destinationViewController toDisplayNewsItem:[self.fetchedResultsController objectAtIndexPath:indexPath]];
                }
            }
        }
    }
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

- (IBAction)refresh:(UIRefreshControl *)sender {
    [self startDownloadingContent];
    [sender endRefreshing];
}
@end
