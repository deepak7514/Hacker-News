//
//  NewsItemTVC.h
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsItemTVC : UITableViewController

// Model of this MVC (it can be publicly set)
@property (nonatomic, strong) NSArray *newsItems; // of News Items
@property (nonatomic, strong) NSURL *storyTypeURL; // passed by segue of corresponding type

@end
