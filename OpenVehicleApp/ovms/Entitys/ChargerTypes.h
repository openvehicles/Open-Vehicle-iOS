//
//  ChargerTypes.h
//  Open Vehicle
//
//  Created by JLab13 on 3/1/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ChargerTypes : NSManagedObject

@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * is_fast_charge_capable;
@property (nonatomic, retain) NSString * title;

@end
