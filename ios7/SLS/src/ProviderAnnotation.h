//
//  ProviderAnnotation.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/31/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@interface ProviderAnnotation : NSObject <MKAnnotation>

@property (copy, nonatomic) NSString* identity;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString* title;
@property (copy, nonatomic) NSString* subtitle;
@property (nonatomic) NSInteger index;
@property (nonatomic) MKPinAnnotationColor color;
@property (copy, nonatomic) NSString* image_filename;
@property (copy, nonatomic) NSString* reuse_id;

- (id) initWithIdentity:(NSString*)identity coordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title subtitle:(NSString*)subtitle index:(NSInteger)index color:(MKPinAnnotationColor)color imageFilename:(NSString*)image_filename reuseID:(NSString*)reuse_id;

@end
