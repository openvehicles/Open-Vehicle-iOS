//
//  NSObject+CDHelper.m
//  OpenChargeMap
//
//  Created by JLab13 on 2/20/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "NSObject+CDHelper.h"
#import "ovmsAppDelegate.h"

@implementation NSObject (CDHelper)

- (NSManagedObjectContext *)managedObjectContext {
    return [ovmsAppDelegate myRef].managedObjectContext;
}

#pragma mark - Core data helper
- (NSFetchRequest *)fetchRequestWithEntityName:(NSString *) entityName {
    NSFetchRequest *fr = [NSFetchRequest new];
    [fr setEntity:[NSEntityDescription entityForName:entityName
                              inManagedObjectContext:self.managedObjectContext]];
    return fr;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request {
	NSError *error = nil;
	NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error != nil) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return result;
}

- (id)entityWithName:(NSString *)name asWhere:(NSString *)where inValue:(NSString *)value {
	NSFetchRequest *fr = [self fetchRequestWithEntityName:name];
    [fr setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", where, value]];
    NSArray *data = [self executeFetchRequest:fr];
    return data.count > 0 ? data[0] : nil;
}

- (void)deleteAllEntityWithName:(NSString *)name {
	NSFetchRequest *fr = [NSFetchRequest new];
	[fr setEntity:[NSEntityDescription entityForName:name
                              inManagedObjectContext:self.managedObjectContext]];
    [fr setIncludesPropertyValues:NO];
    
    NSError *error = nil;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fr error:&error];
//    if (error) return NO;
    if (error) return;
    
    for (NSManagedObject *entity in items) {
        [self.managedObjectContext deleteObject:entity];
    }
//    return [self.managedObjectContext save:&error];
}



@end
