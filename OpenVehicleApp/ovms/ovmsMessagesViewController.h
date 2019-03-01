//
//  ovmsMessagesViewController.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsMessagesViewController_h
#define ovmsMessagesViewController_h

#import <UIKit/UIKit.h>
#import "ovmsAppDelegate.h"
#import "NoChat/NoChat.h"

@interface ovmsMessagesViewController : NOCChatViewController <UINavigationControllerDelegate, ovmsUpdateDelegate>

@end

#endif /* ovmsMessagesViewController_h */
