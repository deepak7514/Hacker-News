//
//  FlickrFetcher.m
//
//  Created for Stanford CS193p Fall 2013.
//  Copyright 2013 Stanford University. All rights reserved.
//

#import "HNFetcher.h"

static NSString * const BaseURLString = @"https://hacker-news.firebaseio.com/v0";

@implementation HNFetcher

+ (NSURL *)URLforNewsItem:(NSString *)newsItem
{
    NSString *query = [NSString stringWithFormat:@"%@/%@stories.json", BaseURLString, newsItem];
    return [NSURL URLWithString:query];
}

+ (NSURL *)URLforItem:(NSString *)itemId
{
    NSString *query = [NSString stringWithFormat:@"%@/item/%@.json", BaseURLString, itemId];
    return [NSURL URLWithString:query];
}

+ (NSURL *)URLforUser:(NSString *)userId
{
    NSString *query = [NSString stringWithFormat:@"%@/user/%@.json", BaseURLString, userId];
    return [NSURL URLWithString:query];
}

+ (NSURL *)URLforComments:(NSString *)itemId
{
    NSString *query = [NSString stringWithFormat:@"http://hn.algolia.com/api/v1/items/%@", itemId];
    return [NSURL URLWithString:query];
}

@end
