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
static const int kInitialLocationListSize = 5;
static const float kMaxFrequency = (24.0 * 3600.0);    // 1 day between fetches

static const char* kProviderListFilename = "providers.list";
static const float kDefaultFrequency = 300.0;       // 5 minutes between fetches

// TODO(aka) The below class has been deprecated.

// Create a *nested* class that can represent the Principal Class as a property list.
@interface ProviderPropertyList : NSObject <NSCoding>

@property (copy, nonatomic) NSString* identity;         // provider's identity
@property (copy, nonatomic) NSString* deposit;          // provider's deposit
@property (copy, nonatomic) NSString* file_store;       // provider's file store (was NSURL)
@property (copy, nonatomic) NSData* key;                // shared symmetric key
//@property (copy, nonatomic) NSArray* locations;         // provider's past locations (was NSMutableArray)
@property (copy, nonatomic) NSString* last_fetch;       // date of last fetch (was NSDate)
@property (copy, nonatomic) NSString* frequency;        // requested seconds between fetches (was NSNumber)
@property (copy, nonatomic) NSString* is_focus;         // (was BOOL)

- (id) initWithProvider:(Principal*)provider;
- (Principal*) absoluteProvider;

@end

@implementation ProviderPropertyList

@synthesize identity = _identity;
@synthesize file_store = _file_store;
@synthesize key = _key;
//@synthesize locations = _locations;
@synthesize last_fetch = _last_fetch;
@synthesize frequency = _frequency;
@synthesize is_focus = _is_focus;

- (id) initWithProvider:(Principal*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ProviderPropertyList:initWithProvider: called.");
    
    if (self = [super init]) {
        _identity = provider.identity;
        _file_store = [provider.file_store absoluteString];
        _key = provider.key;
        
        // TODO(aka) For now, we're not going to bother with locations.
        //_locations = [NSArray array];
        
        NSDateFormatter* date_formatter = [[NSDateFormatter alloc] init];
        [date_formatter setTimeStyle:NSDateFormatterNoStyle];
        [date_formatter setDateStyle:NSDateFormatterMediumStyle];
        NSLocale* us_locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [date_formatter setLocale:us_locale];
        _last_fetch = [date_formatter stringFromDate:provider.last_fetch];
        
        _frequency = [[NSString alloc] initWithFormat:@"%f", [provider.frequency floatValue]];
        _is_focus = [[NSString alloc] initWithFormat:@"%d", provider.is_focus];
    }
    
    return self;
}

- (Principal*) absoluteProvider {
    if (kDebugLevel > 2)
        NSLog(@"ProviderPropertyList:absoluteProvider: called.");
    
    Principal* provider = [[Provider alloc] initWithIdentity:_identity];
    if (_file_store != nil)
        provider.file_store = [[NSURL alloc] initWithString:_file_store];
    else
        provider.file_store = nil;
    provider.key = _key;
    provider.locations = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];   
    if (_frequency != nil)
        provider.frequency = [[NSNumber alloc] initWithFloat:[_frequency floatValue]];
    else
        provider.frequency = [[NSNumber alloc] initWithFloat:kDefaultFrequency];
    provider.last_fetch = nil;
    provider.is_focus = [_is_focus boolValue];
    
    return provider;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"ProviderPropertyList:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        
        _identity = [decoder decodeObjectForKey:@"identity"];
        _file_store = [decoder decodeObjectForKey:@"file-store"];
        _key = [decoder decodeObjectForKey:@"symmetric-key"];
        
        // TODO(aka) For now, we're not going to bother with locations.
        //_locations = [NSArray array];
/*        
        NSDateFormatter* date_formatter = [[NSDateFormatter alloc] init];
        [date_formatter setTimeStyle:NSDateFormatterNoStyle];
        [date_formatter setDateStyle:NSDateFormatterMediumStyle];
        NSLocale* us_locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [date_formatter setLocale:us_locale];
        _last_fetch = [date_formatter stringFromDate:provider.last_fetch];
 */
        
        _frequency = [decoder decodeObjectForKey:@"frequency"];
        _is_focus = [decoder decodeObjectForKey:@"is-focus"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"ProviderPropertyList:encodeWithCoder: called.");
    
    [encoder encodeObject:_identity forKey:@"identity"];
    [encoder encodeObject:_file_store forKey:@"file-store"];
    [encoder encodeObject:_key forKey:@"symmetric-key"];
    [encoder encodeObject:_frequency forKey:@"frequency"];
    [encoder encodeObject:_is_focus forKey:@"is-focus"];
}

@end


@interface ProviderListController ()

@end

@implementation ProviderListController

@synthesize provider_list = _provider_list;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListContoller:init: called.");
    
    if (self = [super init]) {
        _provider_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
     }
    
    return self;
}

- (NSString*) saveState {
    if (kDebugLevel > 2) 
        NSLog(@"ProviderListController:saveState: called.");
    
    // Save the NSArray to disk.
    
    // Get Document path, and add the name of providers' list file.
    NSArray* dir_list = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* provider_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kProviderListFilename];
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderListController:saveState: writing updated list of %lu providers to %s.", (unsigned long)[_provider_list count], [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Note, we must convert our Consumer objects to serialized NSData objects, and rebuild our NSArray.
    
    NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
    for (int i = 0; i < [_provider_list count]; ++i) {
        Principal* provider = [_provider_list objectAtIndex:i];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderListController:saveState: converting provider: %s.", [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);

#if 0
        // XXX Let's try with just NSCoding in Provider
        ProviderPropertyList* pl_provider = [[ProviderPropertyList alloc] initWithProvider:provider];
        NSData* tmp_data = [NSKeyedArchiver archivedDataWithRootObject:pl_provider];
#else
        NSData* tmp_data = [NSKeyedArchiver archivedDataWithRootObject:provider];
#endif
        [serialized_list addObject:tmp_data];
    }
    
    if (![serialized_list writeToFile:provider_list_path atomically:YES]) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"ProviderListController:saveState: writeToFile(%s) failed!", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }

    /*
    // XXX TODO(aka) Alteratively, we could simply serialize the entire list
    NSData* list_data = [NSKeyedArchiver archivedDataWithRootObject:serialized_list];
    [[NSUserDefaults standardUserDefaults] setObject:list_data forKey:@"provider-list"];
*/    

    return nil;
}

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListController:loadState: called.");
    
    // Load in our list of providers from disk.
    
    // Get Document path, and add the name of providers' list file.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* provider_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kProviderListFilename];
    
    // If it exists, load it in, else initialize an empty list.
    if ([[NSFileManager defaultManager] fileExistsAtPath:provider_list_path]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderListController:loadState: %s exists, initializing provider list with contents.", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Note, we must convert the serialized NSData object into our Provider object and re-build our NSArray.
        
        NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithContentsOfFile:provider_list_path];
        for (int i = 0; i < [serialized_list count]; ++i) {
#if 0
            // XXX Let's try with just the NSCoding in Provider.
            ProviderPropertyList* pl_provider = [NSKeyedUnarchiver unarchiveObjectWithData:[serialized_list objectAtIndex:i]];
            Principal* provider = [pl_provider absoluteProvider];
#else
            Principal* provider = [NSKeyedUnarchiver unarchiveObjectWithData:[serialized_list objectAtIndex:i]];
#endif
            [_provider_list addObject:provider];
        }
        
        /*
         // XXX TODO(aka) Alternatively, we could simply read in the entire serialized list.
         NSData* list_data = [[NSUserDefaults standardUserDefaults] objectForKey:@"provider-list"];
         NSArray* serialized_list = [NSKeyedUnarchiver unarchiveObjectWithData:list_data];
         */
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderListController:loadState: %s does not exist, initializing empty provider list.", [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);        
        
        _provider_list = [[NSMutableArray alloc] initWithCapacity:kInitialProviderListSize];
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderListController:loadState: loaded %lu provider(s) from %s.", (unsigned long)[_provider_list count], [provider_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (void) setProvider_list:(NSMutableArray*)new_list {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListContoller:setProvider_list: called.");
    
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_provider_list != new_list) {
        _provider_list = [new_list mutableCopy];
    }
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListController:copyWithZone: called.");
    
    ProviderListController* tmp_controller = [[ProviderListController alloc] init];
    
    if (_provider_list)
        tmp_controller.provider_list = _provider_list;

    return tmp_controller;
}

- (NSUInteger) countOfList {
    return [_provider_list count];
}

- (Principal*) objectInListAtIndex:(NSUInteger)index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListContoller:objectInListAtIndex: called: %lu.", (unsigned long)index);
    
    if ([_provider_list count] == 0 || index >= [_provider_list count])
        return nil;
    else
        return [_provider_list objectAtIndex:index];
}

- (BOOL) containsObject:(Principal*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListContoller:containsObject: called.");
    
    if (provider == nil)
        return false;
    
    if ([_provider_list count] == 0)
        return false;
    
    return [_provider_list containsObject:provider];
}

- (NSString*) addProvider:(Principal*)provider {
    if (kDebugLevel > 2)
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
    if (kDebugLevel > 2)
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
    if (kDebugLevel > 2)
        NSLog(@"ProviderListContoller:getNextTimeInterval: called.");
    
    NSTimeInterval interval = kMaxFrequency;
    for (int i = 0; i < [_provider_list count]; ++i) {
        Principal* provider = [_provider_list objectAtIndex:i];
        
        // If we don't have a valid file store, might as well skip this provider.
        if (provider.file_store == nil) {
            if (kDebugLevel > 0)
                NSLog(@"ProviderListContoller:getNextTimeInterval: skipping provider[%d]: %s, due to nil file store.", i, [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
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


// Delegate functions.

@end
