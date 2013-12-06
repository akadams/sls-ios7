//
//  Provider.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "Provider.h"
#import "PersonalDataController.h"
#import "NSData+Base64.h"
#import "security-defines.h"


static const int kDebugLevel = 1;

static const char* kStringDelimiter = ":";
static const int kInitialLocationListSize = 5;
static const float kDefaultFrequency = 300.0;       // 5 minutes between fetches
static const char* kPublicKeyExt = KC_QUERY_KEY_PUBLIC_KEY_EXT;


@interface Provider ()
- (void) setPublicKeyRef:(SecKeyRef)public_key_ref;
@end

@implementation Provider

@synthesize identity = _identity;
@synthesize identity_hash = _identity_hash;
@synthesize file_store = _file_store;
@synthesize mobile_number = _mobile_number;
@synthesize email_address = _email_address;
@synthesize key = _key;
@synthesize locations = _locations;
@synthesize last_fetch = _last_fetch;
@synthesize frequency = _frequency;
@synthesize is_focus = _is_focus;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"Provider:init: called.");
    
    if (self = [super init]) {
        _identity = nil;
        _identity_hash = nil;
        _file_store = nil;
        _mobile_number = nil;
        _email_address = nil;
        _key = nil;
        _locations = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
        _last_fetch = nil;
        _frequency = [[NSNumber alloc] initWithFloat:kDefaultFrequency];
        _is_focus = false;
        publicKeyRef = NULL;
  }
    
    return self;
}

- (id) initWithIdentity:(NSString*)identity {
    if (kDebugLevel > 2)
        NSLog(@"Provider:initWithIdentity: called.");
    
    self = [super init];
    if (self) {
        _identity = identity;
        _identity_hash = nil;
        _file_store = nil;
        _mobile_number = nil;
        _email_address = nil;
        _key = nil;
        _locations = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
        _last_fetch = nil;
        _frequency = [[NSNumber alloc] initWithFloat:kDefaultFrequency];
        _is_focus = false;
        publicKeyRef = NULL;
       
        return self;
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"Provider:copyWithZone: called.");
    
    Provider* tmp_controller = [[Provider alloc] init];
    if (_identity)
        tmp_controller.identity = _identity;
    
    if (_identity_hash)
        tmp_controller.identity_hash = _identity_hash;
    
    if (_file_store)
        tmp_controller.file_store = _file_store;
    
    if (_mobile_number)
        tmp_controller.mobile_number = _mobile_number;
    
    if (_email_address)
        tmp_controller.email_address = _email_address;
    
    if (_locations)
        tmp_controller.locations = _locations;
    
    if (_key)
        tmp_controller.key = _key;
    
    if (_last_fetch)
        tmp_controller.last_fetch = _last_fetch;
    
    if (_frequency)
        tmp_controller.frequency = _frequency;
    
    tmp_controller.is_focus = _is_focus;
    
    if (publicKeyRef)
        tmp_controller.publicKeyRef = publicKeyRef;
    
    return tmp_controller;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"Provider:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _identity = [decoder decodeObjectForKey:@"identity"];
        _identity_hash = [decoder decodeObjectForKey:@"identity-hash"];
       _file_store = [decoder decodeObjectForKey:@"file-store"];
        _key = [decoder decodeObjectForKey:@"symmetric-key"];
        _mobile_number = [decoder decodeObjectForKey:@"mobile-number"];
        _email_address = [decoder decodeObjectForKey:@"email-address"];
        _locations = [decoder decodeObjectForKey:@"location-list"];
        _last_fetch = [decoder decodeObjectForKey:@"last-fetch"];        
        _frequency = [decoder decodeObjectForKey:@"frequency"];
        _is_focus = [decoder decodeBoolForKey:@"is-focus"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"Provider:encodeWithCoder: called.");
    
    [encoder encodeObject:_identity forKey:@"identity"];
    [encoder encodeObject:_identity_hash forKey:@"identity-hash"];
    [encoder encodeObject:_file_store forKey:@"file-store"];
    [encoder encodeObject:_key forKey:@"symmetric-key"];
    [encoder encodeObject:_mobile_number forKey:@"mobile-number"];
    [encoder encodeObject:_email_address forKey:@"email-address"];
    [encoder encodeObject:_locations forKey:@"location-list"];
    [encoder encodeObject:_last_fetch forKey:@"last-fetch"];
    [encoder encodeObject:_frequency forKey:@"frequency"];
    [encoder encodeBool:_is_focus forKey:@"is-focus"];
}

#if (PROVIDER_USE_URL == 1)
- (void) setFile_store:(NSURL*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"Provider:setFile_store: called.");
    
    _file_store = file_store;
}
#else
- (void) setFile_store:(NSMutableDictionary*)file_store {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_file_store != file_store) {
        _file_store = [file_store mutableCopy];
    }
}
#endif

- (void)setLocations:(NSMutableArray*)locations {
    if (kDebugLevel > 2)
        NSLog(@"Provider:setLocations: called.");
    
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_locations != locations) {
        _locations = [locations mutableCopy];
    }
}

- (SecKeyRef) publicKeyRef {
    if (kDebugLevel > 2)
        NSLog(@"Provider:publicKeyRef: called.");
    
    if (publicKeyRef != NULL)
        return publicKeyRef;
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity_str = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity_str dataUsingEncoding:[NSString defaultCStringEncoding]];    
    NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (error_msg != nil)
        NSLog(@"Provider:publicKeyRef: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return publicKeyRef;
}

- (void) setPublicKeyRef:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"Provider:setPublicKeyRef: called.");
    
    // Note, the key-chain will be updated in setPublicKey().
    publicKeyRef = public_key_ref;   
}

- (NSData*) getPublicKey {
    if (kDebugLevel > 2)
        NSLog(@"Provider:getPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];    
    NSData* public_key = nil;
    NSString* error_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
    if (error_msg != nil)
        NSLog(@"Provider:getPublicKey: TODO(aka) queryKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return public_key;
}

- (void) setPublicKey:(NSData*)public_key {
    if (kDebugLevel > 2)
        NSLog(@"Provider:setPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];    
    
    if (publicKeyRef != NULL) {
        // Delete the key we currently have in the key-chain.
        [PersonalDataController deleteKeyRef:application_tag];
        publicKeyRef = NULL;
    }
    
    // Add the new key to our key-chain.
    NSString* error_msg = [PersonalDataController saveKeyData:public_key withTag:application_tag];
    if (error_msg != nil)
        NSLog(@"Provider:setPublicKey: TODO(aka) saveKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // And get a reference to the newly added key.
    error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (error_msg != nil)
        NSLog(@"Provider:setPublicKey: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (void) addLocation:(CLLocation*)location {
    if (kDebugLevel > 2)
        NSLog(@"Provider:addLocation: called.");
    
    if (_locations == nil)
        _locations = [[NSMutableArray alloc] initWithCapacity:kInitialLocationListSize];
    
    int count = (int)[_locations count];  // get how many we start with
    
    if (kDebugLevel > 0)
        NSLog(@"Provider:addLocation: adding location: %s to %d count array (max is %d).", [location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], count, kInitialLocationListSize);
    
    [_locations insertObject:location atIndex:0];
    
    // Make sure our list stays at our maximum size.
    if (count >= kInitialLocationListSize) {
        NSString* description = [[_locations objectAtIndex:count] description];
        if (kDebugLevel > 0)
            NSLog(@"Provider:addLocation: removing location: %s, for count (%d) reached max: %d.", [description cStringUsingEncoding:[NSString defaultCStringEncoding]], count, kInitialLocationListSize);
        
        [_locations removeObjectAtIndex:count];
        
        if (kDebugLevel > 0)
            NSLog(@"Provider:addLocation: array downsized to: %lu.", (unsigned long)[_locations count]);
    }
}

- (NSTimeInterval) getTimeIntervalToNextFetch {
    if (kDebugLevel > 2)
        NSLog(@"Provider:getTimeIntervalToNextFetch: called.");
    
    if (_last_fetch == nil)
        return 0.0;
    
    // Get our *banked* wait time.
    NSTimeInterval wait_time = abs([_last_fetch timeIntervalSinceNow]);
    
    if (kDebugLevel > 0)
        NSLog(@"Provider:getTimeIntervalToNextFetch: comparing wait time: %f, to our frequency: %f.", wait_time, [_frequency doubleValue]);
    
    // Return how long we've waited (subtracted from our frequency).
    if (wait_time >= [_frequency doubleValue])
        return 0.0;  // we've waited long enough
    else
        return ([_frequency doubleValue] - wait_time);
}

// I believe this routine is *only* used for debugging.
- (NSString*) absoluteString {
    if (kDebugLevel > 2)
        NSLog(@"Provider:absoluteString: called.");
    
    NSString* absolute_string = [[NSString alloc] init];
    
    if (_identity)
        absolute_string = [absolute_string stringByAppendingString:_identity];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
#if (PROVIDER_USE_URL == 1) 
    if (_file_store != nil)
        absolute_string = [absolute_string stringByAppendingString:[_file_store absoluteString]];
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
    
    if (_locations != nil) {
        if ([_locations count] > 0) {
            for (int i = 0; i < [_locations count]; ++i) {
                absolute_string = [absolute_string stringByAppendingFormat:@"[%d] ", i];
                CLLocation* location = [_locations objectAtIndex:i];
                absolute_string = [absolute_string stringByAppendingString:location.description];
                if (i < [_locations count])
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
    
    return absolute_string;
}

- (NSString*) fetchLocationData {
    if (kDebugLevel > 2)
        NSLog(@"Provider:fetchLocationData: called.");
    
    if (kDebugLevel > 2)
        NSLog(@"Provider:fetchLocationData: checking file-store for provider: %s.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
#if (PROVIDER_USE_URL == 1)
    if (_file_store == nil) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* error_msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }
#else
    if (![PersonalDataController isFileStoreValid:_file_store]) {
        NSLog(@"Provider:fetchLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]); 
        return;  // haven't received a file-store yet
    }
#endif
    
    if (_key == nil || 
        ([_key length] == 0)) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* error_msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: ERROR: Provider %s has a file store, but no symmetric key!", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }
    
    // Fetch the location data.
    NSString* encrypted_location_data_b64 = nil;
    NSString* error_msg = [self downloadLocationData:&encrypted_location_data_b64];
    if (error_msg != nil) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: %s", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
    if (kDebugLevel > 2)
        NSLog(@"Provider:fetchLocationData: file-store: %s, fetched base64 data: %s.", [[_file_store absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Unencrypt the location data.
    NSData* encrypted_location_data = [NSData dataFromBase64String:encrypted_location_data_b64];
    NSData* serialized_location_data = nil;
    error_msg = [PersonalDataController decryptData:encrypted_location_data bundleSize:[encrypted_location_data length] symmetricKey:_key decryptedData:&serialized_location_data];
    if (error_msg) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: %s: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }   
    
    if (kDebugLevel > 0)
        NSLog(@"Provider:fetchLocationData: serialized location data is %lub.", (unsigned long)[serialized_location_data length]);

    // We have this test, so we don't inadvertedly try to de-serialize something that wasn't serialized by NSKeyArchiver.
    
    if ([serialized_location_data length] != 724) {
        _last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: fetched serialized data for identity: %s is not 724b, so skipping.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
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
        NSString* error_msg = [[NSString alloc] initWithFormat:@"Provider:fetchLocationData: unable to parse: %s.", location_data_str];
        return error_msg;
    }
#else        
    // For simplicity, we are going to serialize the CLLocation object (as it conforms to NSCoding).
    CLLocation* location = [NSKeyedUnarchiver unarchiveObjectWithData:serialized_location_data];
#endif
    
    if (kDebugLevel > 0)
        NSLog(@"Provider:fetchLocationData: extracted lat: %.6f, lon: %.6f, course: %.6f, date: %s.", location.coordinate.latitude, location.coordinate.longitude, location.course, [[location.timestamp description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // TODO(aka) We may want to ignore this fetch (or replace our last) if the distance between this and our last coordinate is within some distance filter.  (Note, however, that the consumer knows nothing of the provider's current distance filter ... so, we're just going to look at the timestamp.
    
    // If the date of this fetch and our most recent is different, add the new location.
    
    if ([_locations count] > 0) {
        CLLocation* last_location = [_locations objectAtIndex:0];
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
        NSLog(@"Provider:downloadLocationData: called.");
    
    if (_file_store == nil) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"Provider:downloadLocationData: file-store not set for: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }
    
    NSLog(@"Provider:downloadLocationData: TODO(aka) We may want to use NSURLConnector here, well, actually up in ConsumerMasterViewController, to make our fetches asynchronus.");
    
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
    
#if (PROVIDER_USE_URL == 1)
    NSURL* uri = _file_store;
#else
    NSURL* uri = [PersonalDataController absoluteURLFileStore:_file_store withBucket:key_hash];
#endif
    NSError *status = nil;
    *encrypted_location_data_b64 = [[NSString alloc] initWithContentsOfURL:uri encoding:[NSString defaultCStringEncoding] error:&status];
    if (status) {
        NSString* description = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        NSString* error_msg = [[NSString alloc] initWithFormat:@"Provider:downloadLocationData: %s, file-store: %s, initWithContentsOfURL() failed: %s", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[uri absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [description cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"Provider:downloadLocationData: %s, uri: %s, fetched base64 data: %s.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[uri absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [*encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}

- (BOOL) isEqual:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"Provider:isEqual: called.");
    
    if (provider == nil || provider.identity == nil || [provider.identity length] == 0) {
        NSLog(@"Provider:isEqual: SYSTEM_ERROR: provider or provider's idenity is nil!");
        return false;
    }
    
    if (_identity == nil || [_identity length] == 0) {
        NSLog(@"Provider:isEqual: SYSTEM_ERROR: _idenity is nil!");
        return false;
    }
    
    if (![_identity isEqual:provider.identity])
        return false;
    
    // For now, we only care about the identities.
    return true;
}

@end
