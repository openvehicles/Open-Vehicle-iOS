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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

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
    [super viewWillAppear:animated];
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
    
    [[ovmsAppDelegate myRef] registerForUpdate:self];
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
    else
    {
        return YES;
    }
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

 - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
 {
 return 2;
 }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NOCChatCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Telegram";
        cell.imageView.image = [UIImage imageNamed:@"TGIcon"];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"WeChat";
        cell.imageView.image = [UIImage imageNamed:@"MMIcon"];
    }
    return cell;
}

-(void) update
{
}

#pragma mark - OvmsChatInputTextPanelDelegate

- (void)inputTextPanel:(OvmsChatInputTextPanel *)inputTextPanel requestSendText:(NSString *)text
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
    NSMutableArray *layouts = [[NSMutableArray alloc] init];

    OvmsMessage *message = [OvmsMessage alloc];
    message.text = text;
    message.senderId = 0;
    message.outgoing = YES;
    message.date = [NSDate date];
    message.deliveryStatus = OvmsMessageDeliveryStatusDelivered;
    id<NOCChatItemCellLayout> layout = [self createLayoutWithItem:message];
    [layouts insertObject:layout atIndex:0];
    [self insertLayouts:layouts atIndexes:indexes animated:true];
    [self scrollToBottomAnimated:true];
}

@end
