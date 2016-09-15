//
//  NewsItemTVC.h
//  HNews
//
//  Created by deepak.go on 26/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

@interface NewsItemTVC : CoreDataTableViewController

// Model of this MVC (it can be publicly set)
@property (nonatomic, strong) NSString *storyType; // passed by segue of corresponding type
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
