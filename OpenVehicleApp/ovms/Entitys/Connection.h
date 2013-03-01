//
//  Connection.h
//  Open Vehicle
//
//  Created by JLab13 on 3/1/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ChargerTypes, ConnectionTypes;

@interface Connection : NSManagedObject

@property (nonatomic, retain) NSNumber * amps;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * power_kw;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSString * reference;
@property (nonatomic, retain) NSNumber * status_is_operational;
@property (nonatomic, retain) NSString * status_title;
@property (nonatomic, retain) NSNumber * voltage;
@property (nonatomic, retain) ChargerTypes *level;
@property (nonatomic, retain) ConnectionTypes *connection_type;

@end
