//
//  KeyBundleController.m
//  SLS
//
//  Created by Andrew K. Adams on 1/22/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <sys/time.h>

#import "NSData+Base64.h"

#import "PersonalDataController.h"
#import "KeyBundleController.h"

static const int kDebugLevel = 1;
static const char kMsgDelimiter = ' ';  // for now, let's make it whitespace


@implementation KeyBundleController

#pragma mark - Local variables

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:init: called.");
    
    if (self = [super init]) {
        _encrypted_key = nil;
        _time_stamp = 0;
        _signature = nil;
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _encrypted_key = [decoder decodeObjectForKey:@"encrypted-key"];
        _time_stamp = [decoder decodeObjectForKey:@"time-stamp"];
        _signature = [decoder decodeObjectForKey:@"signature"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:encodeWithCoder: called.");
    
    [encoder encodeObject:_encrypted_key forKey:@"encrypted-key"];
    [encoder encodeObject:_time_stamp forKey:@"time-stamp"];
    [encoder encodeObject:_signature forKey:@"signature"];
}

#pragma mark - Data management

- (NSString*) build:(NSString*)encrypted_key privateKeyRef:(SecKeyRef)private_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:build:privateKeyRef: called.");
    
    if (encrypted_key == nil || [encrypted_key length] == 0)
        return @"KeyBundleController:build: key is empty or nil.";
    
    _encrypted_key = encrypted_key;
    
    struct timeval now;
    if (gettimeofday(&now, NULL) == -1)
        return @"KeyBundleController:build: gettimeofday(2) failed.";
    
    _time_stamp = [[NSNumber alloc] initWithLong:now.tv_sec];
    
    // Generate the signature over the hash of the concatenation of the key & time stamp.
    NSString* signature = nil;
    NSString* two_tuple = [[NSString alloc] initWithFormat:@"%s%ld", [_encrypted_key cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];
    NSData* hash = [PersonalDataController hashSHA256StringToData:two_tuple];
    NSString* error_msg = [PersonalDataController signHashData:hash privateKeyRef:private_key_ref signedHash:&signature];
    if (error_msg != nil)
        return error_msg;
    
    if (kDebugLevel > 0)
        NSLog(@"KeyBundleController:build: two tuple: %@, signature: %@.", two_tuple, signature);
    
    _signature = signature;
    
    return nil;
}

- (NSString*) generateWithString:(NSString*)serialized_str {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:generateWithString: called.");

    if (serialized_str == nil || [serialized_str length] == 0)
        return @"KeyBundleController:generateWithString: serialized string empty or nil!";
    
    NSArray* components = [serialized_str componentsSeparatedByString:[NSString stringWithFormat:@"%c", kMsgDelimiter]];
    if ([components count] != 3)
            return @"KeyBundleController:generateWithString: serialized string does not have three commponent!";
    
    _encrypted_key = [components objectAtIndex:0];
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    _time_stamp = [formatter numberFromString:[components objectAtIndex:1]];
    
    _signature = [components objectAtIndex:2];
    
    return nil;
}

- (NSString*) serialize {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:serialize: called.");
    
    NSString* key_bundle = [[NSString alloc] initWithFormat:@"%s%c%ld%c%s", [_encrypted_key cStringUsingEncoding:[NSString defaultCStringEncoding]], kMsgDelimiter, [_time_stamp longValue], kMsgDelimiter, [_signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];

    return key_bundle;
}

- (BOOL) verifySignature:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"KeyBundleController:verifySignature: called.");
    
    // Verify our signature over the hash of the concatenation of the key & time stamp.
    NSString* two_tuple = [[NSString alloc] initWithFormat:@"%s%ld", [_encrypted_key cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];
    NSData* hash = [PersonalDataController hashSHA256StringToData:two_tuple];

    return [PersonalDataController verifySignatureData:hash secKeyRef:public_key_ref signature:[NSData dataFromBase64String:_signature]];
}

@end
