//
//  NewsItem+CoreDataProperties.h
//  HackerNews
//
//  Created by deepak.go on 22/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NewsItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NewsItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *author;
@property (nullable, nonatomic, retain) NSNumber *dead;
@property (nullable, nonatomic, retain) NSNumber *deleted;
@property (nullable, nonatomic, retain) NSNumber *descendants;
@property (nullable, nonatomic, retain) NSNumber *score;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSNumber *time;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSNumber *unique;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) User *by;
@property (nullable, nonatomic, retain) NSSet<NewsItem *> *kids;
@property (nullable, nonatomic, retain) NewsItem *parent;
@property (nullable, nonatomic, retain) StoryType *storyType;

@end

@interface NewsItem (CoreDataGeneratedAccessors)

- (void)addKidsObject:(NewsItem *)value;
- (void)removeKidsObject:(NewsItem *)value;
- (void)addKids:(NSSet<NewsItem *> *)values;
- (void)removeKids:(NSSet<NewsItem *> *)values;

@end

NS_ASSUME_NONNULL_END
