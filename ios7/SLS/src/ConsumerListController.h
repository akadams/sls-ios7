//
//  ConsumerListController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 3/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, this controller class is for the provider's viewController, which displays Consumer objects, *not* the consumer's viewController (which displays the different Provider objects!).

#import <Foundation/Foundation.h>


@class Principal;

@interface ConsumerListController : NSObject

#pragma mark - Local variables
@property (copy, nonatomic) NSMutableArray* consumer_list;  // list of Consumer objects

#pragma mark - Initialization
- (id) init;
- (void) setConsumer_list:(NSMutableArray*)new_list;

#pragma mark - State backup & restore
- (NSString*) saveState;
- (NSString*) loadState;

#pragma mark - Data source routines
- (NSUInteger) countOfList;
- (Principal*) objectInListAtIndex:(NSUInteger)index;
- (void) removeObjectAtIndex:(NSUInteger)index;
- (BOOL) containsObject:(Principal*)consumer;

#pragma mark - Data management
- (NSString*) addConsumer:(Principal*)consumer;
- (NSString*) deleteConsumer:(Principal*)consumer saveState:(BOOL)save_state;

/*  XXX We need to override the following from NSMutableArray and NSArray
insertObject:atIndex:
addObject:
removeLastObject
replaceObjectAtIndex:withObject:
count
objectAtIndex
 XXX As well as the ones for the protocols.
NSCopying, NSMutableCopying, and NSCoding protocols
*/

@end
