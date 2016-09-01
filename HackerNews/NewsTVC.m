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

@interface NewsTVC ()

@end

@implementation NewsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
  
    if([segue.destinationViewController isKindOfClass:[NewsItemTVC class]])
    {
        NewsItemTVC *dest = (NewsItemTVC *)segue.destinationViewController;
        dest.storyTypeURL = [HNFetcher URLforNewsItem:segue.identifier];
        dest.title = [NSString stringWithFormat:@"%@ Stories", [[NSString stringWithFormat:@"%@",segue.identifier] capitalizedString]];
    }
}

@end
