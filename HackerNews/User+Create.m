//
//  User+Create.m
//  HackerNews
//
//  Created by deepak.go on 29/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "User+Create.h"
#import "HNFetcher.h"

@implementation User (Create)

+ (User *)userWithUserId:(NSString *)userId
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    __block User *user = nil;
    
    [context performBlock:^{
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", userId];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches) {
            NSLog(@"Match is nil for User - %@", userId);
        } else if (error) {
            // handle error
            NSLog(@"Error in fetching User -%@ from Core data - %@", userId, error);
        } else if([matches count] > 1) {
            // handle error
            NSLog(@"Multiple Users found for UserId - %@", userId);
        } else if ([matches count]) {
            //NSLog(@"User - %@ already present", userId);
            user = [matches firstObject];
        } else {
            //NSLog(@"Creating User - %@", userId);
            NSDictionary *userDictionary = [self fetchUserInfoWithUserId:userId];
            if(userDictionary){
                user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                         inManagedObjectContext:context];
                
                user.unique = [userDictionary valueForKey:HN_USER_ID];
                user.about = [userDictionary valueForKey:HN_USER_ABOUT];
                user.created = [userDictionary valueForKey:HN_USER_CREATED];
                user.delay = [userDictionary valueForKey:HN_USER_DELAY];
                user.karma = [userDictionary valueForKey:HN_USER_KARMA];
                
            } else {
                NSLog(@"Empty PropertyLists for User - %@", userId);
            }
        }
    }];
    
    return user;
}

+ (NSDictionary *)fetchUserInfoWithUserId:(NSString *)userId
{
    NSError *error = nil;
    // fetch the JSON data from HackerNews
    NSData *jsonResults = [NSData dataWithContentsOfURL:[HNFetcher URLforUser:userId] options:0 error:&error];
    if(error)
    {
        NSLog(@"Error in Fetching User Details with userName:%@ - %@", userId, error);
        return nil;
    }
    // convert it to a Property List (NSArray and NSDictionary)
    NSDictionary *propertyListResults = [NSJSONSerialization JSONObjectWithData:jsonResults options:0 error:&error];
    if(error)
    {
        NSLog(@"Error in Parsing User Details with userName:%@ - %@", userId, error);
        return nil;
    }
    return propertyListResults;
}

@end
