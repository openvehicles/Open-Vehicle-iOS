//
//  ovmsMessagesViewController.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ovmsMessagesViewController.h"
#import "NoChat/ovmsTextMessageCell.h"
#import "NoChat/ovmsTextMessageCellLayout.h"
#import "NoChat/ovmsMessageInputPanel.h"
#import "JHNotificationManager.h"

@implementation ovmsMessagesViewController

#pragma mark - View lifecycle

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
    self.navigationController.delegate = self;
    [self update];
}

- (void)dealloc
{
}

- (void)viewWillAppear:(BOOL)animated
{
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0.069420576095581055 green:0.10595327615737915 blue:0.19171994924545288 alpha:1.0];
    [super viewWillAppear:animated];
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
    
    [[ovmsAppDelegate myRef] registerForUpdate:self];
    [self loadMessages];
    [self update];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

+ (Class)cellLayoutClassForItemType:(NSString *)type
{
    return [OvmsTextMessageCellLayout class];
}

+ (Class)inputPanelClass
{
    return [OvmsChatInputTextPanel class];
}

- (void)registerChatItemCells
{
     [self.collectionView registerClass:[OvmsTextMessageCell class] forCellWithReuseIdentifier:[OvmsTextMessageCell reuseIdentifier]];
}

-(void) update
{
}

-(void) clearMessages
{
    [self.layouts removeAllObjects];
}

-(void) addMessage:(OvmsMessage*)message
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
    NSMutableArray *layouts = [[NSMutableArray alloc] init];
    id<NOCChatItemCellLayout> layout = [self createLayoutWithItem:message];
    [layouts insertObject:layout atIndex:0];
    [self insertLayouts:layouts atIndexes:indexes animated:true];
    [self scrollToBottomAnimated:true];
}

-(void) addMessages:(NSMutableArray*)messages animated:(BOOL)animated
{
    if ((messages!=nil)&&(messages.count > 0))
        {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, messages.count)];
        NSMutableArray *layouts = [[NSMutableArray alloc] init];
    
        [messages enumerateObjectsUsingBlock:^(OvmsMessage *message, NSUInteger idx, BOOL *stop) {
            id<NOCChatItemCellLayout> layout = [self createLayoutWithItem:message];
            [layouts insertObject:layout atIndex:0];
        }];
    
        [self insertLayouts:layouts atIndexes:indexes animated:animated];
        [self scrollToBottomAnimated:animated];
        }
    else
    {
        [self.collectionView reloadData];
    }
}

-(void) loadMessages
{
    [self.layouts removeAllObjects];
    [self addMessages:(NSMutableArray*)[ovmsAppDelegate myRef].sel_messages animated:NO];
}

#pragma mark - OvmsChatInputTextPanelDelegate

- (void)inputTextPanel:(OvmsChatInputTextPanel *)inputTextPanel requestSendText:(NSString *)text
{
    [[ovmsAppDelegate myRef] addMessage:text incoming:NO];
    [[ovmsAppDelegate myRef] commandDoCommand:text];
}

@end
