//
//  CoreLocationController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/10/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "CoreLocationController.h"
#import "PersonalDataController.h"        // for saving/loading state methods


static const int kDebugLevel = 1;

static const char* kPowerToggleFilename = "power-saving-toggle.txt";
static const char* kSharingToggleFilename = "location-sharing-toggle.txt";
static const char* kDistanceFilterFilename = "distance-filter.txt";

static const CLLocationDistance kDefaultDistanceFilter = 50.0;  // 50 meters

@implementation CoreLocationController

#pragma mark - Local variables
@synthesize locationMgr = _locationMgr;
@synthesize location_sharing_toggle = _location_sharing_toggle;
@synthesize power_saving_toggle = _power_saving_toggle;
@synthesize distance_filter = _distance_filter;
@synthesize delegate = _delegate;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:init: called.");
    
	self = [super init];
    
	if(self != nil) {
		_locationMgr = [[CLLocationManager alloc] init];
		_locationMgr.delegate = self;  // set the CLLocationManager delegate as ourselves
        _location_sharing_toggle = false;
        _power_saving_toggle = false;
        _distance_filter = kDefaultDistanceFilter;
        _delegate = nil;
	}
    
	return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:copywithZone: called.");
    
    CoreLocationController* tmp_controller = [[CoreLocationController alloc] init];
    tmp_controller.locationMgr = _locationMgr;
    //tmp_controller.locationMgr.delegate = _locationMgr.delegate;
    tmp_controller.location_sharing_toggle = _location_sharing_toggle;
    tmp_controller.power_saving_toggle = _power_saving_toggle;
    tmp_controller.distance_filter = _distance_filter;
    tmp_controller.delegate = _delegate;
    
    return tmp_controller;
}

- (void) saveState {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:saveState: called.");
    
    NSString* sharing_str = [[NSString alloc] initWithFormat:@"%d", _location_sharing_toggle];
    [PersonalDataController saveState:[NSString stringWithCString:kSharingToggleFilename encoding:[NSString defaultCStringEncoding]] string:sharing_str];
    
    NSString* power_str = [[NSString alloc] initWithFormat:@"%d", _power_saving_toggle];
    [PersonalDataController saveState:[NSString stringWithCString:kPowerToggleFilename encoding:[NSString defaultCStringEncoding]] string:power_str];
    
    NSString* filter_str = [[NSString alloc] initWithFormat:@"%f", _distance_filter];
    [PersonalDataController saveState:[NSString stringWithCString:kDistanceFilterFilename encoding:[NSString defaultCStringEncoding]] string:filter_str];
}

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:loadState: called.");
    
    // Get our sharing and power saving toggles (if they exist), and our distance filter.
    NSString* tmp_string = [PersonalDataController loadStateString:[NSString stringWithCString:kSharingToggleFilename encoding:[NSString defaultCStringEncoding]]];
    if (tmp_string != nil)
        _location_sharing_toggle = [tmp_string boolValue];
    
    tmp_string = [PersonalDataController loadStateString:[NSString stringWithCString:kPowerToggleFilename encoding:[NSString defaultCStringEncoding]]];
    if (tmp_string != nil)
        _power_saving_toggle = [tmp_string boolValue];
    
    tmp_string = [PersonalDataController loadStateString:[NSString stringWithCString:kDistanceFilterFilename encoding:[NSString defaultCStringEncoding]]];
    if (tmp_string != nil)
        _distance_filter = [tmp_string floatValue];
}

- (void) enableLocationGathering {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:enableLocationGathering: called.");

    // Get permission to collect location updates.
    /*
    if ([_locationMgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationMgr requestWhenInUseAuthorization];
    }
    */
    if ([_locationMgr respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationMgr requestAlwaysAuthorization];
    }
    
    if (_power_saving_toggle) {
        if (kDebugLevel > 0)
            NSLog(@"CoreLocationController:enableLocationGathering: starting low power gathering.");
        
        // Start grabbing location data.
        [_locationMgr startMonitoringSignificantLocationChanges];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"CoreLocationController:enableLocationGathering: starting high frequency gathering.");
        
        // Start grabbing location data.
        [_locationMgr setDistanceFilter:_distance_filter];
        [_locationMgr startUpdatingLocation];
    }

#if 0
    // XXX Do we need this, or are we getting course from our in location updates.
        
    _locationMgr.headingFilter = 15;  // requires a change in 15 degrees
    [_locationMgr startUpdatingHeading];
#endif
}

- (void) disableLocationGathering {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:disableLocationGathering: called.");
    
    // Turn off location sharing services.
    if (_power_saving_toggle) {
        if (kDebugLevel > 0)
            NSLog(@"CoreLocationController:disableLocationGathering: turning off low power.");
        
        [_locationMgr stopMonitoringSignificantLocationChanges];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"CoreLocationController:disableLocationGathering: turning off high frequency.");
        
        [_locationMgr stopUpdatingLocation];
    }

#if 0
    // XXX I don't think we want this, as we get course from our in location updates.
    
    // If we have heading information, turn it off, as well.
    if ([CLLocationManager headingAvailable]) {
        [_locationMgr stopUpdatingHeading];
    }
#endif
}


// Delegate functions.

// CLLocationManager delegate functions.
- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:locationManager:didUpdateToLocations: called.");
    
    // Pass our new location on to our delegate.
    [self.delegate locationsUpdate:locations];
}

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)new_location
            fromLocation:(CLLocation*)old_location {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:locationManager:didUpdateToLocation:fromLocation: called.");
    
    // Pass our new location on to our delegate.
    [self.delegate locationUpdate:new_location];
}

- (void) locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    if (kDebugLevel > 2)
        NSLog(@"CoreLocationController:locationManager:didFailWithError: called.");
    
    [self.delegate locationError:error];
}

@end
