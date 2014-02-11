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
#import "PersonalDataController.h"
#import "security-defines.h"

static const int kDebugLevel = 1;

static const size_t kChosenCipherKeySize = CIPHER_KEY_SIZE;
//static const size_t kChosenCipherBlockSize = CIPHER_BLOCK_SIZE;

static const char* kPolicyKeysFilename = "policy.keys";  // state filename which holds policies array
static const char* kSymmetricKey = "symmetric-key";  // prefix in key-chain


@interface SymmetricKeysController ()
@end

@implementation SymmetricKeysController

#pragma mark - Local data
@synthesize symmetric_keys = _symmetric_keys;
@synthesize policies = _policies;

// TOOD(aka) I have no idea what CSSM_ALGID_AES is being set to, i.e, 0x8000000L + 1, 0x8000000L * 2, or just 2?

enum {
    CSSM_ALGID_NONE = 0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:init: called.");
    
    if (self = [super init]) {
        // TODO(aka) Depending on when loadState: is called in the master VC, this init's may not be necessary.
        _symmetric_keys = [[NSMutableDictionary alloc] initWithCapacity:kNumPrecisionLevels];
        _policies = [[NSMutableArray alloc] initWithCapacity:kNumPrecisionLevels];
        NSLog(@"SymmetricKeysController:init: XXXXX policies count: %ld.", (unsigned long)[_policies count]);
        [_policies addObject:[NSString stringWithFormat:@"city"]];
        NSLog(@"SymmetricKeysController:init: XXXXX policies count: %ld.", (unsigned long)[_policies count]);
        [_policies removeObject:[NSString stringWithFormat:@"city"]];
        NSLog(@"SymmetricKeysController:init: XXXXX policies count: %ld.", (unsigned long)[_policies count]);
    }
    
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"Consumer:copywithZone: called.");
    
    SymmetricKeysController* tmp_symmetric_keys_controller = [[SymmetricKeysController alloc] init];
    tmp_symmetric_keys_controller.symmetric_keys = _symmetric_keys;
    tmp_symmetric_keys_controller.policies = _policies;
    
    return tmp_symmetric_keys_controller;
}

- (void) setSymmetric_keys:(NSMutableDictionary*)symmetric_keys {
    // We need to override the default setter, because we declared our dictionary to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_symmetric_keys != symmetric_keys) {
        _symmetric_keys = [symmetric_keys mutableCopy];
    }
}

- (void) setPolicies:(NSMutableArray*)policies {
    // We need to override the default setter, because we declared our array to be a copy (on assignment) and we need to ensure we stay mutable!
    
    if (_policies != policies) {
        _policies = [policies mutableCopy];
    }
}

#pragma mark - State backup & restore

- (NSString*) loadState {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:loadState: called.");
    
    // First, we load in our _policies array; this will act as our guide in fetching any existing symmetric keys from our key-chain in step two!
    
    _policies = [[PersonalDataController loadStateArray:[[NSString alloc] initWithCString:kPolicyKeysFilename encoding:[NSString defaultCStringEncoding]]] mutableCopy];
    
    if ([_policies count] == 0) {
        if (kDebugLevel > 0)
            NSLog(@"SymmetricKeysController:loadState: No policy keys found on disk!");
        
        return nil;
    }
    
    // For each dictionary key we have in _policies now, fetch the corresponding symmetric key from our key-chain.
    NSData* symmetric_key = nil;
    for (id object in _policies) {
        // Create the application tag into the key-chain for this symmetric key.
        NSString* dict_key = (NSString*)object;
        NSString* application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, [dict_key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
        
        if (kDebugLevel > 1)
            NSLog(@"SymmetricKeysController:loadState: querying key-chain for %s, key type: %u.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], CSSM_ALGID_AES);
        
        // Build the key-chain dictionary for our symmetric key.
        NSMutableDictionary* kc_dict = [[NSMutableDictionary alloc] init];
        [kc_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [kc_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [kc_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
        [kc_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
        
        // Get the key.
        CFTypeRef symmetric_key_ref = nil;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)kc_dict, (CFTypeRef*)&symmetric_key_ref);
        if (status != noErr) {
            NSString* err_msg = [[NSString alloc] initWithFormat:@"SymmetricKeysController:loadState: SecItemCopyMatching() failed using tag: %@, error: %d, generating new key.", [[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]], (int)status];
            return err_msg;

            /*
            // Generate the symmetric key for this precision level.
            symmetric_key = [self generateSymmetricKey:[NSNumber numberWithInt:i]];
            
            // Add our precision to our *new keys* list.
            [new_keys addObject:[NSNumber numberWithInt:i]];
             */
        } else {
            symmetric_key = (__bridge_transfer NSData*)symmetric_key_ref;
            
            if (kDebugLevel > 0)
                NSLog(@"SymmetricKeysController:loadState: fetched %luB key using tag: %s.", (unsigned long)[symmetric_key length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
        
#if 0
        // Convert the dictionary key to an index, then store the key in our controller using the index as a key.
        int idx = precision_level_idx([dict_key cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        if (kDebugLevel > 0)
            NSLog(@"SymmetricKeysController:loadState: inserting symmetric key (%s) into our dictionary using key: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], idx);

        [_symmetric_keys setObject:symmetric_key forKey:[NSNumber numberWithInt:idx]];
#else
        // Store the symmetric key in our local dictionary using just the suffix of the key-chain dictionary key.
        if (kDebugLevel > 0)
            NSLog(@"SymmetricKeysController:loadState: inserting symmetric key (%s) into our dictionary using key: %@.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], dict_key);
        
        [_symmetric_keys setObject:symmetric_key forKey:dict_key];
#endif
    }  // for (id object in _policies) {
    
    return nil;
}

#pragma mark - NSMutableDictionary management

- (NSUInteger) count {
    return [_symmetric_keys count];
}

- (NSData*) objectForKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:objectForKey: called.");
    
    return [_symmetric_keys objectForKey:policy];
}

- (void) setObject:(NSData*)symmetric_key forKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:setObject: called.");
    
    [_symmetric_keys setObject:symmetric_key forKey:policy];
}

- (void) removeObjectForKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:removeObjectForKey: called.");
    
    [_symmetric_keys removeObjectForKey:policy];
}

- (NSEnumerator*) keyEnumerator {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:keyEnumerator: called.");
    
    return [_symmetric_keys keyEnumerator];
}

#pragma mark - Symmetric key management

- (void) deleteSymmetricKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:deleteSymmetricKey: called.");
    
    if (policy == nil || [policy length] == 0)
        return;  // XXX TODO(aka) This routine needs to return ERRORS!
    
    // Create the application tag in the key-chain for this symmetric key.
    NSString* application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
    
    // Build the key-chain dictionary for our symmetric key.
    NSMutableDictionary* kc_dict = [[NSMutableDictionary alloc] init];
    [kc_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [kc_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [kc_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
    
    // Delete the symmetric key from the keychain.
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)kc_dict);
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
    
    // Remove the symmetric key from our controller and our dictionary keys array, then save the latter's state.
    [self removeObjectForKey:policy];
    
    NSLog(@"SymmetricKeysController:deleteSymmetricKey: XXX removing policy: %@, from policies (%ld)", policy, (unsigned long)[_policies count]);
    [_policies removeObject:policy];
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kPolicyKeysFilename encoding:[NSString defaultCStringEncoding]] array:_policies];
}

- (NSString*) generateSymmetricKey:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:generateSymmetricKey: called.");
    
    if (policy == nil || [policy length] == 0)
        return @"SymmetricKeysController:generateSymmetricKey: policy is nil or empty!";
    
    // Create the symmetric key for the specified precision level (dictionary key), store the new symmetric key in our key-chain as well as to our internal dictionary indexed by the precision level, add the precision level to our _policies array, and then save the array's state.
    
    // First, make sure we don't already have a key at this precision level.
    if ([_symmetric_keys objectForKey:policy] != nil) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"SymmetricKeysController:generateSymmetricKey: key already exists at precision: %@", policy];
        return err_msg;
    }
    
    // Create a buffer for the symmetric key data.
    uint8_t* symmetric_key_buf = (uint8_t*)malloc(kChosenCipherKeySize * sizeof(uint8_t));
    if (symmetric_key_buf == NULL)
        return @"SymmetricKeysController:generateSymmetricKey: unable to malloc key buffer!";
    
    // We build the symmetric key from random data.  Hopefully, Apple's *default* PRNG works, well.
    memset((void *)symmetric_key_buf, 0x0, kChosenCipherKeySize);
    OSStatus status = noErr;
    status = SecRandomCopyBytes(kSecRandomDefault, kChosenCipherKeySize, symmetric_key_buf);
    if (status != noErr) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"SymmetricKeysController:generateSymmetricKey: SecRandomCopyBytes() failed: %d", (int)status];
        return err_msg;
    }
    
    // Convert the key to an NSData object.
    NSData* symmetric_key = [[NSData alloc] initWithBytes:(const void*)symmetric_key_buf length:kChosenCipherKeySize];
    
    if (symmetric_key_buf != NULL)
        free(symmetric_key_buf);
    
    // Create the application tag in the key-chain for the symmetric key.
    NSString* application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];
    
    // Build the key-chain dictionary for our symmetric key.
    NSMutableDictionary* kc_dict = [[NSMutableDictionary alloc] init];
    [kc_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [kc_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [kc_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
    [kc_dict setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)] forKey:(__bridge id)kSecAttrKeySizeInBits];
    [kc_dict setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)] forKey:(__bridge id)kSecAttrEffectiveKeySize];
    
    /* XXX TODO(aka) Don't know if we need these or not
     [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanEncrypt];
     [dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanDecrypt];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDerive];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanWrap];
     [dict setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanUnwrap];
     */
    
    [kc_dict setObject:symmetric_key forKey:(__bridge id)kSecValueData];
    
    // Add the symmetric key to the keychain.
    status = SecItemAdd((__bridge CFDictionaryRef)kc_dict, NULL);
    if (status != noErr) {
        if (status == errSecDuplicateItem) {
            if (kDebugLevel > 0)
                NSLog(@"SymmetricKeysController:generateSymmetricKey: SecItemAdd() returned errSecDuplicateItem using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            NSString* err_msg = [[NSString alloc] initWithFormat:@"SymmetricKeysController:generateSymmetricKey: SecItemAdd() failed using tag: %s, error: %d!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
            return err_msg;
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"SymmetricKeysController:generateSymmetricKey: returning %luB key using tag: %s.", (unsigned long)[symmetric_key length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // And finally, save the symmetric key and precision level in our local data members.
    [_symmetric_keys setObject:symmetric_key forKey:policy];
    NSLog(@"SymmetricKeysController:generateSymmetricKey: XXX After adding %@, key dictionary: (%ld).", policy, (unsigned long)[_symmetric_keys count]);
    NSLog(@"SymmetricKeysController:generateSymmetricKey: XXX Before adding %@, policies = %ld.", policy, (unsigned long)[_policies count]);
    [_policies addObject:policy];
    NSLog(@"SymmetricKeysController:generateSymmetricKey: XXX After adding policy: %@, policies = %ld.", policy, (unsigned long)[_policies count]);
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kPolicyKeysFilename encoding:[NSString defaultCStringEncoding]] array:_policies];
    
    return nil;
}

- (BOOL) haveAllKeys {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:haveAllKeys: called.");
    
    if ([_symmetric_keys count] == (kNumPrecisionLevels - 1))  // note "- 1", as we never have a key for PC_PRECISION_IDX_NONE
        return true;
    
    return false;
}

- (BOOL) haveAnyKeys {
    if (kDebugLevel > 2)
        NSLog(@"SymmetricKeysController:haveAnyKeys: called.");
    
    if ([_symmetric_keys count] > 0)
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
 symmetric_key = [self generateSymmetricKey:i];
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
