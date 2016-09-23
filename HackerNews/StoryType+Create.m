//
//  StoryType+Create.m
//  HackerNews
//
//  Created by deepak.go on 22/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "StoryType+Create.h"

@implementation StoryType (Create)

+ (StoryType *)storyTypeWithIndex:(NSNumber *)index storyType:(NSString *)type  unique:(NSNumber *)unique
  inManagedObjectContext:(NSManagedObjectContext *)context
{
    StoryType *storyType = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"StoryType"];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"index = %@", index];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"type = %@", type];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        NSLog(@"Match is nil for StoryType - %@", index);
    } else if (error) {
        // handle error
        NSLog(@"Error in fetching StoryType -%@ from Core data - %@", index, error);
    } else if([matches count] > 1) {
        // handle error
        NSLog(@"Multiple StoryType found for Index - %@", index);
    } else if ([matches count]) {
        //NSLog(@"StoryType - %@ already present", index);
        storyType = [matches firstObject];
        storyType.unique = unique;
    } else {
        //NSLog(@"Creating StoryType - %@", index);
        storyType = [NSEntityDescription insertNewObjectForEntityForName:@"StoryType"
                                                 inManagedObjectContext:context];
            
        storyType.index = index;
        storyType.type = type;
        storyType.unique = unique;
    }
    return storyType;
}

+ (NSArray *)newsItemsForStoryType:(NSString *)type inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"StoryType"];
    request.predicate = [NSPredicate predicateWithFormat:@"type = %@", type];
    request.resultType = NSDictionaryResultType;
    [request setPropertiesToFetch:@[@"unique"]];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index"
                                                              ascending:YES
                                                               selector:@selector(compare:)]];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    NSArray *newsItems = nil;
    
    if (!matches) {
        NSLog(@"Match is nil for StoryType - %@", type);
    } else if (error) {
        // handle error
        NSLog(@"Error in fetching StoryType -%@ from Core data - %@", type, error);
    } else if ([matches count]) {
        newsItems = [matches valueForKey:@"unique"];
    }
    return newsItems;
}


@end
