//
//  OCMInformationController.m
//  Open Vehicle
//
//  Created by JLab13 on 3/7/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import "OCMInformationController.h"
#import "NSObject+CDHelper.h"
#import "EntityName.h"
#import "ovmsAppDelegate.h"

@interface OCMInformationController ()

@property (nonatomic, strong) NSArray *keys;
@property (nonatomic, strong) NSArray *values;

@property (nonatomic, strong) NSArray *cokeys;
@property (nonatomic, strong) NSArray *covalues;

@end

@implementation OCMInformationController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Information", nil);
    
    
    ChargingLocation *cl = [self entityWithName:ENChargingLocation
                                        asWhere:@"uuid"
                                        inValue:self.locationUUID];

    if (cl) {
        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *values = [NSMutableArray array];
        NSMutableArray *cokeys = [NSMutableArray array];
        NSMutableArray *covalues = [NSMutableArray array];
        
        if (cl.operator_info.title) {
            [keys addObject:NSLocalizedString(@"Operator name", nil)];
            [values addObject:cl.operator_info.title];
        }
        
        if (cl.number_of_points) {
            [keys addObject:NSLocalizedString(@"Number of points", nil)];
            [values addObject:[cl.number_of_points description]];
        }
        
        if (cl.usage) {
            [keys addObject:NSLocalizedString(@"Usage", nil)];
            [values addObject:cl.usage];
        }
        
        if (cl.status_title) {
            [keys addObject:NSLocalizedString(@"Operation Status", nil)];
            [values addObject:cl.status_title];
        }
        
        if (cl.addres_info) {
            [keys addObject:NSLocalizedString(@"Address", nil)];
            [values addObject:[NSString stringWithFormat:@"%@, %@", cl.addres_info.address_line1, cl.addres_info.title]];
        }
        
        NSUInteger num = 0;
        BOOL isOneConnection = cl.conections.count == 1;
        for (Connection *cn in cl.conections) {
            num++;
            if (cn.level) {
                NSString *key = isOneConnection ? NSLocalizedString(@"Level", nil) : [NSString stringWithFormat:NSLocalizedString(@"Level #%d", nil), num];
                [cokeys addObject:key];
                [covalues addObject:cn.level.title];
            }
            
            if (cn.amps) {
                NSString *key = isOneConnection ? NSLocalizedString(@"Amps", nil) : [NSString stringWithFormat:NSLocalizedString(@"Amps #%d", nil), num];
                [cokeys addObject:key];
                [covalues addObject:[cn.amps description]];
            }
            
            if (cn.connection_type) {
                NSString *key = isOneConnection ? NSLocalizedString(@"Connection type", nil) : [NSString stringWithFormat:NSLocalizedString(@"Connection type #%d", nil), num];
                [cokeys addObject:key];
                [covalues addObject:cn.connection_type.title];
            }
            
        }
        self.cokeys = cokeys;
        self.covalues = covalues;
        
        self.keys = keys;
        self.values = values;
    }
}

#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return NSLocalizedString(@"Charging Station", nil) ;
        case 2:
            return NSLocalizedString(@"Connections", nil) ;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.cokeys.count ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return self.keys.count;
        case 2:
            return self.cokeys.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kDataCellIdentifier = @"dataCell";
    static NSString *kBtnCellIdentifier = @"btnCell";
    
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:kBtnCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kBtnCellIdentifier];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        cell.textLabel.text = NSLocalizedString(@"Route to Charging Station", nil);
        return cell;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kDataCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kBtnCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [cell.textLabel.font fontWithSize:14];
        }
        
        if (indexPath.section == 1) {
            cell.textLabel.text = self.keys[indexPath.row];
            cell.detailTextLabel.text = self.values[indexPath.row];
        } else {
            cell.textLabel.text = self.cokeys[indexPath.row];
            cell.detailTextLabel.text = self.covalues[indexPath.row];
        }
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section) return;
    
    [ovmsAppDelegate routeFrom:self.from To:self.to];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
