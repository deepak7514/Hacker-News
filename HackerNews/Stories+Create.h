//
//  Stories+Create.h
//  HackerNews
//
//  Created by deepak.go on 21/09/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "Stories.h"

@interface Stories (Create)

+ (void)updateStoriesWithStoryType:(NSString *)storyType stories:(NSArray *)data;

+ (NSArray *)storiesWithStoryType:(NSString *)storyType;

@end
