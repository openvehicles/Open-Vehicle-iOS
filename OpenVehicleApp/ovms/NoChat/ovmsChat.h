//
//  ovmsChat.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsChat_h
#define ovmsChat_h

#import <Foundation/Foundation.h>

@interface OvmsChat : NSObject

@property (nonatomic, strong) NSString *chatId;
@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) NSString *targetId;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *detail;

@end

#endif /* ovmsChat_h */
