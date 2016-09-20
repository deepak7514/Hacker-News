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

@interface NewsTVC ()

@end

@implementation NewsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    navController.title = [NSString stringWithFormat:@"%@ Stories", [[NSString stringWithFormat:@"%@",segue.identifier] capitalizedString]];
    
    NewsItemTVC *dest = (NewsItemTVC *)[navController childViewControllers].firstObject;
    dest.storyType = segue.identifier;
    dest.title = [NSString stringWithFormat:@"%@ Stories", [[NSString stringWithFormat:@"%@",segue.identifier] capitalizedString]];
}

@end
