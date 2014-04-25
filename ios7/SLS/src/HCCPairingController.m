//
//  HCCPairingController.m
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "HCCPairingController.h"
#import "PersonalDataController.h"


static const int kDebugLevel = 1;

static const char* kHCCPrincipalsFilename = "hcc-principals";  // state file that holds dictionary of principals on local disk


@interface HCCPairingController ()
@end

@implementation HCCPairingController

#pragma mark - Local data
@synthesize principals = _principals;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:init: called.");
    
    if (self = [super init]) {
        _principals = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:copywithZone: called.");
    
    HCCPairingController* tmp_hcc_controller = [[HCCPairingController alloc] init];
    tmp_hcc_controller.principals = _principals;
    
    return tmp_hcc_controller;
}

- (void) setPrincipals:(NSMutableDictionary*)principals {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:setPrincipals: called.");
    
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_principals != principals) {
        _principals = [principals mutableCopy];
    }
}

#pragma mark - State backup & restore

- (NSString*) loadState {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:loadState: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"HCCPairingController:loadState: XXX TODO(aka) Not implemented yet!");
    
    NSDictionary* tmp_principals = [PersonalDataController loadStateDictionary:[[NSString alloc] initWithCString:kHCCPrincipalsFilename encoding:[NSString defaultCStringEncoding]]];
    if (tmp_principals != nil || [tmp_principals count] > 0) {
        _principals = [tmp_principals mutableCopy];
    } else {
        if (kDebugLevel > 1)
            NSLog(@"HCCPairingController:loadState: No HCC principals found on disk.");
    }
    
    return nil;
}

#pragma mark - NSMutableDictionary management

- (NSUInteger) count {
    return [_principals count];
}

- (NSData*) objectForKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:objectForKey: called.");
    
    return [_principals objectForKey:policy];
}

- (void) setObject:(NSData*)symmetric_key forKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:setObject: called.");
    
    [_principals setObject:symmetric_key forKey:policy];
}

- (void) removeObjectForKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"HCCPairingController:removeObjectForKey: called.");
    
    [_principals removeObjectForKey:policy];
}

@end
