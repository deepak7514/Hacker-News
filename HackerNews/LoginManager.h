//
//  LoginManager.h
//  HackerNews
//
//  Created by deepak.go on 10/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginManager : NSObject

@property (nonatomic) BOOL loggedIn;
@property (nonatomic) NSString *cookieToken;
@property (nonatomic) NSString *userName;

+ (LoginManager*)sharedInstance;
- (void)loginWithUsername: (NSString *)userName
                 password: (NSString *)password
      andExecuteOnSuccess:(void(^)())successBlock
                  onError: (void(^)(NSError *error))errorBlock;
- (void)signOut;

@end
