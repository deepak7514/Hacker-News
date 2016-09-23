//
//  Stories+Create.m
//  HackerNews
//
//  Created by deepak.go on 21/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "Stories+Create.h"
#import "AppDelegate.h"

@implementation Stories (Create)

+ (void)updateStoriesWithStoryType:(NSString *)storyType stories:(NSArray *)data
{
    NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
    
    [backgroundQueue addOperationWithBlock:^{
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *secondaryContext = appDelegate.secondaryMOC;
        
        [secondaryContext performBlock:^{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Stories"];
            request.predicate = [NSPredicate predicateWithFormat:@"name = %@", storyType];
            
            NSError *error = nil;
            NSArray *matches = [secondaryContext executeFetchRequest:request error:&error];
            Stories *story = nil;
            
            if (!matches) {
                NSLog(@"Match is nil for Story - %@", storyType);
            } else if (error) {
                // handle error
                NSLog(@"Error in Fetching -%@ from Core data - %@", storyType, error);
            } else if ([matches count] > 1) {
                // Multiple Items already present
                NSLog(@"Multiple Stories for type - %@ present", storyType);
            } else if ([matches count]) {
                // Item already present
                story = [matches firstObject];
                story.name = storyType;
                story.value = data;
                NSLog(@"%@Story already present", storyType);
            } else {
                NSLog(@"Creating Story - %@", storyType);
                story = [NSEntityDescription insertNewObjectForEntityForName:@"Stories"
                                                               inManagedObjectContext:secondaryContext];
                story.name = storyType;
                story.value = data;
            }
            
            if ([secondaryContext hasChanges] && ![secondaryContext save:&error]) {
                
                NSLog(@"Stories Unresolved error %@", error);
                
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
            
        }];
    }];
}

+ (NSArray *)storiesWithStoryType:(NSString *)storyType
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Stories"];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@", storyType];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    NSArray *result = nil;
    
    if (!matches) {
        NSLog(@"Match is nil for Story - %@", storyType);
    } else if (error) {
        // handle error
        NSLog(@"Error in Fetching -%@ from Core data - %@", storyType, error);
    } else if ([matches count]) {
        // Item already present
        Stories *story = [matches firstObject];
        result = story.value;
    }
    return result;
}

@end
