//
//  NSObject+CDHelper.h
//  OpenChargeMap
//
//  Created by JLab13 on 2/20/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CDHelper) 

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (NSFetchRequest *)fetchRequestWithEntityName:(NSString *) entityName;
- (NSArray *)executeFetchRequest:(NSFetchRequest *)request;
- (id)entityWithName:(NSString *)name asWhere:(NSString *)where inValue:(NSString *)value;
//- (void)deleteAllEntityWithName:(NSString *)name;

@end
