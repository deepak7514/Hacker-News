//
//  StoryType+Create.h
//  HackerNews
//
//  Created by deepak.go on 22/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "StoryType.h"

@interface StoryType (Create)

+ (void)storyTypeWithIndex:(NSNumber *)index
                        storyType:(NSString *)type
                           unique:(NSNumber *)unique
                         newsItem: (NewsItem *)newsitem
           inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)newsItemsForStoryType:(NSString *)type inManagedObjectContext:(NSManagedObjectContext *)context;

@end
