//
//  CoreLocationController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/10/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@protocol CoreLocationControllerDelegate;

@interface CoreLocationController : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager* locationMgr;
@property (nonatomic) BOOL location_sharing_toggle;
@property (nonatomic) BOOL power_saving_toggle;
@property (nonatomic) float distance_filter;
@property (weak, nonatomic) id <CoreLocationControllerDelegate> delegate;

- (id) init;
- (id) copyWithZone:(NSZone*)zone;
- (void) loadState;
- (void) saveState;
- (void) enableLocationGathering;
- (void) disableLocationGathering;

@end

@protocol CoreLocationControllerDelegate 
@required
- (void) locationUpdate:(CLLocation*)location;  // Our location updates are sent here
- (void) locationError:(NSError*)error;         // Any errors are sent here
@end