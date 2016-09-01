//
//  NewsItem+Create.m
//  HackerNews
//
//  Created by deepak.go on 29/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NewsItem+Create.h"
#import "HNFetcher.h"
#import "User+Create.h"

@implementation NewsItem (Create)

+ (NewsItem *)newsItemWithNewsItemId:(NSString *)newsItemId
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    NewsItem *newsItem = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", newsItemId];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        newsItem = [matches firstObject];
    } else {
        newsItem = [NSEntityDescription insertNewObjectForEntityForName:@"NewsItem"
                                              inManagedObjectContext:context];
        
        NSDictionary *newsItemDictionary = [self fetchNewsItemInfoWithNewsItemId:newsItemId];
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        newsItem.unique = [f numberFromString:newsItemId];
        newsItem.title = [newsItemDictionary valueForKey:HN_NEWSITEM_TITLE];
        newsItem.dead = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DEAD] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        newsItem.deleted = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DELETED] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        newsItem.descendants = [f numberFromString:[newsItemDictionary valueForKey:HN_NEWSITEM_DESCENDANTS]];
        newsItem.score = [f numberFromString:[newsItemDictionary valueForKey:HN_NEWSITEM_SCORE]];
        newsItem.text = [newsItemDictionary valueForKey:HN_NEWSITEM_TEXT];
        newsItem.time = [f numberFromString:[newsItemDictionary valueForKey:HN_NEWSITEM_TIME]];
        newsItem.type = [newsItemDictionary valueForKey:HN_NEWSITEM_TYPE];
        newsItem.url = [newsItemDictionary valueForKey:HN_NEWSITEM_URL];
        
        newsItem.by = [User userWithUserId:[newsItemDictionary valueForKey:HN_NEWSITEM_BY] inManagedObjectContext:context];
        
        NSArray *kidsForNewsItem = [newsItemDictionary valueForKey:HN_NEWSITEM_KIDS];
        for (NSString *kid in kidsForNewsItem) {
            [newsItem addKidsObject:[self newsItemWithNewsItemId:kid inManagedObjectContext:context]];
        }
    }
    
    return newsItem;
}

+ (void)loadNewsItemsFromArray:(NSArray *)newsItems // of NewsItem NSString
      intoManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSString *newsItem in newsItems) {
        [self newsItemWithNewsItemId:newsItem inManagedObjectContext:context];
    }
}

+ (NSDictionary *)fetchNewsItemInfoWithNewsItemId:(NSString *)newsItemId
{
    NSError *error = nil;
    // fetch the JSON data from HackerNews
    NSData *jsonResults = [NSData dataWithContentsOfURL:[HNFetcher URLforItem:newsItemId] options:0 error:&error];
    if(error)
    {
        NSLog(@"Error in Fetching NewsItem Details with userName:%@ - %@", newsItemId, error);
        return nil;
    }
    // convert it to a Property List (NSArray and NSDictionary)
    NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults options:0 error:&error];
    if(propertyListResults == nil)
    {
        NSLog(@"Error in Parsing NewsItem Details with userName:%@ - %@", newsItemId, error);
        return nil;
    }
    return propertyListResults;
}

@end
