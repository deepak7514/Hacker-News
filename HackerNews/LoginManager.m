//
//  LoginManager.m
//  HackerNews
//
//  Created by deepak.go on 10/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import "LoginManager.h"
#import "NetworkManager.h"

@implementation LoginManager

+ (LoginManager*)sharedInstance
{
    static LoginManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[LoginManager alloc] init];
        
    });
    return _sharedInstance;
}

- (BOOL)checkSessionCookies
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookies) {
        if([[cookie name] isEqualToString:@"user"]) {
            self.cookieToken = [NSString stringWithFormat:@"%@=%@;", [cookie name], [cookie value]];
            self.userName = [[[cookie value] componentsSeparatedByString:@"&"] objectAtIndex:0];
            return YES;
        }
    }
    return NO;
}

- (BOOL)loggedIn
{
    if (_loggedIn || [self checkSessionCookies]){
        return YES;
    } else {
        return NO;
    }
}

- (void)loginWithUsername: (NSString *)userName
                 password: (NSString *)password
      andExecuteOnSuccess:(void(^)())successBlock
                  onError: (void(^)(NSError *error))errorBlock
{
    [NetworkManager makeHTMLRequestWithMethod:@"POST"
                                    URLString:@"https://news.ycombinator.com/login"
                                       params:@{@"acct":userName,
                                                @"pw":password
                                                }
                                       cookie: nil
                     andExecuteBlockOnSuccess:^(id responseObject, NSURLResponse *response) {
                         NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
                         NSLog(@"cookies - %@", cookies);
                         BOOL loggedIn = NO;
                         NSString *token;
                         for (NSHTTPCookie *cookie in cookies) {
                             if([[cookie name] isEqualToString:@"user"]) {
                                 loggedIn = YES;
                                 token = [NSString stringWithFormat:@"%@=%@;", [cookie name], [cookie value]];
                                 break;
                             }
                         }
                         dispatch_async(dispatch_get_main_queue(), ^{
                             if(loggedIn) {
                                 self.loggedIn = YES;
                                 self.cookieToken = token;
                                 self.userName = userName;
                                 if(successBlock){successBlock();}
                             } else {
                                 self.loggedIn = NO;
                                 if(errorBlock){errorBlock([NSError errorWithDomain:@"" code:-57 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid Combination of userName and password.", nil)}]);}
                             }
                         });
                     }
                                    onFailure:^(NSError *error) {
                                        if(errorBlock){errorBlock(error);}
                                    }];
}

- (void)signOut
{
    self.loggedIn = NO;
    self.cookieToken = nil;
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSHTTPCookie *cookieToDelete = nil;
    for (NSHTTPCookie *cookie in cookies) {
        if ([[cookie name] isEqualToString:@"user"]){
            cookieToDelete = cookie;
        }
    }
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookieToDelete];
}

@end
