//
//  CRTableViewController.m
//  CRMultiRowSelector
//
//  Created by JLab13 on 3/01/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "ConnectionTypesController.h"
#import "CRTableViewCell.h"

#import "NSObject+CDHelper.h"
#import "EntityName.h"

@interface ConnectionTypesController()

@property (nonatomic, strong) NSMutableArray *selectedMarks;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation ConnectionTypesController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Connections", nil);
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    NSFetchRequest *fr =[self fetchRequestWithEntityName:ENConnectionTypes];
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    
    [fr setSortDescriptors:@[sd]];
    self.dataSource = [self executeFetchRequest:fr];
    self.selectedMarks = [NSMutableArray new];
    
    if (self.connectionTypeIds.length) {
        NSArray *ids = [self.connectionTypeIds componentsSeparatedByString:@","];
        for (NSString *itemId in ids) {
            for (ConnectionTypes *ct in self.dataSource) {
                if ([ct.id intValue] != [itemId intValue]) continue;
                [self.selectedMarks addObject:ct];
            }
        }
    }
}

#pragma mark - Methods
- (void)done:(id)sender {
    NSMutableString *result = [NSMutableString string];
    for (ConnectionTypes *ct in self.selectedMarks) {
        [result appendFormat:@"%@,", ct.id];
    }
    if (result.length) [result deleteCharactersInRange:NSMakeRange(result.length-1, 1)];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.action withObject:result.length ? result : nil];
    #pragma clang diagnostic pop
    
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableView Data Source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CRTableViewCellIdentifier = @"cellIdentifier";
    
    // init the CRTableViewCell
    CRTableViewCell *cell = (CRTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CRTableViewCellIdentifier];
    
    if (cell == nil) {
        cell = [[CRTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CRTableViewCellIdentifier];
    }
    
    // Check if the cell is currently selected (marked)
    ConnectionTypes *item = [self.dataSource objectAtIndex:[indexPath row]];
    cell.isSelected = [self.selectedMarks containsObject:item] ? YES : NO;
    cell.textLabel.text = item.title;
    
    return cell;
}

#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ConnectionTypes *item = [self.dataSource objectAtIndex:[indexPath row]];
    
    if ([self.selectedMarks containsObject:item])// Is selected?
        [self.selectedMarks removeObject:item];
    else
        [self.selectedMarks addObject:item];
    
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
