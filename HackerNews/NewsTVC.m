//
//  NewsTVC.m
//  HNews
//
//  Created by deepak.go on 25/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsTVC.h"
#import "NewsItemTVC.h"
#import "HN Fetcher/HNFetcher.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "LoginManager.h"
#import "HackerNews-Swift.h"

@interface NewsTVC ()

@property (strong, nonatomic) NSNumber *logged_in;
@property (strong, nonatomic) NSString *cookie;
@property (strong, nonatomic) NSString *userName;

@property (nonatomic) LoginManager *loginManager;

@end

@implementation NewsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.loginManager = [LoginManager sharedInstance];
    [self.loginManager addObserver:self forKeyPath:@"loggedIn" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"loggedIn"]) {
        [self.tableView reloadData];
    }
}

- (NSArray *)menuItems
{
    if (![self.loginManager loggedIn]) {
        return @[@"Login/SignUp", @"Top Stories", @"Best Stories", @"New Stories", @"Show Stories", @"Ask Stories", @"Job Stories"];
    } else {
        return @[[NSString stringWithFormat:@"Welcome %@", self.loginManager.userName], @"Top Stories", @"Best Stories", @"New Stories", @"Show Stories", @"Ask Stories", @"Job Stories", @"Favourite Stories", @"Hidden Stories", @"Logout"];
    }
}

- (NSString *)cellIdentifierForMenuItem: (NSString *)menuItem
{
    if ([menuItem hasSuffix:@"Stories"]) {
        return @"StoryItem Cell";
    } else {
        return @"LoginItem Cell";
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *menuItem = [self.menuItems objectAtIndex:indexPath.row];
    NSString *cellIdentifier = [self cellIdentifierForMenuItem:menuItem];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = menuItem;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *menuItem = [self.menuItems objectAtIndex:indexPath.row];
    if ([menuItem isEqualToString:@"Login/SignUp"]) {
        [self performSegueWithIdentifier:@"LoginScreen" sender:indexPath];
    } else if ([menuItem hasPrefix:@"Welcome"]) {
        [self performSegueWithIdentifier:@"WelcomeScreen" sender:indexPath];
    } else if ([menuItem hasSuffix:@"Stories"]) {
        [self performSegueWithIdentifier:@"StoryItem" sender:indexPath];
    } else if ([menuItem isEqualToString:@"Logout"]) {
        [self.loginManager signOut];
        [self.tableView reloadData];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    
    if([segue.identifier isEqualToString:@"LoginScreen"])
    {
        HNLoginViewController *dest = (HNLoginViewController *)[navController childViewControllers].firstObject;
    } else if([segue.identifier isEqualToString:@"WelcomeScreen"])
    {
        HNWelcomeViewController *dest = (HNWelcomeViewController *)[navController childViewControllers].firstObject;
    } else if([segue.identifier isEqualToString:@"StoryItem"]) {
        NewsItemTVC *dest = (NewsItemTVC *)[navController childViewControllers].firstObject;
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        NSString *menuItem = [self.menuItems objectAtIndex:indexPath.row];
        dest.storyType = [[[menuItem componentsSeparatedByString:@" "] objectAtIndex:0] lowercaseString];
        dest.title = menuItem;
    }
}

@end
