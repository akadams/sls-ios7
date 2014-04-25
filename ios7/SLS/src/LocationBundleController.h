//
//  LocationBundleController.h
//  SLS
//
//  Created by Andrew K. Adams on 1/24/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define LOCATION_BUNDLE_EXTENSION ".lb"            // TODO(aka) I think this is deprecated
#define LOCATION_BUNDLE_LOCATION_DELIMITER ':'
#define LOCATION_BUNDLE_COMPONENT_DELIMITER ';'


@interface LocationBundleController : NSObject <NSCoding, NSCopying>
// NSCopying is needed because we use LocationBundleController as a key in a NSDictionary!  TODO(aka) We do?

#pragma mark - Local variables
@property (copy, nonatomic) NSString* serialized_location;
@property (copy, nonatomic) NSNumber* time_stamp;
@property (copy, nonatomic) NSString* signature;       // signature over serialized location and timestamp

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management
- (NSString*) build:(CLLocation*)location privateKeyRef:(SecKeyRef)private_key_ref policy:(NSNumber*)policy;
- (NSString*) generateWithString:(NSString*)serialized_str;
- (NSString*) serialize;
- (BOOL) verifySignature:(SecKeyRef)public_key_ref;
- (CLLocation*) generateCLLocation;

@end
