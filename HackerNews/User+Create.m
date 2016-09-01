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
    User *user = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", userId];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        user = [matches firstObject];
    } else {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                 inManagedObjectContext:context];
        
        NSDictionary *userDictionary = [self fetchUserInfoWithUserId:userId];
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        
        user.unique = [f numberFromString:userId];
        user.about = [userDictionary valueForKey:HN_USER_ABOUT];
        user.created = [f numberFromString:[userDictionary valueForKey:HN_USER_CREATED]];
        user.delay = [f numberFromString:[userDictionary valueForKey:HN_USER_DELAY] ];
        user.karma = [f numberFromString:[userDictionary valueForKey:HN_USER_KARMA] ];
    }
    
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
    if(propertyListResults == nil)
    {
        NSLog(@"Error in Parsing User Details with userName:%@ - %@", userId, error);
        return nil;
    }
    return propertyListResults;
}

@end
