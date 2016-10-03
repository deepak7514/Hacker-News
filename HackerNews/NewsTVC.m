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

@interface NewsTVC ()
@property (strong, nonatomic) NSNumber *logged_in;
@property (strong, nonatomic) NSString *cookie;
@property (strong, nonatomic) NSString *userName;
@end

@implementation NewsTVC
{
    NSArray *itemForTitle;
    NSArray *itemsForNewUsers;
    NSArray *itemsForLoggedInUsers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    itemForTitle = @[@"Login", @"Welcome"];
    itemsForNewUsers = @[@"Top Stories", @"Best Stories", @"New Stories", @"Show Stories", @"Ask Stories", @"Job Stories"];
    itemsForLoggedInUsers = @[@"Favourite Stories", @"Hidden Stories", @"Logout"];
}

- (NSNumber *)logged_in
{
    if(_logged_in == nil)
    {
        _logged_in = @0;
    }
    return _logged_in;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    numberOfRows += [itemsForNewUsers count];
    numberOfRows += [self.logged_in boolValue]?[itemsForLoggedInUsers count]:0;
    
    return 1 + numberOfRows; // 1 for title
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = nil;
    if(indexPath.row == 0) {
        CellIdentifier = [itemForTitle objectAtIndex:[self.logged_in intValue]];
    } else if(indexPath.row <= [itemsForNewUsers count]) {
        CellIdentifier = [itemsForNewUsers objectAtIndex:(indexPath.row - 1)];
    } else {
        CellIdentifier = [itemsForLoggedInUsers objectAtIndex:(indexPath.row - [itemsForNewUsers count] - 1)];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%@ Cell",CellIdentifier] forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if([self.logged_in isEqual: @1] && indexPath.row == 0){
       cell.textLabel.text = [NSString stringWithFormat:@"Hi, %@", self.userName ];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = nil;
    if(indexPath.row == 0) {
        [self performSegueWithIdentifier:@"Login" sender:indexPath];
    } else if(indexPath.row >=1 && indexPath.row <= [itemsForNewUsers count]) {
        [self performSegueWithIdentifier:@"Menu" sender:indexPath];
    } else {
        CellIdentifier = [itemsForLoggedInUsers objectAtIndex:(indexPath.row - [itemsForNewUsers count] - 1)];
        if([CellIdentifier isEqualToString:@"Logout"]) {
            self.logged_in = @0;
            self.userName = nil;
            self.cookie = nil;
            NSLog(@"User Logged Out");
        } else {
            [self performSegueWithIdentifier:@"Menu" sender:indexPath];
        }
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"Login"])
    {
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        LoginViewController *dest = (LoginViewController *)[navController childViewControllers].firstObject;
        dest.delegate = self;
    } else if([segue.identifier isEqualToString:@"Menu"]) {
    
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        NewsItemTVC *dest = (NewsItemTVC *)[navController childViewControllers].firstObject;
        
        NSString *CellIdentifier = nil;
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        if(indexPath.row == 0) {
            CellIdentifier = [itemForTitle objectAtIndex:[self.logged_in intValue]];
        } else if(indexPath.row <= [itemsForNewUsers count]) {
            CellIdentifier = [itemsForNewUsers objectAtIndex:(indexPath.row - 1)];
        } else {
            CellIdentifier = [itemsForLoggedInUsers objectAtIndex:(indexPath.row - [itemsForNewUsers count] - 1)];
        }
        if([CellIdentifier hasSuffix:@"Stories"]) {
            CellIdentifier = [[CellIdentifier componentsSeparatedByString:@" "] objectAtIndex:0];
            dest.storyType = [CellIdentifier lowercaseString];
        } else {
            dest.storyType  = @"top";
        }
        dest.title = [NSString stringWithFormat:@"%@ Stories", [NSString stringWithFormat:@"%@",CellIdentifier]];
        dest.cookieToken = self.cookie;
    }
}

#pragma mark - Login View Controller Delegate
- (void)addItemViewController:(LoginViewController *)controller didFinishEnteringCookie:(NSString *)cookie UserName:(NSString *)userName
{
    self.logged_in = @1;
    self.cookie = cookie;
    self.userName = userName;
    [self.tableView reloadData];
    NSLog(@"Login View Controller Delegate Method");
}

@end
