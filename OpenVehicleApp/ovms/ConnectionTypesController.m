//
//  CRTableViewController.m
//  CRMultiRowSelector
//
//  Created by JLab13 on 3/01/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "ConnectionTypesController.h"
#import "ovmsAppDelegate.h"

#import "CRTableViewCell.h"

#import "NSObject+CDHelper.h"
#import "EntityName.h"

@interface ConnectionTypesController()

@property (nonatomic, strong) NSMutableArray *selectedMarks;
@property (nonatomic, strong) NSArray *dataSource;
@property (readonly, nonatomic) Cars *carEditing;

@end

@implementation ConnectionTypesController

@synthesize carEditing = _carEditing;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Connections", nil);
    self.view.backgroundColor = UIColorFromRGB(0x121b2f);
    
    
    NSFetchRequest *fr = [NSFetchRequest new];
    [fr setEntity:[NSEntityDescription entityForName:ENConnectionTypes
                              inManagedObjectContext:self.managedObjectContext]];

    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    
    [fr setSortDescriptors:@[sd]];
    self.dataSource = [self executeFetchRequest:fr];
    self.selectedMarks = [NSMutableArray new];
    
    NSString *connectionTypeIds = self.carEditing.connection_type_ids;
    
    if (connectionTypeIds.length) {
        NSArray *ids = [connectionTypeIds componentsSeparatedByString:@","];
        for (NSString *itemId in ids) {
            for (ConnectionTypes *ct in self.dataSource) {
                if ([ct.id intValue] != [itemId intValue]) continue;
                [self.selectedMarks addObject:ct];
            }
        }
    }
}

- (Cars*)carEditing {
    if (_carEditing) return _carEditing;
 
    NSManagedObjectContext *context = [ovmsAppDelegate myRef].managedObjectContext;
    NSFetchRequest *fr = [NSFetchRequest new];
    [fr setEntity:[NSEntityDescription entityForName:ENCars
                              inManagedObjectContext:context]];

    [fr setPredicate:[NSPredicate predicateWithFormat:@"vehicleid = %@", self.carEditingId]];
    NSArray *result = [self executeFetchRequest:fr];
    
    if (result.count) _carEditing = result[0];
    
    return _carEditing;
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
    
    
    NSMutableString *result = [NSMutableString string];
    for (ConnectionTypes *ct in self.selectedMarks) {
        [result appendFormat:@"%@,", ct.id];
    }
    if (result.length) [result deleteCharactersInRange:NSMakeRange(result.length-1, 1)];
    
    self.carEditing.connection_type_ids = result;
    
    ovmsAppDelegate *app = [ovmsAppDelegate myRef];
    [app saveContext];
    
    if ([app.sel_car isEqualToString:self.carEditingId]) {
        app.sel_connection_type_ids = self.carEditing.connection_type_ids;
    }
}

@end
