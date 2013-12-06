//
//  SymmetricKeysController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/7/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <Security/Security.h>
//#import <CommonCrypto/CommonDigest.h>
//#import <CommonCrypto/CommonCryptor.h>

#import "SymmetricKeysController.h"
#import "security-defines.h"

static const int kDebugLevel = 1;

static const size_t kChosenCipherKeySize = CIPHER_KEY_SIZE;
//static const size_t kChosenCipherBlockSize = CIPHER_BLOCK_SIZE;
static const char* kSymmetricKey = "symmetric-key";
static const char* kLow = "low";
static const char* kMedium = "medium";
static const char* kHigh = "high";

@interface SymmetricKeysController ()
@end

@implementation SymmetricKeysController

@synthesize symmetric_keys = _symmetric_keys;

// TOOD(aka) I have no idea what CSSM_ALGID_AES is being set to, i.e, 0x8000000L + 1, 0x8000000L * 2, or just 2?

enum {
    CSSM_ALGID_NONE = 0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:init: called.");
    
    if (self = [super init]) {
        _symmetric_keys = [[NSMutableDictionary alloc] initWithCapacity:kNumPrecisionLevels];
    }
    
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:copywithZone: called.");
    
    SymmetricKeysController* tmp_symmetric_keys_controller = [[SymmetricKeysController alloc] init];
    tmp_symmetric_keys_controller.symmetric_keys = _symmetric_keys;
    
    return tmp_symmetric_keys_controller;
}

- (void) setSymmetric_keys:(NSMutableDictionary*)symmetric_keys {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_symmetric_keys != symmetric_keys) {
        _symmetric_keys = [symmetric_keys mutableCopy];
    }
}

- (NSArray*) loadState {
    // We inform the calling routine if we created any *new* symmetric keys by sending back an NSArray of precision levels (to any newly generated symmetric keys).  The reason for this is so the calling routine can then inform the consumers that use that symmetric key!
    
    // TOOD(aka) We may decide that *(re)starting* the app is a really good time to (re)cut our symmetric keys, hence, the first thing we should do is delete any existing symmetric keys in our key-chain!
    
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:loadState: called.");
    
    NSLog(@"SymmetricKeysController:loadState: TODO(aka) This routine should return an error message and pass in the new keys array as a pointer!  In fact, new keys should be a data member in SymmetricKeysController!");
    
    NSMutableArray* new_keys = [[NSMutableArray alloc] initWithCapacity:kNumPrecisionLevels];
    
    // For each precision level, see if our key is in the key-chain, if not, generate a key and send it out to our Consumers.
    
    for (int i = SKC_PRECISION_LOW; i <= SKC_PRECISION_HIGH; ++i) {
        NSData* symmetric_key = nil;
        
        // Create the application tag into the key-chain for this symmetric key.
        
        NSString* application_tag_str = nil;
        if (i == SKC_PRECISION_LOW) {
            application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kLow];
        } else if (i == SKC_PRECISION_MEDIUM) {
            application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kMedium];
        } else {
            application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kHigh];
        }
        
        NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
  
       if (kDebugLevel > 0)
            NSLog(@"SymmetricKeysController:loadState: querying key-chain for %s, key type: %u.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], CSSM_ALGID_AES);
        
        // Build the key-chain dictionary for our symmetric key.
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
        
        // Get the key.
        CFTypeRef symmetric_key_ref = nil;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, (CFTypeRef*)&symmetric_key_ref);
        if (status != noErr) {
            if (kDebugLevel > 1)
                NSLog(@"SymmetricKeysController:loadState: SecItemCopyMatching() failed using tag: %s, error: %d, generating new key.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status);
            
            // Generate the symmetric key for this precision level.
            symmetric_key = [self genSymmetricKey:[NSNumber numberWithInt:i]];
            
            // Add our precision to our *new keys* list.
            [new_keys addObject:[NSNumber numberWithInt:i]];
        } else {
            symmetric_key = (__bridge_transfer NSData*)symmetric_key_ref;
            
            if (kDebugLevel > 1)
                NSLog(@"SymmetricKeysController:loadState: fetched %luB key using tag: %s.", (unsigned long)[symmetric_key length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
        
        // Add it to our key list.
        if (kDebugLevel > 0)
            NSLog(@"SymmetricKeysController:loadState: inserting symmetric key (%s) into our dictionary using key: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], i);
        
        [_symmetric_keys setObject:symmetric_key forKey:[NSNumber numberWithInt:i]];
    }  // for (int i = SKC_PRECISION_LOW; i <= SKC_PRECISION_HIGH; ++i) { 
    
    return new_keys;
}

- (NSUInteger) count {
    return [_symmetric_keys count];
}

- (NSData*) objectForKey:(NSNumber*)precision {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:objectForKey: called.");
    
    return [_symmetric_keys objectForKey:precision];
}

- (void) setObject:(NSData*)symmetric_key forKey:(NSNumber*)precision {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:setObject: called.");
    
    [_symmetric_keys setObject:symmetric_key forKey:precision];
}

- (void) removeObjectForKey:(NSNumber*)precision {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:removeObjectForKey: called.");
    
    [_symmetric_keys removeObjectForKey:precision];
}

- (NSEnumerator*) keyEnumerator {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:keyEnumerator: called.");
    
    return [_symmetric_keys keyEnumerator];
}

- (void) deleteSymmetricKey:(NSNumber*)precision {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:deleteSymmetricKey: called.");
    
    // Create the application tag in the key-chain for this symmetric key.
    NSString* application_tag_str = nil;
    if (precision.intValue == SKC_PRECISION_LOW) {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kLow];
    } else if (precision.intValue == SKC_PRECISION_MEDIUM) {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kMedium];
    } else {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kHigh];
    }
    
    NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
    
    // Build the key-chain dictionary for our symmetric key.
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
    
    // Delete the symmetric key from the keychain.
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)dict);
    if (status != noErr) {
        if (status == errSecItemNotFound) {
            if (kDebugLevel > 1)
                NSLog(@"SymmetricKeysController:deleteSymmetricKey: SecRandomCopyBytes() returned errSecItemNotFound using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            NSLog(@"SymmetricKeysController:deleteSymmetricKey: SecItemDelete() failed using tag: %s, error: %d", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status);
            return;
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"SymmetricKeysController:deleteSymmetricKey: deleted key using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (NSData*) genSymmetricKey:(NSNumber*)precision {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:genSymmetricKey: called.");
    
    NSLog(@"SymmetricKeysController:genSymmetricKey: TODO(aka) This routine needs to return an error message and pass in a pointer to the NSData* object!");
    
    // Create a buffer for the symmetric key data.
    uint8_t* symmetric_key_buf = (uint8_t*)malloc(kChosenCipherKeySize * sizeof(uint8_t));
    if (symmetric_key_buf == NULL) {
        NSLog(@"SymmetricKeysController:genSymmetricKey: unable to malloc key buffer!");
        return nil;
    }
    
    // We build the symmetric key from random data.  Hopefully, Apple's *default* PRNG works, well.
    memset((void *)symmetric_key_buf, 0x0, kChosenCipherKeySize);
    OSStatus status = noErr;
    status = SecRandomCopyBytes(kSecRandomDefault, kChosenCipherKeySize, symmetric_key_buf);
    if (status != noErr) {
        NSLog(@"SymmetricKeysController:genSymmetricKey: SecRandomCopyBytes() failed: %d", (int)status);
        return nil;
    }
    
    // Convert the key to an NSData object.
    NSData* symmetric_key = [[NSData alloc] initWithBytes:(const void*)symmetric_key_buf length:kChosenCipherKeySize];
    
    if (symmetric_key_buf != NULL)
        free(symmetric_key_buf);
    
    // Create the application tag in the key-chain for the symmetric key.
    NSString* application_tag_str = nil;
    if (precision.intValue == SKC_PRECISION_LOW) {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kLow];
    } else if (precision.intValue == SKC_PRECISION_MEDIUM) {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kMedium];
    } else {
        application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, kHigh];
    }
    
    NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
    
    // Build the key-chain dictionary for our symmetric key.
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
    [dict setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)] forKey:(__bridge id)kSecAttrKeySizeInBits];
    [dict setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)] forKey:(__bridge id)kSecAttrEffectiveKeySize];
    
    /* XXX TODO(aka) Don't know if we need these or not
     [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanEncrypt];
     [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanDecrypt];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDerive];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanWrap];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanUnwrap];
     */
    
    [dict setObject:symmetric_key forKey:(__bridge id)kSecValueData];
    
    // Add the symmetric key to the keychain.
    status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if (status != noErr) {
        if (status == errSecDuplicateItem) {
            if (kDebugLevel > 0)
                NSLog(@"SymmetricKeysController:genSymmetricKey: SecItemAdd() returned errSecDuplicateItem using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            NSLog(@"SymmetricKeysController:genSymmetricKey: SecItemAdd() failed using tag: %s, error: %d!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status);
            return nil;
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"SymmetricKeysController:genSymmetricKey: returning %luB key using tag: %s.", (unsigned long)[symmetric_key length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return symmetric_key;
}

- (BOOL) haveKeys {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:haveKeys: called.");
    
    if ([_symmetric_keys count] == kNumPrecisionLevels)
        return true;
    
    return false;
}

/* XXX Deprecated in favor for loadState:
 - (void) loadDefaultData {
 if (kDebugLevel > 2)
 NSLog(@"SymmetricKeysController:loadDefaultData: called.");
 
 // For each precision level, see if our key is in the key-chain, if not, generate a key and send it out to our Consumers.
 
 NSEnumerator* enumerator = [_symmetric_keys keyEnumerator];
 id key;
 while ((key = [enumerator nextObject])) {
 
 }
 
 
 
 NSLog(@"SymmetricKeysController:loadDefaultData: Entering loop at i = %d.).", SKC_PRECISION_LOW);
 
 for (int i = SKC_PRECISION_LOW; i < SKC_PRECISION_HIGH; ++i) {
 
 // Creates NSData object that contains this symmetric key's index into the key-chain.
 
 // TOOD(aka) Use the damn constants for this!
 NSString* application_tag_str = nil;
 if (i == SKC_PRECISION_LOW) {
 application_tag_str = @"symmetric-key.low";
 } else if (i == SKC_PRECISION_MEDIUM) {
 application_tag_str = @"symmetric-key.medium";
 } else {
 application_tag_str = @"symmetric-key.high";
 }
 
 if (kDebugLevel > 0)
 NSLog(@"SymmetricKeysController:loadDefaultData: TODO(aka) querying key-chain for %s, key type: %u.", [application_tag_str cStringUsingEncoding:[NSString defaultCStringEncoding]], CSSM_ALGID_AES);
 
 NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
 
 // Build the key-chain dictionary for our symmetric key.
 NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
 [dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
 [dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
 [dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
 [dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
 
 // Get the key.
 NSData* symmetric_key = nil;
 CFTypeRef symmetric_key_ref = nil;
 OSStatus status = noErr;
 status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, (CFTypeRef*)&symmetric_key_ref);
 if (status != noErr) {
 if (kDebugLevel > 0)
 NSLog(@"SymmetricKeysController:loadDefaultData: SecItemCopyMatching() failed: %ld.", status);
 
 // Generate the symmetric key for this precision level.
 symmetric_key = [self genSymmetricKey:i];
 } else {
 symmetric_key = (__bridge_transfer NSData*)symmetric_key_ref;
 
 if (kDebugLevel > 0)
 NSLog(@"SymmetricKeysController:loadDefaultData: fetched %dB key at %s.", [symmetric_key length], [application_tag_str cStringUsingEncoding:[NSString defaultCStringEncoding]]);
 }
 
 // Add it to our key list.
 
 NSLog(@"SymmetricKeysController:loadDefaultData: inserting key at index %d.).", i);
 
 [_symmetric_keys insertObject:symmetric_key atIndex:i];
 }
 }
*/

@end
