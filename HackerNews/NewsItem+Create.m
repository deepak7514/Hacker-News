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

+ (void)loadNewsItemsFromArray:(NSArray *)newsItems
{
    NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
    
    [backgroundQueue addOperationWithBlock:^{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *secondaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        secondaryContext.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator;
        
        for (NSString *newsItem in newsItems) {
            [backgroundQueue addOperationWithBlock:^{
                [self createNewsItemWithId:newsItem inManagedObjectContext:secondaryContext];
            }];
        }
    }];
}

+ (void)createNewsItemWithId:(NSString *)newsItemId inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", newsItemId];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count]) {
        // handle error or Item obtained
    } else {
    
        NSURLRequest *request = [NSURLRequest requestWithURL:[HNFetcher URLforItem:newsItemId]];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask *task = [session
                                          downloadTaskWithRequest:request
                                          completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error)
                                          {
                                              if (!error)
                                              {
                                                  if ([request.URL isEqual:[HNFetcher URLforItem:newsItemId]])
                                                  {
                                                      NSError *err = nil;
                                                      NSData *jsonData = [NSData dataWithContentsOfURL:localfile options:0 error:&err];
                                                      if(error){NSLog(@"Error Fetching NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);}
                                                      NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
                                                      if(error){NSLog(@"Error Parsing NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);}
                                                      // Create NewsItem
                                                      [self createNewsItemWithNewsItemInfo:jsonArray inManagedObjectContext:context];
                                                  }
                                              } else
                                              {
                                                  NSLog(@"NewsItem Fetch Task failed : %@", error);
                                              }
                                          }];
        [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        
    }
    
//    NSError *error = nil;
//    // fetch the JSON data from HackerNews
//    NSData *jsonResults = [NSData dataWithContentsOfURL:[HNFetcher URLforItem:newsItemId] options:0 error:&error];
//    if(error)
//    {
//        NSLog(@"Error in Fetching NewsItem Details with newsItemId:%@ - %@", newsItemId, error);
//        return nil;
//    }
//    // convert it to a Property List (NSArray and NSDictionary)
//    NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults options:0 error:&error];
//    if(propertyListResults == nil)
//    {
//        NSLog(@"Error in Parsing NewsItem Details with newsItemId:%@ - %@", newsItemId, error);
//        return nil;
//    }
//    return propertyListResults;
}

+ (void)createNewsItemWithNewsItemInfo:(NSDictionary *)newsItemDictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
        
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
        
        newsItem.by = [User userWithUserId:[newsItemDictionary valueForKey:HN_NEWSITEM_BY] inManagedObjectContext:context];
        //    NSArray *kidsForNewsItem = [newsItemDictionary valueForKey:HN_NEWSITEM_KIDS];
        //    for (NSString *kid in kidsForNewsItem) {
        //        [newsItem addKidsObject:[self newsItemWithNewsItemId:kid inManagedObjectContext:context]];
        //    }
        
        NSError *error = nil;
        if ([context hasChanges] && ![context save:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            
            NSArray * conflictListArray = (NSArray*)[[error userInfo] objectForKey:@"conflictList"];
            NSLog(@"conflict array: %@",conflictListArray);
            NSError * conflictFixError = nil;
            
            if ([conflictListArray count] > 0) {
                
                NSMergePolicy *mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSOverwriteMergePolicyType];
                
                if (![mergePolicy resolveConflicts:conflictListArray error:&conflictFixError]) {
                    NSLog(@"Unresolved conflict error %@, %@", conflictFixError, [conflictFixError userInfo]);
                    NSLog(@"abort");
                    abort();
                }
            }
        }
    }];
}

@end
