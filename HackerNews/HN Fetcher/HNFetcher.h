//
//  HNFetcher.h
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//

#import <Foundation/Foundation.h>

// keys (paths) to values in a NEWSITEM dictionary
#define HN_NEWSITEM_ID @"id"
#define HN_NEWSITEM_DELETED @"deleted"
#define HN_NEWSITEM_TYPE @"type"
#define HN_NEWSITEM_BY @"by"
#define HN_NEWSITEM_TIME @"time" // in unix time
#define HN_NEWSITEM_TEXT @"text"
#define HN_NEWSITEM_DEAD @"dead"
#define HN_NEWSITEM_PARENT @"parent"
#define HN_NEWSITEM_KIDS @"kids"
#define HN_NEWSITEM_URL @"url"
#define HN_NEWSITEM_SCORE @"score"
#define HN_NEWSITEM_TITLE @"title"
#define HN_NEWSITEM_DESCENDANTS @"descendants"

// keys (paths) to values in a USER dictionary
#define HN_USER_ID @"id"
#define HN_USER_KARMA @"karma"
#define HN_USER_DELAY @"delay"
#define HN_USER_CREATED @"created"
#define HN_USER_ABOUT @"about"
#define HN_USER_SUBMITTED @"submitted"

@interface HNFetcher : NSObject

+ (NSURL *)URLforComments:(NSString *)itemId;

+ (NSURL *)URLforNewsItem:(NSString *)newsItem;

+ (NSURL *)URLforItem:(NSString *)itemId;

+ (NSURL *)URLforUser:(NSString *)userId;

@end
