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
static const char kMsgDelimiter = ':';


@implementation KeyBundleController

#pragma mark - Local variables
@synthesize symmetric_key = _symmetric_key;
@synthesize history_log_path = _history_log_path;
@synthesize time_stamp = _time_stamp;
@synthesize signature = _signature;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:init: called.");
    
    if (self = [super init]) {
        _symmetric_key = nil;
        _history_log_path = nil;
        _time_stamp = 0;
        _signature = nil;
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _symmetric_key = [decoder decodeObjectForKey:@"symmetric-key"];
        _history_log_path = [decoder decodeObjectForKey:@"history-log-path"];
        _time_stamp = [decoder decodeObjectForKey:@"time-stamp"];
        _signature = [decoder decodeObjectForKey:@"signature"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:encodeWithCoder: called.");
    
    [encoder encodeObject:_symmetric_key forKey:@"symmetric-key"];
    [encoder encodeObject:_history_log_path forKey:@"history-log-path"];
    [encoder encodeObject:_time_stamp forKey:@"time-stamp"];
    [encoder encodeObject:_signature forKey:@"signature"];
}

#pragma mark - Data management

- (NSString*) build:(NSString*)symmetric_key privateKeyRef:(SecKeyRef)private_key_ref historyLogPath:(NSString*)path {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:build:privateKeyRef:path: called.");
    
    if (symmetric_key == nil || [symmetric_key length] == 0 || path == nil || [path length] == 0)
        return @"KeyBundleController:build: key or path is empty or nil.";
    
    _symmetric_key = symmetric_key;
    
    NSLog(@"KeyBundleController:build: TODO(aka) make sure path doesn't contain a ':' character: %s.", [path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _history_log_path = path;
    
    struct timeval now;
    if (gettimeofday(&now, NULL) == -1)
        return @"KeyBundleController:build: gettimeofday(2) failed.";
    
    _time_stamp = [[NSNumber alloc] initWithLong:now.tv_sec];
    
    // Generate the signature over the hash of the concatenation of the key, path & time stamp.
    NSString* signature = nil;
    NSString* three_tuple = [[NSString alloc] initWithFormat:@"%s%s%ld", [_symmetric_key cStringUsingEncoding:[NSString defaultCStringEncoding]], [_history_log_path cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];
    NSData* hash = [PersonalDataController hashSHA256StringToData:three_tuple];
    NSString* error_msg = [PersonalDataController signHashData:hash privateKeyRef:private_key_ref signedHash:&signature];
    if (error_msg != nil)
        return error_msg;
    
    if (kDebugLevel > 0)
        NSLog(@"KeyBundleController:build: two tuple: %@, signature: %@.", three_tuple, signature);
    
    _signature = signature;
    
    return nil;
}

- (NSString*) generateWithString:(NSString*)serialized_str {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:generateWithString: called.");

    if (serialized_str == nil || [serialized_str length] == 0)
        return @"KeyBundleController:generateWithString: serialized string empty or nil!";
    
    NSArray* components = [serialized_str componentsSeparatedByString:[NSString stringWithFormat:@"%c", kMsgDelimiter]];
    if ([components count] != 4)
            return @"KeyBundleController:generateWithString: serialized string does not have three commponent!";
    
    _symmetric_key = [components objectAtIndex:0];
    _history_log_path =  [components objectAtIndex:1];
    
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    _time_stamp = [formatter numberFromString:[components objectAtIndex:2]];
    
    _signature = [components objectAtIndex:3];
    
    return nil;
}

- (NSString*) serialize {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:serialize: called.");
    
    NSString* key_bundle = [[NSString alloc] initWithFormat:@"%s%c%s%c%ld%c%s", [_symmetric_key cStringUsingEncoding:[NSString defaultCStringEncoding]], kMsgDelimiter, [_history_log_path cStringUsingEncoding:[NSString defaultCStringEncoding]], kMsgDelimiter, [_time_stamp longValue], kMsgDelimiter, [_signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];

    return key_bundle;
}

- (BOOL) verifySignature:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 4)
        NSLog(@"KeyBundleController:verifySignature: called.");
    
    // Verify our signature over the hash of the concatenation of the key & time stamp.
    NSString* three_tuple = [[NSString alloc] initWithFormat:@"%s%s%ld", [_symmetric_key cStringUsingEncoding:[NSString defaultCStringEncoding]], [_history_log_path cStringUsingEncoding:[NSString defaultCStringEncoding]], [_time_stamp longValue]];
    NSData* hash = [PersonalDataController hashSHA256StringToData:three_tuple];

    return [PersonalDataController verifySignatureData:hash secKeyRef:public_key_ref signature:[NSData dataFromBase64String:_signature]];
}

@end
