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
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
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

-(void) update
{
}


@end
