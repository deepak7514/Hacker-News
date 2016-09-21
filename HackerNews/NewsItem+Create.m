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
        [secondaryContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        for (NSString *newsItem in newsItems) {
            [backgroundQueue addOperationWithBlock:^{
                [self createNewsItemWithId:newsItem inManagedObjectContext:secondaryContext];
            }];
        }
    }];
}

+ (void)createNewsItemWithId:(NSString *)newsItemId inManagedObjectContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", newsItemId];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches) {
            NSLog(@"Match is nil for NewsItem - %@", newsItemId);
        } else if (error) {
            // handle error
            NSLog(@"Error in fetching NewsItem -%@ from Core data - %@", newsItemId, error);
        } else if ([matches count] > 1) {
            // Multiple Items already present
            NSLog(@"Multiple NewsItems - %@ present", newsItemId);
        } else if ([matches count]) {
            // Item already present
            //NSLog(@"NewsItem - %@ already present", newsItemId);
        } else {
            //NSLog(@"Creating NewsItem - %@", newsItemId);
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[HNFetcher URLforItem:newsItemId]];
            
//            NSURLResponse *response = nil;
//            NSError *error = nil;
//            NSData *data = [NSURLConnection sendSynchronousRequest:request
//                                                 returningResponse:&response
//                                                             error:&error];
//            if(error){NSLog(@"Error Fetching NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], error);}
//            NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//            if(error){NSLog(@"Error Parsing NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], error);}
//            // Create NewsItem
//            if(jsonArray)
//            {
//                [self createNewsItemWithNewsItemInfo:jsonArray inManagedObjectContext:context];
//            } else {
//                NSLog(@"Error - empty propertyLists for NewsItem - %@ - %@", newsItemId, jsonArray);
//            }
            
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
                                                          if(err){NSLog(@"Error Fetching NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);}
                                                          NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
                                                          if(err){NSLog(@"Error Parsing NewsItem-%@ error-%@",[HNFetcher URLforItem:newsItemId], err);}
                                                          // Create NewsItem
                                                          if(jsonArray)
                                                          {
                                                              [self createNewsItemWithNewsItemInfo:jsonArray inManagedObjectContext:context];
                                                          } else {
                                                              NSLog(@"Error - empty propertyLists for NewsItem - %@ - %@", newsItemId, jsonArray);
                                                          }
                                                      }
                                                  } else
                                                  {
                                                      NSLog(@"NewsItem Fetch Task failed : %@", error);
                                                  }
                                              }];
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
            
        }
    }];
}

+ (void)createNewsItemWithNewsItemInfo:(NSDictionary *)newsItemDictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"NewsItem"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        if (!matches) {
            NSLog(@"Match is nil for NewsItem - %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]);
        } else if (error) {
            // handle error
            NSLog(@"Error in fetching NewsItem -%@ from Core data - %@", [newsItemDictionary objectForKey:HN_NEWSITEM_ID], error);
        } else if ([matches count] > 1) {
            // Multiple Items already present
            NSLog(@"Multiple NewsItems - %@ present", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]);
        } else if ([matches count]) {
            // Item already present
            //NSLog(@"NewsItem - %@ already present", [newsItemDictionary objectForKey:HN_NEWSITEM_ID]);
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
            
            //newsItem.by = [User userWithUserId:[newsItemDictionary valueForKey:HN_NEWSITEM_BY] inManagedObjectContext:context];
            //    NSArray *kidsForNewsItem = [newsItemDictionary valueForKey:HN_NEWSITEM_KIDS];
            //    for (NSString *kid in kidsForNewsItem) {
            //        [newsItem addKidsObject:[self newsItemWithNewsItemId:kid inManagedObjectContext:context]];
            //    }
            
            NSError *error = nil;
            if ([context hasChanges] && ![context save:&error]) {
                
                NSLog(@"NewsItem Unresolved error %@", error);
                
                NSArray * conflictListArray = (NSArray*)[[error userInfo] objectForKey:@"conflictList"];
                //NSLog(@"conflict array: %@",conflictListArray);
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
        }
    }];
}

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array
{
    id objectInstance;
    NSUInteger indexKey = 0;
    
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    for (objectInstance in array)
        [mutableDictionary setObject:objectInstance forKey:[NSNumber numberWithUnsignedInt:indexKey++]];
    
    return (NSDictionary *)mutableDictionary;
}

@end
