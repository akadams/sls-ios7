//
//  ProviderListController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/26/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ProviderListController.h"
#import "Principal.h"


static const int kDebugLevel = 1;

static const int kInitialProviderListSize = 10;
// XXX static const int kInitialLocationListSize = 5;
static const float kMaxFrequency = (24.0 * 3600.0);    // 1 day between fetches

static const char* kProviderListFilename = "providers.list";
// XXX static const float kDefaultFrequency = 300.0;       // 5 minutes between fetches


@interface ProviderListController ()
@end

@implementation ProviderListController

#pragma mark - Local data
@synthesize provider_list = _provider_list;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:init: called.");
    
    if (self = [super init]) {
        _provider_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
     }
    
    return self;
}

- (void) setProvider_list:(NSMutableArray*)new_list {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:setProvider_list: called.");
    
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_provider_list != new_list) {
        _provider_list = [new_list mutableCopy];
    }
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListController:copyWithZone: called.");
    
    ProviderListController* tmp_controller = [[ProviderListController alloc] init];
    
    if (_provider_list)
        tmp_controller.provider_list = _provider_list;
    
    return tmp_controller;
}

#pragma mark - State backup & restore

- (NSString*) saveState {
    if (kDebugLevel > 4) 
        NSLog(@"ProviderListController:saveState: called.");
    
    // Save the NSArray to disk.
    
    // Get Document path, and add the name of providers' list file.
    NSArray* dir_list = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* provider_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kProviderListFilename];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderListController:saveState: writing updated list of %lu providers to %s.", (unsigned long)[_provider_list count], [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Note, we must convert our Consumer objects to serialized NSData objects, and rebuild our NSArray.
    
    // XXX TODO(aka) Why do we do this, as opposed to simply making the ProviderListController NSCoding commplient?  It only has the one data member, the NSArray!
    
    NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
    for (int i = 0; i < [_provider_list count]; ++i) {
        Principal* provider = [_provider_list objectAtIndex:i];
        
        if (kDebugLevel > 2)
            NSLog(@"ProviderListController:saveState: converting provider: %s.", [[provider serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);

        NSData* tmp_data = [NSKeyedArchiver archivedDataWithRootObject:provider];
        [serialized_list addObject:tmp_data];
    }
    
    if (![serialized_list writeToFile:provider_list_path atomically:YES]) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"ProviderListController:saveState: writeToFile(%s) failed!", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }

    return nil;
}

- (void) loadState {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListController:loadState: called.");
    
    // Load in our list of providers from disk.
    
    // Get Document path, and add the name of providers' list file.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* provider_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kProviderListFilename];
    
    // If it exists, load it in, else initialize an empty list.
    if ([[NSFileManager defaultManager] fileExistsAtPath:provider_list_path]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderListController:loadState: %s exists, initializing provider list with contents.", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Note, we must convert the serialized NSData object into our Provider object and re-build our NSArray.
        
        NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithContentsOfFile:provider_list_path];
        for (int i = 0; i < [serialized_list count]; ++i) {
            Principal* provider = [NSKeyedUnarchiver unarchiveObjectWithData:[serialized_list objectAtIndex:i]];
            [_provider_list addObject:provider];
        }
    } else {
        if (kDebugLevel > 2)
            NSLog(@"ProviderListController:loadState: %s does not exist, initializing empty provider list.", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);        
        
        _provider_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderListController:loadState: loaded %lu provider(s) from %s.", (unsigned long)[_provider_list count], [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

#pragma mark - Data source routines

- (NSUInteger) countOfList {
    return [_provider_list count];
}

- (Principal*) objectInListAtIndex:(NSUInteger)index {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:objectInListAtIndex: called: %lu.", (unsigned long)index);
    
    if ([_provider_list count] == 0 || index >= [_provider_list count])
        return nil;
    else
        return [_provider_list objectAtIndex:index];
}

- (BOOL) containsObject:(Principal*)provider {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:containsObject: called.");
    
    if (provider == nil)
        return false;
    
    if ([_provider_list count] == 0)
        return false;
    
    return [_provider_list containsObject:provider];
}

#pragma mark - Data management

- (Principal*) getProvider:(NSString*)identity_hash {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:getProvider: called: %@.", identity_hash);
    
    if ([_provider_list count] == 0 || identity_hash == nil || [identity_hash length] == 0)
        return nil;
    
    for (id object in _provider_list) {
        Principal* provider = (Principal*)object;
        
        if ([identity_hash isEqualToString:provider.identity_hash])
            return provider;
    }

    return nil;  // we were unable to find it
}

- (NSString*) addProvider:(Principal*)provider {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:addProvider: called.");
    
    if (provider == nil)
        return nil;
    
    // First, see if the provider already exists in the list (if so, delete it).
    if ([self containsObject:provider])
        [self deleteProvider:provider saveState:false];  // we'll be saving state shortly
    
    [self.provider_list addObject:provider];
    
    // Store our (newly) updated list of providers to disk.
    return [self saveState];
}

- (NSString*) deleteProvider:(Principal*)provider saveState:(BOOL)save_state {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:deleteProvider: called.");
    
    [self.provider_list removeObject:provider];
    
    if (save_state) {
        // Store our (newly) updated list of providers to disk.
        return [self saveState];
    } else {
        return nil;
    }
}

- (NSTimeInterval) getNextTimeInterval {
    if (kDebugLevel > 4)
        NSLog(@"ProviderListContoller:getNextTimeInterval: called.");
    
    NSTimeInterval interval = kMaxFrequency;
    for (int i = 0; i < [_provider_list count]; ++i) {
        Principal* provider = [_provider_list objectAtIndex:i];
        
        // If we don't have a valid file store, might as well skip this provider.
        if (![provider isFileStoreURLValid]) {
            if (kDebugLevel > 0)
                NSLog(@"ProviderListContoller:getNextTimeInterval: skipping provider[%d]: %s, due to nil file store.", i, [[provider serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
        
       NSTimeInterval new_interval = [provider getTimeIntervalToNextFetch];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderListContoller:getNextTimeInterval: index %d, comparing previous interval %f to %f (%s).", i, interval, new_interval, [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        if (new_interval < interval)
            interval = new_interval;
    }
    
    return interval;
}

@end
