//
//  ChargingLocation.h
//  Open Vehicle
//
//  Created by JLab13 on 3/7/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AddressInfo, Connection, OperatorInfo;

@interface ChargingLocation : NSManagedObject

@property (nonatomic, retain) NSString * data_providers_reference;
@property (nonatomic, retain) NSNumber * data_quality_level;
@property (nonatomic, retain) NSString * general_comments;
@property (nonatomic, retain) NSNumber * number_of_points;
@property (nonatomic, retain) NSNumber * status_is_operational;
@property (nonatomic, retain) NSString * status_title;
@property (nonatomic, retain) NSString * usage;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * status_id;
@property (nonatomic, retain) AddressInfo *addres_info;
@property (nonatomic, retain) NSSet *conections;
@property (nonatomic, retain) OperatorInfo *operator_info;
@end

@interface ChargingLocation (CoreDataGeneratedAccessors)

- (void)addConectionsObject:(Connection *)value;
- (void)removeConectionsObject:(Connection *)value;
- (void)addConections:(NSSet *)values;
- (void)removeConections:(NSSet *)values;

@end
