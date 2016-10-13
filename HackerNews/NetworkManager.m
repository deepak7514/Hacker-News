//
//  NetworkManager.m
//  HackerNews
//
//  Created by deepak.go on 12/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "NetworkManager.h"
#include <AFNetworking/AFNetworking.h>

@implementation NetworkManager

+ (void)makeDataRequestWithMethod: (NSString *)method
                              URLString: (NSString *)URLString
                           params: (NSDictionary *)params
                           cookie: (NSString *)cookieToken
         andExecuteBlockOnSuccess: (void(^)(id responseObject, NSURLResponse *response))successBlock
                        onFailure: (void(^)(NSError *error))errorBlock
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:method URLString:URLString parameters:params error:nil];
    [request setValue:cookieToken forHTTPHeaderField:@"cookie"];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error making %@ request-%@ error-%@",method, request, error);
            if(errorBlock){errorBlock(error);}
        } else {
            if(successBlock){successBlock(responseObject, response);}
        }
    }];
    [dataTask resume];
}

+ (void)makeHTMLRequestWithMethod: (NSString *)method
                        URLString: (NSString *)URLString
                           params: (NSDictionary *)params
                           cookie: (NSString *)cookieToken
         andExecuteBlockOnSuccess: (void(^)(id responseObject, NSURLResponse *response))successBlock
                        onFailure: (void(^)(NSError *error))errorBlock
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:method URLString:URLString parameters:params error:nil];
    [request setValue:cookieToken forHTTPHeaderField:@"cookie"];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error making %@ request-%@ error-%@",method, request, error);
            if(errorBlock){errorBlock(error);}
        } else {
            if(successBlock){successBlock(responseObject, response);}
        }
    }];
    [dataTask resume];
}

@end
