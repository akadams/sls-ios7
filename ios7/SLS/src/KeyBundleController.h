//
//  KeyBundleController.h
//  SLS
//
//  Created by Andrew K. Adams on 1/22/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_BUNDLE_EXTENSION ".kb"


@interface KeyBundleController : NSObject <NSCoding>

#pragma mark - Local variables
@property (copy, nonatomic) NSString* encrypted_key;       // base64 encrypted shared symmetric key
@property (copy, nonatomic) NSNumber* time_stamp;          // timestamp
@property (copy, nonatomic) NSString* signature;           // base64 signature over key and timestamp

#pragma mark - Initialization
- (id) init;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management
- (NSString*) build:(NSString*)encrypted_key privateKeyRef:(SecKeyRef)private_key_ref;
- (NSString*) generateWithString:(NSString*)serialized_str;
- (NSString*) serialize;
- (BOOL) verifySignature:(SecKeyRef)public_key_ref;

@end
