//
//  User+CoreDataProperties.h
//  HackerNews
//
//  Created by deepak.go on 04/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *about;
@property (nullable, nonatomic, retain) NSNumber *created;
@property (nullable, nonatomic, retain) NSNumber *delay;
@property (nullable, nonatomic, retain) NSNumber *karma;
@property (nullable, nonatomic, retain) NSString *unique;
@property (nullable, nonatomic, retain) NSSet<NewsItem *> *submitted;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addSubmittedObject:(NewsItem *)value;
- (void)removeSubmittedObject:(NewsItem *)value;
- (void)addSubmitted:(NSSet<NewsItem *> *)values;
- (void)removeSubmitted:(NSSet<NewsItem *> *)values;

@end

NS_ASSUME_NONNULL_END
