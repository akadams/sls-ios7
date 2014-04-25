//
//  LocationBundleController.m
//  SLS
//
//  Created by Andrew K. Adams on 1/24/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <sys/time.h>
#include <stdlib.h>

#import "NSData+Base64.h"

#import "PersonalDataController.h"
#import "PolicyController.h"
#import "LocationBundleController.h"

static const int kDebugLevel = 1;

static const char kLocationDelimiter = LOCATION_BUNDLE_LOCATION_DELIMITER;
static const char kComponentDelimiter = LOCATION_BUNDLE_COMPONENT_DELIMITER;


@implementation LocationBundleController

#pragma mark - Local variables

@synthesize serialized_location = _serialized_location;
@synthesize time_stamp = _time_stamp;
@synthesize signature = _signature;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:init: called.");
    
    if (self = [super init]) {
        _serialized_location = nil;
        _time_stamp = 0;
        _signature = nil;
    }
    
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:copywithZone: called.");
    
    LocationBundleController* tmp_controller = [[LocationBundleController alloc] init];
    tmp_controller.serialized_location = _serialized_location;
    tmp_controller.time_stamp = _time_stamp;
    tmp_controller.signature = _signature;
    
    return tmp_controller;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _serialized_location = [decoder decodeObjectForKey:@"location"];
        _time_stamp = [decoder decodeObjectForKey:@"time-stamp"];
        _signature = [decoder decodeObjectForKey:@"signature"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:encodeWithCoder: called.");
    
    [encoder encodeObject:_serialized_location forKey:@"location"];
    [encoder encodeObject:_time_stamp forKey:@"time-stamp"];
    [encoder encodeObject:_signature forKey:@"signature"];
}

#pragma mark - Data management

- (NSString*) build:(CLLocation*)location privateKeyRef:(SecKeyRef)private_key_ref policy:(NSNumber*)policy {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:generate:privateKeyRef: called.");
    
    if (location == nil)
        return @"LocationBundleController:generate: location is nil.";
    
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    double course = location.course;
    double altitude = location.altitude;
    NSDate* location_time = location.timestamp;
    
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:generate: description: %s, latitude %+.7f, longitude %+.7f, course: %+.7f.", [location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], latitude, longitude, course);
    
    switch ([policy intValue]) {
        case PC_PRECISION_IDX_STATE :  // 0 decimal places (110km)
        {
            NSLog(@"LocationBundleController:generate: XXX before applying state mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);
            
            // HACK: Attempt at quickly diffusing a double's precision.
            static uint64_t mask = 0xFFFF000000000000;
            double* lon_ptr = &longitude;
            double* lat_ptr = &latitude;
            uint64_t diffused_lon = (*(uint64_t*)lon_ptr) & mask;
            uint64_t diffused_lat = (*(uint64_t*)lat_ptr) & mask;
            longitude = *(double*)&diffused_lon;
            latitude = *(double*)&diffused_lat;
        }
            break;

        case PC_PRECISION_IDX_COUNTY:  // 1 decimal place (11km)
        {
            NSLog(@"LocationBundleController:generate: XXX before applying county mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);
            
            // HACK: Attempt at quickly diffusing a double's precision.
            static uint64_t mask = 0xFFFFFE0000000000;
            double* lon_ptr = &longitude;
            double* lat_ptr = &latitude;
            uint64_t diffused_lon = (*(uint64_t*)lon_ptr) & mask;
            uint64_t diffused_lat = (*(uint64_t*)lat_ptr) & mask;
            longitude = *(double*)&diffused_lon;
            latitude = *(double*)&diffused_lat;
        }
            break;
        
        case PC_PRECISION_IDX_CITY :   // 2 decimal places (1.1km)
        {
            NSLog(@"LocationBundleController:generate: XXX before applying city mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);
            
            // HACK: Attempt at quickly diffusing a double's precision.
            static uint64_t mask = 0xFFFFFFC000000000;
            double* lon_ptr = &longitude;
            double* lat_ptr = &latitude;
            uint64_t diffused_lon = (*(uint64_t*)lon_ptr) & mask;
            uint64_t diffused_lat = (*(uint64_t*)lat_ptr) & mask;
            longitude = *(double*)&diffused_lon;
            latitude = *(double*)&diffused_lat;
        }
            break;
        
        case PC_PRECISION_IDX_NEIGHBORHOOD :  // 3 decimal places (110m)
        {
            NSLog(@"LocationBundleController:generate: XXX before applying neighborhood mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);
            
            // HACK: Attempt at quickly diffusing a double's precision.
            static uint64_t mask = 0xFFFFFFF800000000;
            double* lon_ptr = &longitude;
            double* lat_ptr = &latitude;
            uint64_t diffused_lon = (*(uint64_t*)lon_ptr) & mask;
            uint64_t diffused_lat = (*(uint64_t*)lat_ptr) & mask;
            longitude = *(double*)&diffused_lon;
            latitude = *(double*)&diffused_lat;
        }
            break;
        
        case PC_PRECISION_IDX_BUILDING :  // 4 decimal places (11m)
        {
            NSLog(@"LocationBundleController:generate: XXX before applying building mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);
            
            // HACK: Attempt at quickly diffusing a double's precision.
            static uint64_t mask = 0xFFFFFFFF00000000;
            double* lon_ptr = &longitude;
            double* lat_ptr = &latitude;
            uint64_t diffused_lon = (*(uint64_t*)lon_ptr) & mask;
            uint64_t diffused_lat = (*(uint64_t*)lat_ptr) & mask;
            longitude = *(double*)&diffused_lon;
            latitude = *(double*)&diffused_lat;
        }
            break;
        
        case PC_PRECISION_IDX_EXACT :  // 5 decimal places (1.1m)
            break;  // we don't want to muck with the precision
            
        default :
        {
            NSString* err_msg = [NSString stringWithFormat:@"LocationBundleController:generate: unknown policy: %d.", [policy intValue]];
            return err_msg;
        }
    }

    if (kDebugLevel > 0)
        NSLog(@"LocationBundleController:generate: DEBUG: After applying mask, latitude %+.7f, longitude %+.7f.", latitude, longitude);

    // TODO(aka) We need to add accuracy and speed!
    _serialized_location = [[NSString alloc] initWithFormat:@"%+.7f%c%+.7f%c%+.7f%c%+.6f", latitude, kLocationDelimiter, longitude, kLocationDelimiter, course, kLocationDelimiter, altitude];
    
    // Convert NSDate within CLLocation to time_t, then convert that to our NSNumber.
    time_t utc = (time_t)[location_time timeIntervalSince1970];
    _time_stamp = [[NSNumber alloc] initWithLong:utc];
    
    // Generate the signature over the concatination of our serialized location & time stamp.
    NSString* signature = nil;
    
    // Our attempt at an O/S agnostic framing/encoding scheme for the location, course and timestamp!
    NSString* two_tuple = [[NSString alloc] initWithFormat:@"%s%ld", [_serialized_location cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];  // note, lack of kMsgDelimiter
    NSData* hash = [PersonalDataController hashSHA256StringToData:two_tuple];
    NSString* error_msg = [PersonalDataController signHashData:hash privateKeyRef:private_key_ref signedHash:&signature];
    if (error_msg != nil)
        return error_msg;
    
    if (kDebugLevel > 1)
        NSLog(@"LocationBundleController:generate: two tuple: %@, signature: %@.", two_tuple, signature);

    _signature = signature;
    
    return nil;
}

- (NSString*) generateWithString:(NSString*)serialized_str {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:generateWithString: called.");
    
    if (serialized_str == nil || [serialized_str length] == 0)
        return @"LocationBundleController:generateWithString: serialized string empty or nil!";
    
    NSArray* components = [serialized_str componentsSeparatedByString:[NSString stringWithFormat:@"%c", kComponentDelimiter]];
    if ([components count] != 3)
        return @"LocationBundleController:generateWithString: serialized string does not have three commponent!";
    
    _serialized_location = [components objectAtIndex:0];
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    _time_stamp = [formatter numberFromString:[components objectAtIndex:1]];
    
    _signature = [components objectAtIndex:2];

    return nil;
}

- (NSString*) serialize {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:serialize: called.");
    
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:generate: serialized loc: %@, time stamp: %@, sig: %@.", _serialized_location, _time_stamp, _signature);
    
    NSString* location_bundle = [[NSString alloc] initWithFormat:@"%s%c%ld%c%s", [_serialized_location cStringUsingEncoding:[NSString defaultCStringEncoding]], kComponentDelimiter, [_time_stamp longValue], kComponentDelimiter, [_signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    return location_bundle;
}

- (BOOL) verifySignature:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleControler:verifySignature: called.");
    
    // Verify our signature over the hash of the concatenation of the key & time stamp.
    NSString* two_tuple = [[NSString alloc] initWithFormat:@"%s%ld", [_serialized_location cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];  // note, lack of kMsgDelimiter
    NSData* hash = [PersonalDataController hashSHA256StringToData:two_tuple];
    
    return [PersonalDataController verifySignatureData:hash secKeyRef:public_key_ref signature:[NSData dataFromBase64String:_signature]];
}

- (CLLocation*) generateCLLocation {
    if (kDebugLevel > 4)
        NSLog(@"LocationBundleController:generateCLLocation: called.");
    
    // Build CLLocation.
    NSArray* components = [_serialized_location componentsSeparatedByString:[NSString stringWithFormat:@"%c", kLocationDelimiter]];
    if ([components count] < 4)
        NSLog(@"LocationBundleController:generateCLLocation: ERROR: TODO(aka) insufficient components within serialized location: %lu.", (unsigned long)[components count]);
    
    double latitude = strtod([[components objectAtIndex:0] cStringUsingEncoding:[NSString defaultCStringEncoding]], (char**)NULL);
    double longitude = strtod([[components objectAtIndex:1] cStringUsingEncoding:[NSString defaultCStringEncoding]], (char**)NULL);
    double course = strtod([[components objectAtIndex:2] cStringUsingEncoding:[NSString defaultCStringEncoding]], (char**)NULL);
    double altitude = strtod([[components objectAtIndex:3] cStringUsingEncoding:[NSString defaultCStringEncoding]], (char**)NULL);
    double accuracy = 1.0;  // for now, just default to best (it's in meters)
    double speed = 0.0;  // again, for now, just make this empty
    CLLocationCoordinate2D coordinate;
	coordinate.latitude = latitude;
	coordinate.longitude = longitude;
    
    CLLocation* location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude horizontalAccuracy:accuracy verticalAccuracy:accuracy course:course speed:speed timestamp:[NSDate dateWithTimeIntervalSince1970:[_time_stamp intValue]]];
    
    if (kDebugLevel > 1)
        NSLog(@"LocationBundleController:generateCLLocation: generated %@.", location.description);
    
    return location;
}

@end
