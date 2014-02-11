//
//  LocationBundleController.m
//  SLS
//
//  Created by Andrew K. Adams on 1/24/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <sys/time.h>

#import "PersonalDataController.h"
#import "LocationBundleController.h"

static const int kDebugLevel = 1;
static const char kMsgDelimiter = ' ';  // for now, let's make it whitespace


@implementation LocationBundleController

#pragma mark - Local variables

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:init: called.");
    
    if (self = [super init]) {
        _location = nil;
        _time_stamp = 0;
        _signature = nil;
    }
    
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:copywithZone: called.");
    
    LocationBundleController* tmp_controller = [[LocationBundleController alloc] init];
    tmp_controller.location = _location;
    tmp_controller.time_stamp = _time_stamp;
    tmp_controller.signature = _signature;
    
    return tmp_controller;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _location = [decoder decodeObjectForKey:@"encrypted-key"];
        _time_stamp = [decoder decodeObjectForKey:@"time-stamp"];
        _signature = [decoder decodeObjectForKey:@"signature"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:encodeWithCoder: called.");
    
    [encoder encodeObject:_location forKey:@"encrypted-key"];
    [encoder encodeObject:_time_stamp forKey:@"time-stamp"];
    [encoder encodeObject:_signature forKey:@"signature"];
}

#pragma mark - Data management

- (NSString*) build:(CLLocation*)location privateKeyRef:(SecKeyRef)private_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:generate:privateKeyRef: called.");
    
    if (location == nil)
        return @"LocationBundleController:generate: location is nil.";
    
    _location = location;  // grab CLLocation
    
    // Convert NSDate within CLLocation to time_t, then convert that to our NSNumber.
    time_t utc = (time_t)[_location.timestamp timeIntervalSince1970];
    _time_stamp = [[NSNumber alloc] initWithLong:utc];
    
    // Generate the signature over the concatination of our serialized location & time stamp.
    NSString* signature = nil;
    
#if 1
    // Our attempt at an O/S agnostic framing/encoding scheme for the location, course and timestamp!
    double latitude = _location.coordinate.latitude;
    double longitude = _location.coordinate.longitude;
    double course = _location.course;
    
    if (kDebugLevel > 1)
        NSLog(@"LocationBundleController:generate: description: %s, latitude %+.6f, longitude %+.6f, course: %+.6f\n", [_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], latitude, longitude, course);
    
    NSString* location_str = [[NSString alloc] initWithFormat:@"%+.6f:%+.6f:%+.6f", latitude, longitude, course];
    NSString* two_tuple = [[NSString alloc] initWithFormat:@"%s%ld", [location_str cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];  // note, lack of kMsgDelimiter
    NSData* hash = [PersonalDataController hashSHA256StringToData:two_tuple];
    NSString* error_msg = [PersonalDataController signHashData:hash privateKeyRef:private_key_ref signedHash:&signature];
    if (error_msg != nil)
        return error_msg;
    
    if (kDebugLevel > 0)
        NSLog(@"LocationBundleController:generate: two tuple: %@, signature: %@.", two_tuple, signature);

    // XXX NSData* serialized_location_data = [location_str dataUsingEncoding:[NSString defaultCStringEncoding]];
#else
    // For simplicity, we are going to serialize the CLLocation object (as it conforms to NSCoding).
    
    // XXX TODO(aka) But how do we add the time stamp for the signature?
    // XXX NSData* serialized_location_data = [NSKeyedArchiver archivedDataWithRootObject:location];
#endif
    
    _signature = signature;
    
    return nil;
}

// TODO(aka) I think the following two routines are deprecated, until we move to O/S agnostic ways in storing history log.
- (NSString*) generateWithString:(NSString*)serialized_str {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:generateWithString: called.");
    
    if (serialized_str == nil || [serialized_str length] == 0)
        return @"LocationBundleController:generateWithString: serialized string empty or nil!";
    
    NSArray* components = [serialized_str componentsSeparatedByString:[NSString stringWithFormat:@"%c", kMsgDelimiter]];
    if ([components count] != 3)
        return @"LocationBundleController:generateWithString: serialized string does not have three commponent!";
    
    _location = [components objectAtIndex:0];
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    _time_stamp = [formatter numberFromString:[components objectAtIndex:1]];
    
    _signature = [components objectAtIndex:2];
    
    return nil;
}

- (NSString*) serialize {
    if (kDebugLevel > 2)
        NSLog(@"LocationBundleController:serialize: called.");
    
    double latitude = _location.coordinate.latitude;
    double longitude = _location.coordinate.longitude;
    double course = _location.course;
    
    if (kDebugLevel > 1)
        NSLog(@"LocationBundleController:generate: description: %s, latitude %+.6f, longitude %+.6f, course: %+.6f\n", [_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], latitude, longitude, course);
    
    NSString* location_bundle = [[NSString alloc] initWithFormat:@"%+.6f%c%+.6f%c%+6.f%c%ld%c%s", latitude, kMsgDelimiter, longitude, kMsgDelimiter, course, kMsgDelimiter, [_time_stamp longValue], kMsgDelimiter, [_signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    return location_bundle;
}

@end
