//
//  Consumer.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "Consumer.h"
#import "PersonalDataController.h"    // for access to keychain routines
#import "NSData+Base64.h"
#import "security-defines.h"


static const int kDebugLevel = 1;

static const char* kStringDelimiter = ":";
static const char* kPublicKeyExt = KC_QUERY_KEY_PUBLIC_KEY_EXT;

@interface Consumer ()
- (void) setPublicKeyRef:(SecKeyRef)public_key_ref;
@end

@implementation Consumer

@synthesize identity = _identity;
@synthesize identity_hash = _identity_hash;
@synthesize key_deposit = _key_deposit;
@synthesize mobile_number = _mobile_number;
@synthesize email_address = _email_address;
@synthesize precision = _precision;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:init: called.");
    
    if (self = [super init]) {
        _identity = nil;
        _identity_hash = nil;
        _key_deposit = nil;
        _mobile_number = nil;
        _email_address = nil;
        _precision = 0;
        publicKeyRef = NULL;
    }
    
    return self;
}

- (id) initWithIdentity:(NSString*)identity {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:initWithIdentity: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"Consumer:initWithIdentity: using identity %s.", [identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    self = [super init];
    if (self) {
        _identity = identity;
        _identity_hash = nil;
        _key_deposit = nil;
        _mobile_number = nil;
        _email_address = nil;
        _precision = 0;
        publicKeyRef = NULL;
        
        return self;
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:copywithZone: called.");
    
    Consumer* tmp_controller = [[Consumer alloc] init];
    
    if (_identity)
        tmp_controller.identity = _identity;
    
    if (_identity_hash)
        tmp_controller.identity_hash = _identity_hash;
    
    if (_key_deposit)
        tmp_controller.key_deposit = _key_deposit;
    
    if (_mobile_number)
        tmp_controller.mobile_number = _mobile_number;
    
    if (_email_address)
        tmp_controller.email_address = _email_address;
    
    tmp_controller.precision = _precision;
    
    if (publicKeyRef != NULL)
        tmp_controller.publicKeyRef = publicKeyRef;
    
    return tmp_controller;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _identity = [decoder decodeObjectForKey:@"identity"];
        _identity_hash = [decoder decodeObjectForKey:@"identity-hash"];
        _key_deposit = [decoder decodeObjectForKey:@"key-deposit"];
        _mobile_number = [decoder decodeObjectForKey:@"mobile-number"];
        _email_address = [decoder decodeObjectForKey:@"email-address"];
        _precision = [decoder decodeObjectForKey:@"precision"];
        
        // Now we need to get our public key from the key-chain (using the identity that we just decoded).
        publicKeyRef = NULL;
        [self publicKeyRef];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:encodeWithCoder: called.");
    
    // Note, we don't encode the SecKeyRef, we'll just reload that from the key-chain in the decoder method using our identity.
    
    [encoder encodeObject:_identity forKey:@"identity"];
    [encoder encodeObject:_identity_hash forKey:@"identity-hash"];
    [encoder encodeObject:_key_deposit forKey:@"key-deposit"];
    [encoder encodeObject:_mobile_number forKey:@"mobile-number"];
    [encoder encodeObject:_email_address forKey:@"email-address"];
    [encoder encodeObject:_precision forKey:@"precision"];
}

- (void)setKey_deposit:(NSMutableDictionary*)key_deposit {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_key_deposit != key_deposit) {
        _key_deposit = [key_deposit mutableCopy];
    }
}

- (SecKeyRef) publicKeyRef {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:publicKeyRef: called.");
    
    NSLog(@"Consumer:publicKeyRef: XXX publicKeyRef is %d!", (publicKeyRef == NULL) ? false : true);
    
    if (publicKeyRef != NULL)
        return publicKeyRef;
      
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity_str = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity_str dataUsingEncoding:[NSString defaultCStringEncoding]];    
    NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (error_msg != nil)
        NSLog(@"Consumer:publicKeyRef: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSLog(@"Consumer:publicKeyRef: XXX after queryKeyRef, publicKeyRef is %d!", (publicKeyRef == NULL) ? false : true);
    
    return publicKeyRef;
}

- (void) setPublicKeyRef:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:setPublicKeyRef: called.");
    
    // Note, the key-chain will be updated in setPublicKey().
    publicKeyRef = public_key_ref;   
}

- (NSData*) getPublicKey {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:getPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];    
    NSData* public_key = nil;
    NSString* error_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
    if (error_msg != nil)
        NSLog(@"Consumer:getPublicKey: TODO(aka) queryKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return public_key;
}

- (void) setPublicKey:(NSData*)public_key {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:setPublicKey: called.");
    
    // Setup application tag for key-chain query and attempt to get a key.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];    
    
    if (publicKeyRef != NULL) {
        // Delete the key we currently have in the key-chain.
        [PersonalDataController deleteKeyRef:application_tag];
        publicKeyRef = NULL;
    }
    
    NSLog(@"Consumer:setPublicKey: TODO(aka) I think we want a *no write* flag, so we don't overwrite our existing key if it didn't change!  Or can we accomplish the same thing by just using setPublicKeyRef()?");
    
    // Add the new key to our key-chain.
    NSString* error_msg = [PersonalDataController saveKeyData:public_key withTag:application_tag];
    if (error_msg != nil)
        NSLog(@"Consumer:setPublicKey: TODO(aka) saveKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // And get our reference to the newly added key.
    error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (error_msg != nil)
        NSLog(@"Consumer:setPublicKey: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSLog(@"Consumer:setPublicKey: XXX after queryKeyRef, publicKeyRef is %d!", (publicKeyRef == NULL) ? false : true);
}

- (BOOL) isEqual:(Consumer*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:isEqual: called.");
    
    // Currently, the only data member we care about is the identity.
    if (![_identity isEqual:consumer.identity])
        return false;
    
    return true;
}

// This routine is currently only used for debugging.
- (NSString*) absoluteString {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:absoluteString: called.");
    
    NSString* absolute_string = [[NSString alloc] init];
    
    if (_identity != nil)
        absolute_string = [absolute_string stringByAppendingString:_identity];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    if (_key_deposit != nil)
        absolute_string = [absolute_string stringByAppendingString:[PersonalDataController absoluteStringKeyDeposit:_key_deposit]];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    absolute_string = [absolute_string stringByAppendingFormat:@"%ld", (long)[_precision integerValue]];
    absolute_string = [absolute_string stringByAppendingFormat:@"%s", kStringDelimiter];
    
    NSData* public_key = [self getPublicKey];
    if (public_key != nil)
        absolute_string = [absolute_string stringByAppendingString:[public_key base64EncodedString]];
    else
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
    
    return absolute_string;
}

/*
- (SecKeyRef) getPublicKey:mode {
    NSLog(@"Consumer:getPublicKey called.");
    
    // First, see if we have a public key in our key-chain.
    
    NSLog(@"Consumer:getPublicKey:mode: change SecurityUtil to *not* be a Class method.");
    // XXX SecurityUtil* secFactory = [SecurityUtil securityFactory];
    
    CFTypeRef publicKeyRef = NULL;
    publicKeyRef = [[SecurityUtil securityFactory] getPublicKeyWithIdentity:_identity];
    if (publicKeyRef == NULL) {
        // Okay, no key in our key-chain, either generate one (consumer mode) or retrieve it (provider mode).
        if (mode == CONSUMER_MODE_CONSUMER) {
            NSLog(@"Consumer:getPublicKey:mode: generating key pair.");
            
            // Ask Security Factory to generate a key pair for us.
            [[SecurityUtil securityFactory] generateKeyPairWithIdentity:_identity];
            publicKeyRef = [[SecurityUtil securityFactory] getPublicKeyWithIdentity:_identity];
            if (publicKeyRef == NULL) {
                NSLog(@"Consumer:getPublicKey:mode: TODO(aka) publicKey is NULL!");
            }
            
            _publicKey = [NSData alloc];
            _publicKey = (__bridge NSData*)publicKeyRef;
            
            NSLog(@"Consumer:getPublicKey:mode: base64 public key: %s.", [[self.publicKey base64EncodedString] cStringUsingEncoding: [NSString defaultCStringEncoding]]);
        } else if (mode == CONSUMER_MODE_PROVIDER) {
            NSLog(@"Consumer:getPublicKey:mode: retrieving key from: %s.", [[_publicKeyURL absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Okay, we need to retrieve our public key from our URL.
            NSError* status;
            _publicKey = [NSData dataWithContentsOfURL:_publicKeyURL options:NSDataReadingMappedIfSafe error:&status];
            if (_publicKey == nil && status) {
                NSString* errDesc = [[status localizedDescription] stringByAppendingString:
                                     ([status localizedFailureReason] ? [status localizedFailureReason] : @"")];
                NSLog(@"Consumer:getPublicKey:mode: %s.", [errDesc cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            }
            
            NSLog(@"Consumer:getPublicKey:mode: base64 public key %s.", [[self.publicKey base64EncodedString] cStringUsingEncoding: [NSString defaultCStringEncoding]]);
            
            NSLog(@"Consumer:getPublicKey:mode: TOOD(aka) we need to put the new retrieved consumer key in our key-chain!");
        } else {
            NSLog(@"Consumer:getPublicKey:mode: unknown mode: %d.", mode);
        }
        
    } else {
        NSLog(@"Consumer:getPublicKey:mode: got key from key-chain.");
        if (!_publicKey)
            _publicKey = [NSData alloc];
        _publicKey = (__bridge NSData*)publicKeyRef;
        
        NSLog(@"Consumer:getPublicKey:mode: base64 public key %s.", [[self.publicKey base64EncodedString] cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    }
}
*/

@end
