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
#import "StoryType+Create.h"
#import "SWRevealViewController.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <FormatterKit/FormatterKit.h>
#import "NetworkManager.h"

@interface NewsItemTVC ()

@property (nonatomic, strong) NSArray *newsItems; // of News Items IDs
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
- (IBAction)refresh:(UIRefreshControl *)sender;
@end


@implementation NewsItemTVC

// whenever our Model is set, must update our View
- (void)viewDidLoad {
    [super viewDidLoad];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    if(self.storyType == nil){
        // Default Story Type
        self.title = @"Top Stories";
        self.storyType = @"top";
    }
    [self startDownloadingContent];
    
    self.tableView.estimatedRowHeight = 66;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor blueColor];
    self.spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/3);
    self.spinner.hidesWhenStopped = YES;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
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
    [self modifyFetchedResultsControllerWithStoryType:self.storyType withNewsItems:newsItems];
    [self.spinner stopAnimating];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
}

- (void)modifyFetchedResultsControllerWithStoryType:(NSString *)storyType withNewsItems:(NSArray *)newsItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@", storyType];
    
    
    if(self.fetchedResultsController == nil)
    {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"StoryType"];
        request.predicate = predicate;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index"
                                                                  ascending:YES
                                                                   selector:@selector(compare:)]];
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.managedObjectContext
                                                                              sectionNameKeyPath:nil cacheName:nil];
    } else {
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
        NSError *error;
        if (![[self fetchedResultsController] performFetch:&error]) {
            // Update to handle the error appropriately.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we must be sure to use the same identifier here as in the storyboard!
    static NSString *CellIdentifier = @"News Item Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    
    // get the newsItem out of our Model
    StoryType *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // update UILabels in the UITableViewCell
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.text = story.newsItem.title;
    titleLabel.font = [UIFont boldSystemFontOfSize:13];
    
    UILabel *userNameLabel = (UILabel *)[cell viewWithTag:101];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[story.newsItem.time doubleValue]];
    TTTTimeIntervalFormatter *timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
    NSString *dateInterval = [timeIntervalFormatter stringForTimeInterval:[date timeIntervalSinceNow]];
    userNameLabel.text = [NSString stringWithFormat:@"Submitted %@ by %@", dateInterval, story.newsItem.author];
    userNameLabel.font = [UIFont italicSystemFontOfSize:12];
    
    UILabel *uriLabel = (UILabel *)[cell viewWithTag:102];
    uriLabel.text = story.newsItem.url;
    uriLabel.font = [UIFont italicSystemFontOfSize:12];
    
    UILabel *scoreLabel = (UILabel *)[cell viewWithTag:103];
    scoreLabel.text = [NSString stringWithFormat:@"S:%@", story.newsItem.score];
    scoreLabel.font = [UIFont italicSystemFontOfSize:13];
    
    UILabel *commentsLabel = (UILabel *)[cell viewWithTag:104];
    commentsLabel.text = [NSString stringWithFormat:@"C:%@", story.newsItem.descendants? :@0];
    commentsLabel.font = [UIFont italicSystemFontOfSize:13];
    
    return cell;
}

#pragma mark - Navigation

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
                    [self prepareNewsItemContentVC:segue.destinationViewController toDisplayNewsItem:[(StoryType *)[self.fetchedResultsController objectAtIndexPath:indexPath] newsItem]];
                }
            }
        }
    }
}

- (void)prepareNewsItemContentVC:(NewsItemContentVC *)vc toDisplayNewsItem:(NewsItem *)newsItem
{
    vc.newsItem = newsItem;
    vc.title = [NSString stringWithFormat:@"%@", newsItem.unique];
}

#pragma mark - Setting the NewsItems from the StoryType's URL

- (void)startDownloadingContent
{
    if (self.storyType)
    {
        NSURL *storyTypeURL = [HNFetcher URLforNewsItem:self.storyType];
        
        id successBlock = ^(id responseObject, NSURLResponse *response) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.newsItems = (NSArray *)responseObject;
                [NewsItem loadNewsItemsFromArray:self.newsItems storyType:self.storyType];
            });
        };
        
        id errorBlock = ^(NSError *error) {
            NSArray *stories = [StoryType newsItemsForStoryType:self.storyType inManagedObjectContext:self.managedObjectContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(stories == nil)
                {
                    UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
                    noDataLabel.text = @"No data available";
                    noDataLabel.textColor = [UIColor blackColor];
                    noDataLabel.textAlignment = NSTextAlignmentCenter;
                    [self.spinner stopAnimating];
                    self.tableView.backgroundView = noDataLabel;
                } else {
                    self.newsItems = stories;
                }
            });
        };
        
        [NetworkManager makeDataRequestWithMethod:@"GET"
                                        URLString:[storyTypeURL absoluteString]
                                           params:nil
                                           cookie:nil
                         andExecuteBlockOnSuccess:successBlock
                                        onFailure:errorBlock];
    }
}

- (IBAction)refresh:(UIRefreshControl *)sender {
    [self startDownloadingContent];
    [sender endRefreshing];
}
@end
