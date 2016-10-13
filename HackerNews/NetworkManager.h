//
//  NetworkManager.h
//  HackerNews
//
//  Created by deepak.go on 12/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

+ (void)makeDataRequestWithMethod: (NSString *)method
                              URLString: (NSString *)URLString
                           params: (NSDictionary *)params
                           cookie: (NSString *)cookieToken
         andExecuteBlockOnSuccess: (void(^)(id responseObject, NSURLResponse *response))successBlock
                        onFailure: (void(^)(NSError *error))errorBlock;

+ (void)makeHTMLRequestWithMethod: (NSString *)method
                        URLString: (NSString *)URLString
                           params: (NSDictionary *)params
                           cookie: (NSString *)cookieToken
         andExecuteBlockOnSuccess: (void(^)(id responseObject, NSURLResponse *response))successBlock
                        onFailure: (void(^)(NSError *error))errorBlock;

@end
