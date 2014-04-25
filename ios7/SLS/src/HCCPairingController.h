//
//  HCCPairingController.h
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//
// XXX Deprecated Class!

#import <Foundation/Foundation.h>

@class Principal;

@interface HCCPairingController : NSObject

#pragma mark - Local data
@property (copy, nonatomic) NSMutableDictionary* principals;  // map of potential principals indexed by their HCC state (or status)

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;

#pragma mark - State backup & restore
- (NSString*) loadState;

#pragma mark - NSMutableDictionary _principals management
- (NSUInteger) count;
- (void) setObject:(Principal*)principal forKey:(NSNumber*)mode;
- (Principal*) objectForKey:(NSNumber*)mode;
- (void) removeObjectForKey:(NSString*)mode;
/* XXX
- (NSEnumerator*) keyEnumerator;
 */

#pragma mark - HCC pairing management
/* XXX
- (void) deleteSymmetricKey:(NSString*)policy;         // updates state
- (NSString*) generateSymmetricKey:(NSString*)policy;  // updates state
- (BOOL) haveKey:(NSString*)policy;
- (BOOL) haveAllKeys;
- (BOOL) haveAnyKeys;
 */

@end
