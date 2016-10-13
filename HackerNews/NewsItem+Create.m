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
#import "StoryType+Create.h"
#import "AppDelegate.h"

@implementation NewsItem (Create)

+ (NewsItem *)newsItemWithNewsItemId:(NSString *)newsItemId
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSLog(@"NewsItem - %@", newsItemId);
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
        // create NewsItem
        //newsItem = [self createNewsItemWithId:newsItemId inManagedObjectContext:context];
    }
    
    return newsItem;
}

+ (void)loadNewsItemsFromArray:(NSArray *)newsItems storyType:(NSString *)type
{
    NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
    
    [backgroundQueue addOperationWithBlock:^{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *secondaryContext = appDelegate.secondaryMOC;
        
        NSInteger index = 0;
        for (NSString *newsItem in newsItems) {
            if (newsItem) {
                [backgroundQueue addOperationWithBlock:^{
                    [self createOrUpdateNewsItemWithId:newsItem index:index storyType:type inManagedObjectContext:secondaryContext];
                }];
            }
            index += 1;
        }
        NSLog(@"%@ stories, count- %ld", type, (long)index);
    }];
}

+ (void)createOrUpdateNewsItemWithId:(NSString *)newsItemId index:(NSInteger)index storyType:(NSString *)type inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[HNFetcher URLforItem:newsItemId]];
            
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task =
        [session downloadTaskWithRequest:request
                completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error)
                {
                    if (!error)
                    {
                        if ([request.URL isEqual:[HNFetcher URLforItem:newsItemId]])
                        {
                            NSError *err = nil;
                            NSData *jsonData = [NSData dataWithContentsOfURL:localfile options:0 error:&err];
                            if(err){
                                NSLog(@"Error Fetching NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);
                            }
                            NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
                            if(err){
                                NSLog(@"Error Parsing NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);
                            }
                            // Create NewsItem
                            if(jsonArray)
                            {
                                [self createOrUpdateNewsItemWithNewsItemInfo:jsonArray index:index storyType:type inManagedObjectContext:context];
                            } else {
                                NSLog(@"Error - empty propertyLists for NewsItem - %@ - %@", newsItemId, jsonArray);
                            }
                        }
                    } else {
                        NSLog(@"NewsItem Fetch Task failed : %@", error);
                    }
                }];
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
}

+ (void)createOrUpdateNewsItemWithNewsItemInfo:(NSDictionary *)newsItemDictionary index:(NSInteger)index storyType:(NSString *)type
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]];
        
        NSError *error = nil;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        if (!matches) {
            NSLog(@"Match is nil for NewsItem - %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]);
        } else if (error) {
            // handle error
            NSLog(@"Error in fetching NewsItem -%@ from Core data - %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID], error);
        } else if ([matches count]) {
            if ([matches count] > 1) {
                // Multiple Items already present
                NSLog(@"Multiple NewsItems - %@ present", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]);
            }
            NewsItem *newsItem = [matches firstObject];
            newsItem.dead = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DEAD] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
            newsItem.deleted = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DELETED] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
            newsItem.descendants = [newsItemDictionary valueForKey:HN_NEWSITEM_DESCENDANTS];
            newsItem.score = [newsItemDictionary valueForKey:HN_NEWSITEM_SCORE];
            newsItem.text = [newsItemDictionary valueForKey:HN_NEWSITEM_TEXT];
            
//            NSMutableArray *storyItems = [[NSMutableArray alloc] initWithCapacity:0];
//            for (StoryType *storyItem in newsItem.storyType) {
//                if([storyItem.type isEqualToString:type]) {
//                    [storyItems addObject:storyItem];
//                }
//            }
//            for (StoryType *item in storyItems) {
//                [newsItem removeStoryTypeObject:item];
//            }
            
            [StoryType storyTypeWithIndex:[NSNumber numberWithInteger:index] storyType:type unique:[newsItemDictionary objectForKey:HN_NEWSITEM_ID] newsItem:newsItem inManagedObjectContext:context];
            
        } else {
        
            NewsItem *newsItem = [NSEntityDescription insertNewObjectForEntityForName:@"NewsItem"
                                                               inManagedObjectContext:context];
            
            newsItem.unique = [newsItemDictionary valueForKey:HN_NEWSITEM_ID];
            newsItem.title = [newsItemDictionary valueForKey:HN_NEWSITEM_TITLE];
            newsItem.dead = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DEAD] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
            newsItem.deleted = ([[newsItemDictionary valueForKey:HN_NEWSITEM_DELETED] isEqual: @"true"]) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
            newsItem.descendants = [newsItemDictionary valueForKey:HN_NEWSITEM_DESCENDANTS];
            newsItem.score = [newsItemDictionary valueForKey:HN_NEWSITEM_SCORE];
            newsItem.text = [newsItemDictionary valueForKey:HN_NEWSITEM_TEXT];
            newsItem.time = [newsItemDictionary valueForKey:HN_NEWSITEM_TIME];
            newsItem.type = [newsItemDictionary valueForKey:HN_NEWSITEM_TYPE];
            newsItem.url = [newsItemDictionary valueForKey:HN_NEWSITEM_URL];
            newsItem.author = [newsItemDictionary valueForKey:HN_NEWSITEM_BY];
            
            [StoryType storyTypeWithIndex:[NSNumber numberWithInteger:index] storyType:type unique:[newsItemDictionary objectForKey:HN_NEWSITEM_ID] newsItem:newsItem inManagedObjectContext:context];
            
            //newsItem.by = [User userWithUserId:[newsItemDictionary valueForKey:HN_NEWSITEM_BY] inManagedObjectContext:context];
            //    NSArray *kidsForNewsItem = [newsItemDictionary valueForKey:HN_NEWSITEM_KIDS];
            //    for (NSString *kid in kidsForNewsItem) {
            //        [newsItem addKidsObject:[self newsItemWithNewsItemId:kid inManagedObjectContext:context]];
            //    }
            
        }

        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"NewsItem Unresolved error %@", error);
        }
    }];
}

@end
