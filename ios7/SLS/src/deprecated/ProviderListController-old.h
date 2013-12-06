//
//  ProviderListController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/26/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, this controller class is for the consumer's viewController, which displays Provider objects, *not* the provider's viewController (which displays the different Consumer objects!).

#import <Foundation/Foundation.h>


@class Principal;

@interface ProviderListController : NSObject

@property (copy, nonatomic) NSMutableArray* provider_list;  // list of Provider objects

- (id) init;
- (void) loadState;
- (NSString*) saveState;
- (void) setProvider_list:(NSMutableArray*)new_list;
- (id) copyWithZone:(NSZone*)zone;
- (NSUInteger) countOfList;
- (Principal*) objectInListAtIndex:(NSUInteger)index;
- (BOOL) containsObject:(Principal*)provider;
- (NSString*) addProvider:(Principal*)provider;
- (NSString*) deleteProvider:(Principal*)provider saveState:(BOOL)save_state;
- (NSTimeInterval) getNextTimeInterval;

// TODO(aka) Add the following NSMutableArray functions for the list.
// insertObject:atIndex:
// removeObjectAtIndex:
// addObject:
// removeLastObject
// replaceObjectAtIndex:withObject:


@end
