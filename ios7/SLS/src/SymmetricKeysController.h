//
//  SymmetricKeysController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/7/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, the symmetric keys are stored in the key-chain when created, so we can load them from there on startup.

#import <Foundation/Foundation.h>

#import "PolicyController.h"
#import "ConsumerListController.h"  // needed for notification  XXX is this still true?  I think notification is now done in MVC!


@interface SymmetricKeysController : NSObject

#pragma mark - Local data
@property (copy, nonatomic) NSMutableDictionary* symmetric_keys;  // map of symmetric keys indexed by precision level
@property (copy, nonatomic) NSMutableArray* policies;             // dictionary keys currently in use within _symmetric_keys

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;

#pragma mark - State backup & restore
- (NSString*) loadState;

#pragma mark - NSMutableDictionary symmetric keys management
- (NSUInteger) count;  // XXX TODO(aka) I don't think we need this one, or it should be called countSymmetricKeys:
- (NSData*) objectForKey:(NSString*)policy;
- (void) setObject:(NSData*)symmetric_key forKey:(NSString*)policy;
- (void) removeObjectForKey:(NSString*)policy;
- (NSEnumerator*) keyEnumerator;

#pragma mark - Symmetric key management
- (void) deleteSymmetricKey:(NSString*)policy;         // updates state
- (NSString*) generateSymmetricKey:(NSString*)policy;  // updates state
- (BOOL) haveKey:(NSString*)policy;
- (BOOL) haveAllKeys;
- (BOOL) haveAnyKeys;

@end
