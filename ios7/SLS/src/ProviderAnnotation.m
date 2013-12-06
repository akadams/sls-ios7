//
//  ProviderAnnotation.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/31/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ProviderAnnotation.h"


static const int kDebugLevel = 1;

@implementation ProviderAnnotation

@synthesize identity = _identity;
@synthesize coordinate = _coordinate;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize index = _index;
@synthesize color = _color;
@synthesize image_filename = _image_filename;
@synthesize reuse_id = _reuse_id;

- (id) initWithIdentity:(NSString*)identity coordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title subtitle:(NSString*)subtitle index:(NSInteger)index color:(MKPinAnnotationColor)color imageFilename:(NSString*)image_filename reuseID:(NSString*)reuse_id {
    if (kDebugLevel > 2)
        NSLog(@"ProviderAnnotation:initWithIdentity:coordinate:title:subtitle:color:index: called.");
    
    self = [super init];
    if (self) {
        _identity = identity;
        _coordinate = coordinate;
        _title = title;
        _subtitle = subtitle;
        _index = index;
        _color = color;
        _image_filename = image_filename;
        _reuse_id = reuse_id;
        
        return self;
    }
    
    return nil;
}

@end
