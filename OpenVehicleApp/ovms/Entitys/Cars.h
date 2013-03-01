//
//  Cars.h
//  Open Vehicle
//
//  Created by JLab13 on 3/1/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Cars : NSManagedObject

@property (nonatomic, retain) NSString * imagepath;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * netpass;
@property (nonatomic, retain) NSString * userpass;
@property (nonatomic, retain) NSString * vehicleid;
@property (nonatomic, retain) NSString * connection_type_ids;

@end
