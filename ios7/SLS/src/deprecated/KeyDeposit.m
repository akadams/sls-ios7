//
//  KeyDeposit.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/8/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "KeyDeposit.h"


static const int kDebugLevel = 1;

@implementation KeyDeposit

@synthesize type = _type;
@synthesize location = _location;

- (id) init {
    if (kDebugLevel > 0)
        NSLog(@"KeyDeposit:init: called.");
    
    if (self = [super init]) {
        NSLog(@":KeyDeposit:init: TODO(aka) Setting members to nil.");
        
        _type = nil;
        _location = nil;
    }
    
    return self;
}

- (id) initWithType:(NSString*)type location:(NSString*)location {
    if (kDebugLevel > 0)
        NSLog(@"KeyDeposit:initWithType:location: called.");
    
    self = [super init];
    if (self) {
        if (kDebugLevel > 0)
            NSLog(@"KeyDeposit:initWithType:location: using type %s.", [type cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        _type = type;
        _location = location;
        return self;
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 0)
        NSLog(@"KeyDeposit:copyWithZone: called.");
    
    KeyDeposit* tmp_deposit = [[KeyDeposit alloc] init];
    
    if (_type)
        tmp_deposit.type = _type;
    if (_location)
        tmp_deposit.location = _location;
    
    return tmp_deposit;
}

- (NSString*) absoluteString {
    if (kDebugLevel > 0)
        NSLog(@"KeyDeposit:absoluteString: called.");
    
    NSString* tmp_string = [[NSString alloc] initWithFormat:@"%s:%s", [_type cStringUsingEncoding:[NSString defaultCStringEncoding]], [_location cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    if (kDebugLevel > 0)
        NSLog(@"KeyDeposit:absoluteString: generated: %s.", [tmp_string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return tmp_string;
}

@end
