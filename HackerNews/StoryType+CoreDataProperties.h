//
//  StoryType+CoreDataProperties.h
//  HackerNews
//
//  Created by deepak.go on 04/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StoryType.h"

NS_ASSUME_NONNULL_BEGIN

@interface StoryType (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *index;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSNumber *unique;
@property (nullable, nonatomic, retain) NewsItem *newsItem;

@end

NS_ASSUME_NONNULL_END
