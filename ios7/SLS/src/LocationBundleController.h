//
//  LocationBundleController.h
//  SLS
//
//  Created by Andrew K. Adams on 1/24/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define LOCATION_BUNDLE_EXTENSION ".lb"


@interface LocationBundleController : NSObject <NSCoding, NSCopying>

#pragma mark - Local variables
@property (copy, nonatomic) CLLocation* location;
@property (copy, nonatomic) NSNumber* time_stamp;
@property (copy, nonatomic) NSString* signature;       // signature over serialized location and timestamp

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management
- (NSString*) build:(CLLocation*)location privateKeyRef:(SecKeyRef)private_key_ref;
- (NSString*) generateWithString:(NSString*)serialized_str;
- (NSString*) serialize;

@end
