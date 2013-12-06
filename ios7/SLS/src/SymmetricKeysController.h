//
//  SymmetricKeysController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/7/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, the symmetric keys are stored in the key-chain when created, so we can load them from there on startup.

#import <Foundation/Foundation.h>

#import "ConsumerListController.h"  // needed for notification


// Indexes into symmetric keys dictionary.
typedef enum {
    SKC_PRECISION_NONE = 0,
    SKC_PRECISION_LOW = 1,
    SKC_PRECISION_MEDIUM = 2,
    SKC_PRECISION_HIGH = 3
} SKCPrecisionLevels;

static const int kNumPrecisionLevels = SKC_PRECISION_HIGH;


@interface SymmetricKeysController : NSObject

@property (copy, nonatomic) NSMutableDictionary* symmetric_keys;  // map of symmetric keys indexed by precision level

- (id) init;
- (id) copyWithZone:(NSZone*)zone;
- (NSUInteger) count;
- (NSData*) objectForKey:(NSNumber*)precision;
- (void) setObject:(NSData*)symmetric_key forKey:(NSNumber*)precision;
- (void) removeObjectForKey:(NSNumber*)precision;
- (NSEnumerator*) keyEnumerator;
- (void) deleteSymmetricKey:(NSNumber*)precision;
- (NSData*) genSymmetricKey:(NSNumber*)precision;
- (NSArray*) loadState;
- (BOOL) haveKeys;

@end
