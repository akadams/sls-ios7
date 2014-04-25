//
//  Principal.m
//  SLS
//
//  Created by Andrew K. Adams on 12/4/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "NSData+Base64.h"

#import "Principal.h"
#import "LocationBundleController.h"
#import "PersonalDataController.h"           // only needed for Class crypto functions & NSDictionary functions
#import "security-defines.h"


static const int kDebugLevel = 1;

static const char* kStringDelimiter = ":";
static const char* kPublicKeyExt = KC_QUERY_KEY_PUBLIC_KEY_EXT;
static const int kInitialLocationListSize = 5;
static const float kDefaultFrequency = 300.0;       // 5 minutes between fetches


@interface Principal ()
- (void) setPublicKeyRef:(SecKeyRef)public_key_ref;
@end

@implementation Principal

#pragma mark - Local variables
@synthesize identity = _identity;
@synthesize identity_hash = _identity_hash;
@synthesize mobile_number = _mobile_number;
@synthesize email_address = _email_address;
@synthesize deposit = _deposit;

#pragma mark - Data used by ConsumerMaster VC
@synthesize key_bundle_url = _key_bundle_url;
@synthesize file_store_url = _file_store_url;
@synthesize key = _key;
@synthesize history_log = _history_log;
@synthesize last_fetch = _last_fetch;
@synthesize frequency = _frequency;
@synthesize is_focus = _is_focus;

#pragma mark - Data used by ProviderMaster VC
@synthesize policy = _policy;
@synthesize file_store_sent = _file_store_sent;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"Principal:init: called.");
    
    if (self = [super init]) {
        publicKeyRef = NULL;
        _identity = nil;
        _identity_hash = nil;
        _mobile_number = nil;
        _email_address = nil;
        _deposit = nil;
        _file_store_url = nil;
        _key_bundle_url = nil;
        _key = nil;
        _history_log = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
        _last_fetch = nil;
        _frequency = [[NSNumber alloc] initWithFloat:kDefaultFrequency];
        _is_focus = false;
        _policy = nil;
        _file_store_sent = false;
    }
    
    return self;
}

- (id) initWithIdentity:(NSString*)identity {
    if (kDebugLevel > 2)
        NSLog(@"Principal:initWithIdentity: called.");
    
    self = [super init];
    if (self) {
        publicKeyRef = NULL;
        _identity = identity;  // note, identity could be nil
        _identity_hash = [PersonalDataController hashMD5String:_identity];  // TODO(aka) arguable if we should call this in an init:
        _mobile_number = nil;
        _email_address = nil;
        _deposit = nil;
        _file_store_url = nil;
        _key_bundle_url = nil;
        _key = nil;
        _history_log = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
        _last_fetch = nil;
        _frequency = [[NSNumber alloc] initWithFloat:kDefaultFrequency];
        _is_focus = false;
        _policy = nil;
        _file_store_sent = false;
        
        return self;
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"Principal:copyWithZone: called.");
    
    Principal* tmp_controller = [[Principal alloc] init];
    if (_identity)
        tmp_controller.identity = _identity;
    
    if (_identity_hash)
        tmp_controller.identity_hash = _identity_hash;
    
    if (_mobile_number)
        tmp_controller.mobile_number = _mobile_number;
    
    if (_email_address)
        tmp_controller.email_address = _email_address;
    
    if (_deposit)
        tmp_controller.deposit = _deposit;
    
    if (_file_store_url)
        tmp_controller.file_store_url = _file_store_url;
    
    if (_key_bundle_url)
        tmp_controller.key_bundle_url = _key_bundle_url;
    
    if (_key)
        tmp_controller.key = _key;
    
    if (_history_log)
        tmp_controller.history_log = _history_log;
    
    if (_last_fetch)
        tmp_controller.last_fetch = _last_fetch;
    
    if (_frequency)
        tmp_controller.frequency = _frequency;
    
    tmp_controller.is_focus = _is_focus;
    
    tmp_controller.policy = _policy;
    
    tmp_controller.file_store_sent = _file_store_sent;
    
    if (publicKeyRef)
        tmp_controller.publicKeyRef = publicKeyRef;
    
    return tmp_controller;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"Principal:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _identity = [decoder decodeObjectForKey:@"identity"];
        _identity_hash = [decoder decodeObjectForKey:@"identity-hash"];
        _mobile_number = [decoder decodeObjectForKey:@"mobile-number"];
        _email_address = [decoder decodeObjectForKey:@"email-address"];
        _deposit = [decoder decodeObjectForKey:@"deposit"];
        _file_store_url = [decoder decodeObjectForKey:@"file-store-url"];
        _key_bundle_url = [decoder decodeObjectForKey:@"key-bundle-url"];
        _key = [decoder decodeObjectForKey:@"symmetric-key"];
        _history_log = [decoder decodeObjectForKey:@"history-log"];
        _last_fetch = [decoder decodeObjectForKey:@"last-fetch"];
        _frequency = [decoder decodeObjectForKey:@"frequency"];
        _is_focus = [decoder decodeBoolForKey:@"is-focus"];
        _policy = [decoder decodeObjectForKey:@"policy"];
        _file_store_sent = [decoder decodeBoolForKey:@"file-store-sent"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"Principal:encodeWithCoder: called.");
    
    [encoder encodeObject:_identity forKey:@"identity"];
    [encoder encodeObject:_identity_hash forKey:@"identity-hash"];
    [encoder encodeObject:_mobile_number forKey:@"mobile-number"];
    [encoder encodeObject:_email_address forKey:@"email-address"];
    [encoder encodeObject:_deposit forKey:@"deposit"];
    [encoder encodeObject:_file_store_url forKey:@"file-store-url"];
    [encoder encodeObject:_key_bundle_url forKey:@"key-bundle-url"];
    [encoder encodeObject:_key forKey:@"symmetric-key"];
    [encoder encodeObject:_history_log forKey:@"history-log"];
    [encoder encodeObject:_last_fetch forKey:@"last-fetch"];
    [encoder encodeObject:_frequency forKey:@"frequency"];
    [encoder encodeBool:_is_focus forKey:@"is-focus"];
    [encoder encodeObject:_policy forKey:@"policy"];
    [encoder encodeBool:_file_store_sent forKey:@"file-store-sent"];
}

#pragma mark - Data management

- (void) setDeposit:(NSMutableDictionary*)deposit {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_deposit != deposit) {
        _deposit = [deposit mutableCopy];
    }
}

#if (FILE_STORE_USE_NSURL == 1)

- (void) setFile_store_url:(NSURL*)file_store_url {
    if (kDebugLevel > 2)
        NSLog(@"Principal:setFile_store_url: called.");
    
    _file_store_url = file_store_url;
}

- (void) setKey_bundle_url:(NSURL*)key_bundle_url {
    if (kDebugLevel > 2)
        NSLog(@"Principal:setKey_bundle_url: called.");
    
    _key_bundle_url = key_bundle_url;
}
#else
- (void) setFile_store:(NSMutableDictionary*)file_store {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_file_store != file_store) {
        _file_store = [file_store mutableCopy];
    }
}
#endif

- (void)setHistory_log:(NSMutableArray*)history_log {
    if (kDebugLevel > 2)
        NSLog(@"Principal:setHistory_log: called.");
    
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_history_log != history_log) {
        _history_log = [history_log mutableCopy];
    }
}

- (SecKeyRef) publicKeyRef {
    if (kDebugLevel > 2)
        NSLog(@"Principal:publicKeyRef: called.");
    
    if (publicKeyRef != NULL)
        return publicKeyRef;
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity_str = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity_str dataUsingEncoding:[NSString defaultCStringEncoding]];
    NSString* err_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (err_msg != nil)
        NSLog(@"Principal:publicKeyRef: TODO(aka) queryKeyRef() failed: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return publicKeyRef;
}

- (void) setPublicKeyRef:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"Principal:setPublicKeyRef: called.");
    
    // Note, the key-chain will be updated in setPublicKey().
    publicKeyRef = public_key_ref;
}

- (NSData*) getPublicKey {
    if (kDebugLevel > 2)
        NSLog(@"Principal:getPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    NSData* public_key = nil;
    NSString* err_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
    if (err_msg != nil)
        NSLog(@"Principal:getPublicKey: TODO(aka) queryKeyData() failed: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return public_key;
}

- (void) setPublicKey:(NSData*)public_key accessGroup:(NSString*)access_group {
    if (kDebugLevel > 2)
        NSLog(@"Principal:setPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    if (publicKeyRef != NULL) {
        // Delete the key we currently have in the key-chain.
        [PersonalDataController deleteKeyRef:application_tag];
        publicKeyRef = NULL;
    }
    
    // Add the new key to our key-chain.
    NSString* err_msg = [PersonalDataController saveKeyData:public_key withTag:application_tag accessGroup:access_group];
    if (err_msg != nil)
        NSLog(@"Principal:setPublicKey: TODO(aka) saveKeyData() failed: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // And get a reference to the newly added key.
    err_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (err_msg != nil)
        NSLog(@"Principal:setPublicKey: TODO(aka) queryKeyRef() failed: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (BOOL) isEqual:(Principal*)principal {
    if (kDebugLevel > 2)
        NSLog(@"Principal:isEqual: called.");
    
    if (principal == nil || principal.identity == nil || [principal.identity length] == 0) {
        if (kDebugLevel > 0)
            NSLog(@"Principal:isEqual: SYSTEM_ERROR: principal or principal's identity is nil or empty!");
        return false;
    }
    
    if (_identity == nil || [_identity length] == 0) {
        if (kDebugLevel > 0)
            NSLog(@"Principal:isEqual: SYSTEM_ERROR: _idenity is nil or empty!");
        return false;
    }
    
    if (![_identity isEqual:principal.identity])
        return false;
    
    // For now, we only care about the identities.
    return true;
}

#pragma mark - ConsumerMaster VC utilities

- (void) updateLastFetch {
    if (kDebugLevel > 2)
        NSLog(@"Principal:updateLastFetch: called.");
    
    if (_last_fetch == nil)
        _last_fetch = [[NSDate alloc] init];
    else
        _last_fetch = [[NSDate alloc] init];  // hell with it, just get a new date
}

- (NSTimeInterval) getTimeIntervalToNextFetch {
    if (kDebugLevel > 2)
        NSLog(@"Principal:getTimeIntervalToNextFetch: called.");
    
    if (_last_fetch == nil)
        return 0.0;
    
    // Get our *banked* wait time.
    NSTimeInterval wait_time = abs([_last_fetch timeIntervalSinceNow]);
    
    if (kDebugLevel > 1)
        NSLog(@"Principal:getTimeIntervalToNextFetch: comparing wait time: %f, to our frequency: %f.", wait_time, [_frequency doubleValue]);
    
    // Return how long we've waited (subtracted from our frequency).
    if (wait_time >= [_frequency doubleValue])
        return 0.0;  // we've waited long enough
    else
        return ([_frequency doubleValue] - wait_time);
}

- (BOOL) isFileStoreURLValid {
    if (kDebugLevel > 2)
        NSLog(@"Principal:isFileStoreURLValid: called.");
    
#if (FILE_STORE_USE_NSURL == 1)
    // TODO(aka) We probably should issue checkResourceIsReachableAndReturnError:!
    if (_file_store_url != nil && [[_file_store_url absoluteString] length] > 0  && [[_file_store_url path] length] > 0)
            return true;
    
    return false;
#else
    return [PersonalDataController isFileStoreValid:_file_store];
#endif
}

- (BOOL) isKeyBundleURLValid {
    if (kDebugLevel > 2)
        NSLog(@"Principal:isKeyBundleURLValid: called.");
    
#if (FILE_STORE_USE_NSURL == 1)
    // TODO(aka) We probably should issue checkResourceIsReachableAndReturnError:!
    if (_key_bundle_url != nil && [[_key_bundle_url absoluteString] length] > 0)
        return true;
    else
        return false;
#else
    return [PersonalDataController isFileStoreValid:_file_store];
#endif
}

#pragma mark - Deprecated ConsumerMaster VC utilities

#if 0
- (void) addLocation:(CLLocation*)location {
    if (kDebugLevel > 2)
        NSLog(@"Principal:addLocation: called.");
    
    xxx;  // I think this routine has changed.
    
    if (_history_log == nil)
        _history_log = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
    
    int count = (int)[_history_log count];  // get how many we start with
    
    if (kDebugLevel > 0)
        NSLog(@"Principal:addLocation: adding location: %s to %d count array (max is %d).", [location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], count, kInitialLocationListSize);
    
    [_history_log insertObject:location atIndex:0];
    
    // Make sure our list stays at our maximum size.
    if (count >= kInitialLocationListSize) {
        NSString* description = [[_history_log objectAtIndex:count] description];
        if (kDebugLevel > 0)
            NSLog(@"Principal:addLocation: removing location: %s, for count (%d) reached max: %d.", [description cStringUsingEncoding:[NSString defaultCStringEncoding]], count, kInitialLocationListSize);
        
        [_history_log removeObjectAtIndex:count];
        
        if (kDebugLevel > 0)
            NSLog(@"Principal:addLocation: array downsized to: %lu.", (unsigned long)[_history_log count]);
    }
}

- (NSString*) fetchLocationData {
    if (kDebugLevel > 2)
        NSLog(@"Principal:fetchLocationData: called.");
    
    if (kDebugLevel > 2)
        NSLog(@"Principal:fetchLocationData: checking file-store for provider: %s.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    xxx; // I think this work should be done in the Consumer MVC.
    
#if (FILE_STORE_USE_NSURL == 1)
    if (_file_store == nil) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
#else
    if (![PersonalDataController isFileStoreValid:_file_store]) {
        NSLog(@"Principal:fetchLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return;  // haven't received a file-store yet
    }
#endif
    
    if (_key == nil ||
        ([_key length] == 0)) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: ERROR: Provider %s has a file store, but no symmetric key!", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    // Fetch the location data.
    NSString* encrypted_location_data_b64 = nil;
    NSString* err_msg = [self downloadLocationData:&encrypted_location_data_b64];
    if (err_msg != nil) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: %s", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
    if (kDebugLevel > 2)
        NSLog(@"Principal:fetchLocationData: file-store: %s, fetched base64 data: %s.", [[_file_store absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Unencrypt the location data.
    NSData* encrypted_location_data = [NSData dataFromBase64String:encrypted_location_data_b64];
    NSData* serialized_location_data = nil;
    err_msg = [PersonalDataController decryptData:encrypted_location_data bundleSize:[encrypted_location_data length] symmetricKey:_key decryptedData:&serialized_location_data];
    if (err_msg) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: %s: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"Principal:fetchLocationData: serialized location data is %lub.", (unsigned long)[serialized_location_data length]);
    
    // We have this test, so we don't inadvertedly try to de-serialize something that wasn't serialized by NSKeyArchiver.
    
    if ([serialized_location_data length] != 724) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: fetched serialized data for identity: %s is not 724b, so skipping.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
#if 0
    NSString* location_data_str = [[NSString alloc] initWithBytes:[serialized_location_data bytes] length:[serialzied_location_data length] encoding:[NSString defaultCStringEncoding]];
    
    // Get the coordinates from the string.
    
    // XXX TODO(aka) Make a kLDDelimiter!
    CLLocation* location = nil;
    NSArray* components = [location_data_str componentsSeparatedByString:@":"];
    if ([components count] >= 3) {
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [[components objectAtIndex:0] doubleValue];
        coordinate.longitude = [[components objectAtIndex:1] doubleValue];
        location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 course:[[components objectAtIndex:2] doubleValue] speed:0 timestamp:nil];
    } else if ([components count] == 2) {
        location = [[CLLocation alloc] initWithLatitude:[[components objectAtIndex:0] doubleValue] longitude:[[components objectAtIndex:1] doubleValue]];
    } else {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Principal:fetchLocationData: unable to parse: %s.", location_data_str];
        return err_msg;
    }
#else
    // For simplicity, we are going to serialize the CLLocation object (as it conforms to NSCoding).
    CLLocation* location = [NSKeyedUnarchiver unarchiveObjectWithData:serialized_location_data];
#endif
    
    if (kDebugLevel > 0)
        NSLog(@"Principal:fetchLocationData: extracted lat: %.6f, lon: %.6f, course: %.6f, date: %s.", location.coordinate.latitude, location.coordinate.longitude, location.course, [[location.timestamp description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // TODO(aka) We may want to ignore this fetch (or replace our last) if the distance between this and our last coordinate is within some distance filter.  (Note, however, that the consumer knows nothing of the provider's current distance filter ... so, we're just going to look at the timestamp.
    
    // If the date of this fetch and our most recent is different, add the new location.
    
    if ([_history_log count] > 0) {
        CLLocation* last_location = [_history_log objectAtIndex:0];
        if (![last_location.timestamp isEqualToDate:location.timestamp])
            [self addLocation:location];
    } else {
        [self addLocation:location];
    }
    
    // Finally, update our *last fetch* timestamp.
    if (_last_fetch == nil)
        _last_fetch = [[NSDate alloc] init];
    else
        _last_fetch = [[NSDate alloc] init];  // hell with it, just get a new date
    
    return nil;
}

- (NSString*) downloadLocationData:(NSString *__autoreleasing *)encrypted_location_data_b64 {
    if (kDebugLevel > 2)
        NSLog(@"Principal:downloadLocationData: called.");
    
    if (_file_store == nil) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Principal:downloadLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    NSLog(@"Principal:downloadLocationData: TODO(aka) We may want to use NSURLConnector here, well, actually up in ConsumerMasterViewController, to make our fetches asynchronus.");
    
    /*  TODO(aka) NSURLConnection way ...
     // Create the request.
     NSURLRequest* theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
     
     // Create the connection.
     NSURLConnection* theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
     if (theConnection) {
     // Create the NSMutableData to hold the received data.
     // receivedData is an instance variable declared elsewhere.
     
     receivedData = [[NSMutableData data] retain];
     } else {
     // Inform the user that the connection failed.
     }
     */
    
    // Build the URI using the file-store, the *key-hash* directory and location-data filename.
    
#if (FILE_STORE_USE_NSURL == 1)
    NSURL* uri = _file_store;
#else
    NSURL* uri = [PersonalDataController absoluteURLFileStore:_file_store withBucket:key_hash];
#endif
    NSError *status = nil;
    *encrypted_location_data_b64 = [[NSString alloc] initWithContentsOfURL:uri encoding:[NSString defaultCStringEncoding] error:&status];
    if (status) {
        NSString* description = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Principal:downloadLocationData: %s, file-store: %s, initWithContentsOfURL() failed: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[uri absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [description cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"Principal:downloadLocationData: %s, uri: %s, fetched base64 data: %s.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[uri absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [*encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}
#endif

#pragma mark - ProviderMaster VC utilities

#pragma mark - Debugging routines

// I believe this routine is *only* used for debugging.
- (NSString*) serialize {
    if (kDebugLevel > 2)
        NSLog(@"Principal:serialize: called.");
    
    NSString* absolute_string = [[NSString alloc] init];
    
    if (_identity)
        absolute_string = [absolute_string stringByAppendingString:_identity];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    absolute_string = [absolute_string stringByAppendingString:[PersonalDataController serializeDeposit:_deposit]];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
#if (FILE_STORE_USE_NSURL == 1)
    if (_key_bundle_url != nil)
        absolute_string = [absolute_string stringByAppendingString:[_key_bundle_url absoluteString]];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
#else
    absolute_string = [absolute_string stringByAppendingString:[PersonalDataController absoluteStringFileStore:_file_store]];
#endif
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    if (_key != nil)
        absolute_string = [absolute_string stringByAppendingString:[_key base64EncodedString]];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    if (_history_log != nil) {
        if ([_history_log count] > 0) {
            for (int i = 0; i < [_history_log count]; ++i) {
                absolute_string = [absolute_string stringByAppendingFormat:@"[%d] ", i];
                CLLocation* location = [_history_log objectAtIndex:i];
                absolute_string = [absolute_string stringByAppendingString:location.description];
                if (i < [_history_log count])
                    absolute_string = [absolute_string stringByAppendingFormat:@", "];
            }
        } else {
            absolute_string = [absolute_string stringByAppendingFormat:@"0"];
        }
    } else {
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    }
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    if (_last_fetch != nil)
        absolute_string = [absolute_string stringByAppendingString:[_last_fetch description]];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    absolute_string = [absolute_string stringByAppendingFormat:@"%f", [_frequency floatValue]];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    absolute_string = [absolute_string stringByAppendingFormat:@"%d", _is_focus];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    absolute_string = [absolute_string stringByAppendingFormat:@"%@", _policy];
    
    return absolute_string;
}

@end
