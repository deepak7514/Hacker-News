//
//  Stories+CoreDataProperties.h
//  HackerNews
//
//  Created by deepak.go on 22/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Stories.h"

NS_ASSUME_NONNULL_BEGIN

@interface Stories (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) id value;

@end

NS_ASSUME_NONNULL_END
