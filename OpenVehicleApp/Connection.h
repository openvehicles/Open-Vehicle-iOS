//
//  Connection.h
//  Open Vehicle
//
//  Created by JLab13 on 2/25/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Connection : NSManagedObject

@property (nonatomic, retain) NSNumber * amps;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * level_comments;
@property (nonatomic, retain) NSNumber * level_is_fast_charge;
@property (nonatomic, retain) NSString * level_title;
@property (nonatomic, retain) NSString * power_kw;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSString * reference;
@property (nonatomic, retain) NSNumber * status_is_operational;
@property (nonatomic, retain) NSString * status_title;
@property (nonatomic, retain) NSString * type_formal_name;
@property (nonatomic, retain) NSNumber * type_is_discontinued;
@property (nonatomic, retain) NSNumber * type_is_obsolete;
@property (nonatomic, retain) NSString * type_title;
@property (nonatomic, retain) NSNumber * voltage;

@end
