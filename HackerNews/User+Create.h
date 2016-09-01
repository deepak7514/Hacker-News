//
//  User+Create.h
//  HackerNews
//
//  Created by deepak.go on 29/08/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "User.h"

@interface User (Create)

+ (User *)userWithUserId:(NSString *)userId
    inManagedObjectContext:(NSManagedObjectContext *)context;

@end
