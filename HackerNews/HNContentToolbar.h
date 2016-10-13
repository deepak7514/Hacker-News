//
//  HNContentToolbar.h
//  HackerNews
//
//  Created by deepak.go on 12/10/16.
//  Copyright © 2016 deepak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HNContentToolbar : UIToolbar

- (instancetype)initWithNewsItemId:(NSNumber *)newsitemId itemURL: (NSString *)newsItemURL;

- (void)updateToolBarWithAuthToken:(NSString *)authToken
                         hmacToken:(NSString *)hmacToken
           andNewsItemMarkedHidden:(BOOL)hidden
                         favourite:(BOOL)liked
                             voted:(BOOL)voted;

@end
