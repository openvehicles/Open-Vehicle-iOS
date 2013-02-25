//
//  ChargingPin.h
//  OpenChargeMap
//
//  Created by JLab13 on 2/21/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "REVClusterPin.h"
#import "EntityName.h"

@interface ChargingAnnotation : REVClusterPin

@property (nonatomic, assign) NSInteger level;
@property (nonatomic, copy) NSString *location_uuid;

+ (id)pinWithChargingLocation:(ChargingLocation*)location;
- (id)initWithChargingLocation:(ChargingLocation*)location;

@end
