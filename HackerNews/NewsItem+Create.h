//
//  NewsItem+Create.h
//  HackerNews
//
//  Created by deepak.go on 29/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItem.h"

@interface NewsItem (Create)

+ (NewsItem *)newsItemWithNewsItemId:(NSString *)newsItemid
        inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)loadNewsItemsFromArray:(NSArray *)newsItems; // of NewsItem NSDictionary

@end
