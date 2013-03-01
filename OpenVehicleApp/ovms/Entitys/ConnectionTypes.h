//
//  ConnectionTypes.h
//  Open Vehicle
//
//  Created by JLab13 on 3/1/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ConnectionTypes : NSManagedObject

@property (nonatomic, retain) NSString * formal_name;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * is_discontinued;
@property (nonatomic, retain) NSNumber * is_obsolete;
@property (nonatomic, retain) NSString * title;

@end
