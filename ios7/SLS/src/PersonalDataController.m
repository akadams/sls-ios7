//
//  PersonalDataController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/21/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import "NSData+Base64.h"

#import "PersonalDataController.h"
#import "security-defines.h"


// TODO(aka) We may want to split this up, e.g., kDebugCryptoLevel, etc.
static const int kDebugLevel = 1;

// Crypto constants.
static const size_t kChosenCipherKeySize = CIPHER_KEY_SIZE;
static const size_t kChosenCipherBlockSize = CIPHER_BLOCK_SIZE;
static const int kChosenKeyBitSize = 1024;

static const char* kPublicKeyExt = KC_QUERY_KEY_PUBLIC_KEY_EXT;
static const char* kPrivateKeyExt = KC_QUERY_KEY_PRIVATE_KEY_EXT;
static const char* kLocationDataFilename = URI_LOCATION_DATA_FILENAME;

// Identity constants.
static const char* kIdentityFilename = "identity.txt";

// Deposit dictionary keys and constants.
static const char* kDepositKeyType = "type";
static const char* kDepositKeyPhoneNumber = "phone-number";
static const char* kDepositKeyAddress = "address";

static const char* kDepositNone = "None Selected";
static const char* kDepositSMS = "SMS";
static const char* kDepositEMail = "E-mail";

static const char* kDepositDelimiter = ":";
static const char* kDepositFilename = "deposit.dict";

// File Store dictionary keys and constants.
static const char* kFSKeyService = "service";
static const char* kFSKeyAccessKey = "access-key";
static const char* kFSKeySecretKey = "secret-key";
static const char* kFSKeyScheme = "scheme";
static const char* kFSKeyHost = "host";

static const char* kFSNone = "None Selected";
static const char* kFSAmazonS3 = "Amazon S3";

static const char* kFSSchemeHTTPS = "https";
// static const char* kFSDelimiter = ":";
static const char* kFSHostAmazonS3 = "s3.amazonaws.com";

static const char* kFSFilename = "file-store.dict";

// QR Encoding constants.
static const int qr_margin = 3;
static const char* kQRDelimiter = ";";
static const char* kQRKeyIdentityHash = "id";
static const char* kQRKeyPublicKey = "key";

//static const int kQRMode = QR_MODE_NUM;    // Numeric mode
//static const int kQRMode = QR_MODE_AN;     // Alphabet-numeric mode
static const int kQRMode = QR_MODE_8;        // 8-bit data mode
//static const int kQRMode = QR_MODE_KANJI;  // Kanji (shift-jis) mode

//static const int kQRErrorCorrection = QR_ECLEVEL_L;  // lowest
//static const int kQRErrorCorrection = QR_ECLEVEL_M;
//static const int kQRErrorCorrection = QR_ECLEVEL_Q;
static const int kQRErrorCorrection = QR_ECLEVEL_H;    // highest

// Miscellaneous
static const int kInitialDictionarySize = 5;

@interface PersonalDataController ()
- (void) getAsymmetricKeys;       // attempt to get keys from key chain
- (void) setPublicKeyRef:(SecKeyRef)public_key_ref;
- (void) setPrivateKeyRef:(SecKeyRef)private_key_ref;
@end

@implementation PersonalDataController

#pragma mark - Local data
@synthesize identity = _identity;
@synthesize identity_hash = _identity_hash;
@synthesize deposit = _deposit;
@synthesize file_store = _file_store;

#pragma mark - Initialization
- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:init: called.");
    
    if (self = [super init]) {
        _identity = nil;
        _identity_hash = nil;
        _deposit = nil;
        _file_store = nil;
        publicKeyRef = NULL;
        privateKeyRef = NULL;
    }
    
    return self;
}

- (void)setDeposit:(NSMutableDictionary*)deposit {
    // We need to override the default setter, because masterProviderList property is a copy, and we must ensure that the new copy is also mutable.
    
    if (_deposit != deposit) {
        _deposit = [deposit mutableCopy];
    }
}

- (void)setFile_store:(NSMutableDictionary*)file_store {
    // We need to override the default setter, because masterProviderList property is a copy, and we must ensure that the new copy is also mutable.
    
    if (_file_store != file_store) {
        _file_store = [file_store mutableCopy];
    }
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:copyWithZone: called.");
    
    PersonalDataController* tmp_controller = [[PersonalDataController alloc] init];
    if (_identity)
        tmp_controller.identity = _identity;
    
    if (_identity_hash)
        tmp_controller.identity_hash = _identity_hash;
    
    if (publicKeyRef)
        tmp_controller.publicKeyRef = publicKeyRef;
    
    if (privateKeyRef)
        tmp_controller.privateKeyRef = privateKeyRef;
    
    if (_deposit)
        tmp_controller.deposit = _deposit;
    
    if (_file_store)
        tmp_controller.file_store = _file_store;
    
    return tmp_controller;
}

#pragma mark - State backup & restore

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:loadState: called.");
    
    // Load in our identity, keys, file store and deposit parameters (dictionary) from disk.
    
    // Get Document path.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the identity filename and load it in (if it exists).
    NSString* identity_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kIdentityFilename];
    
    // If it exists, load it in, else initialize an empty string.
    if ([[NSFileManager defaultManager] fileExistsAtPath:identity_file]) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s exists, initializing identity with contents.", [identity_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSError* status = nil;
        _identity = [[NSString alloc] initWithContentsOfFile:identity_file encoding:[NSString defaultCStringEncoding] error:&status];
        
        // Since we've got an identity, build our hash ID and try now to load our private & public asymmetric keys.
        
        _identity_hash = [PersonalDataController hashMD5String:_identity];
        
        NSString* private_key_identity = [_identity stringByAppendingFormat:@"%s", kPrivateKeyExt];
        NSData* application_tag = [private_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
        
        privateKeyRef = NULL;
        NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&privateKeyRef];
        if (error_msg != nil)
            NSLog(@"PersonalDataController:loadState: TODO(aka) queryKeyRef() failed: %s", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);            
        else if (privateKeyRef == NULL)
            NSLog(@"PersonalDataController:loadState: XXX TODO(aka) Failed to retrieve private key using tag: %s!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
        application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
        
        publicKeyRef = NULL;
        NSString* pubkey_error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
        if (pubkey_error_msg != nil)
            NSLog(@"PersonalDataController:loadState: TODO(aka) queryKeyRef() failed: %s", [pubkey_error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);            
    } else {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s does not exist, initializing empty identity.", [identity_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);        
        
        _identity = [[NSString alloc] init];
    }
    
    // Build the deposit dictionary filename and load it in (if it exists).
    NSString* deposit_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kDepositFilename];
    
    // If it exists, load it in, else initialize an empty dictionary.
    if ([[NSFileManager defaultManager] fileExistsAtPath:deposit_file]) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s exists, initializing deposit dictionary with contents.", [deposit_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        _deposit = [[NSMutableDictionary alloc] initWithContentsOfFile:deposit_file];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s does not exist, initializing empty deposit dictionary.", [deposit_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        _deposit = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionarySize];
    }
    
    // Build the file-store dictionary filename and load it in (if it exists).
    NSString* fs_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSFilename];
    
    // If it exists, load it in, else initialize an empty dictionary.
    if ([[NSFileManager defaultManager] fileExistsAtPath:fs_file]) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s exists, initializing file store dictionary with contents.", [fs_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        _file_store = [[NSMutableDictionary alloc] initWithContentsOfFile:fs_file];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadState: %s does not exist, initializing empty file store dictionary.", [fs_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        _file_store = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionarySize];
    }
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:loadState: Loaded identity: %s, pubKeyRef: %d, pubKeyBase64: %s, deposit: %s, file store: %s.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], (publicKeyRef == NULL) ? false : true,
              [[[self getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringDeposit:_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringFileStore:_file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]);        
}

- (void) saveIdentityState {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveIdentityState: called.");
    
    // Store our (newly) updated identity to disk.

    // Get Document path.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the identity filename and write the identity out to disk.
    NSString* identity_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kIdentityFilename];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveIdentityState: writing updated identity to %s.", [identity_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSError* status = nil;
    [_identity writeToFile:identity_file atomically:YES encoding:[NSString defaultCStringEncoding] error:&status];
    
    if (status != nil)
        NSLog(@"PersonalDataController:saveIdentityState: ERROR: writeToFile(%s) failed: %s.", [identity_file cStringUsingEncoding:[NSString defaultCStringEncoding]], [status.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

- (void) saveDepositState {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveDepositState: called.");
    
    // Store our (newly) updated file store dictionary to disk.
    
    // Get Document path.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the file-store dictionary filename and write it out to disk.
    NSString* deposit_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kDepositFilename];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveDepositState: writing updated dictionary to %s.", [deposit_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [_deposit writeToFile:deposit_file atomically:YES];
}

- (void) saveFileStoreState {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveFileStoreState: called.");
    
    // Store our (newly) updated file store dictionary to disk.
    
    // Get Document path.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the file-store dictionary filename and write it out to disk.
    NSString* fs_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSFilename];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveFileStoreState: writing updated dictionary to %s.", [fs_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [_file_store writeToFile:fs_file atomically:YES];
}

#pragma mark - State Class functions

+ (BOOL) loadStateBool:(NSString*)filename {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:loadStateBool: called.");
    
    BOOL flag = false;
    
    // Get Document path.
    NSArray* dir_list =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the state filename and load it into our NSString (if it exists).
    NSString* state_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:state_file]) {
        if (kDebugLevel > 2)
            NSLog(@"PersonalDataController:loadStateBool: %s exists, initializing sharing_enabled with contents.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSError* status = nil;
        NSString* flag_str = [[NSString alloc] initWithContentsOfFile:state_file encoding:[NSString defaultCStringEncoding] error:&status];
        if (status != nil) {
            NSLog(@"PersonalDataController:loadStateBool: ERROR: initWithContentsOfFile(%s) failed: %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]], [status.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            return false;
        }
        
        flag = [flag_str boolValue];
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadStateBool: Initialized boolean state %d with the contents of: %s.", flag, [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    return flag;
}

+ (NSString*) loadStateString:(NSString*)filename {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:loadStateString: called.");
    
    NSString* string = nil;
    
    // Get Document path.
    NSArray* dir_list =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the state filename and load it into our NSString (if it exists).
    NSString* state_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:state_file]) {
        if (kDebugLevel > 2)
            NSLog(@"PersonalDataController:loadStateString: %s exists, initializing sharing_enabled with contents.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSError* status = nil;
        string = [[NSString alloc] initWithContentsOfFile:state_file encoding:[NSString defaultCStringEncoding] error:&status];
        if (status != nil) {
            NSLog(@"PersonalDataController:loadStateString: ERROR: initWithContentsOfFile(%s) failed: %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]], [status.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            return nil;
        }
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:loadStateString: Initialized string state %s with the contents of: %s.", [string cStringUsingEncoding:[NSString defaultCStringEncoding]], [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    return string;
}

+ (void) saveState:(NSString*)filename Bool:(BOOL)boolean {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveState:Bool: called.");
    
    // Get Document path.
    NSArray* dir_list =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the state filename and write it out to disk.
    NSString* state_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveState:Bool: writing updated download flag to %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    NSString* string = [NSString stringWithFormat:@"%d", boolean];
    
    NSError* status = nil;
    [string writeToFile:state_file atomically:YES encoding:[NSString defaultCStringEncoding] error:&status];
    
    if (status != nil)
        NSLog(@"PersonalDataControll:saveState:Bool: ERROR: writeToFile(%s) failed: %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]], [status.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

+ (void) saveState:(NSString*)filename string:(NSString*)string {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveState:String: called.");
    
    // Get Document path.
    NSArray* dir_list =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    
    // Build the state filename and write it out to disk.
    NSString* state_file = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveState:String: writing updated download flag to %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSError* status = nil;
    [string writeToFile:state_file atomically:YES encoding:[NSString defaultCStringEncoding] error:&status];
    
    if (status != nil)
        NSLog(@"PersonalDataControll:saveState:String: ERROR: writeToFile(%s) failed: %s.", [state_file cStringUsingEncoding:[NSString defaultCStringEncoding]], [status.description cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

#pragma mark - Cryptography Management

- (SecKeyRef) publicKeyRef {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:publicKeyRef: called.");
    
    if (publicKeyRef != NULL)
        return publicKeyRef;
    
    if (_identity == nil || [_identity length] == 0)
        return NULL;
    
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&publicKeyRef];
    if (error_msg != nil)
        NSLog(@"PersonalDataController:publicKeyRef: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return publicKeyRef;    
}

- (SecKeyRef) privateKeyRef {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:privateKeyRef: called.");
    
    if (privateKeyRef != NULL)
        return privateKeyRef;
    
    if (_identity == nil || [_identity length] == 0)
        return NULL;
    
    NSString* private_key_identity = [_identity stringByAppendingFormat:@"%s", kPrivateKeyExt];
    NSData* application_tag = [private_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&privateKeyRef];
    if (error_msg != nil)
        NSLog(@"PersonalDataController:publicKeyRef: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return privateKeyRef;    
}

- (NSData*) getPublicKey {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getPublicKey: called.");
    
    if (_identity == nil || [_identity length] == 0)
        return NULL;
    
    // Setup application tag for key-chain query.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    // Attempt to get the key.
    NSData* public_key = nil;
    NSString* error_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
    if (error_msg != nil)
        NSLog(@"PersonalDataController:getPublicKey: TODO(aka) queryKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return public_key;
}

- (void) setPublicKeyRef:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setPublicKeyRef: called.");
    
    // Note, it is up to the calling routine to make sure that the key is loaded in the key-chain (genAsymmetricKeys() *does* load the keys in the key-chain).
    
    publicKeyRef = public_key_ref;
}

- (void) setPrivateKeyRef:(SecKeyRef)private_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setPrivateKeyRef: called.");
    
    // Note, as with setPublicKeyRef, it is up to the calling routine to make sure that the key is loaded in the key-chain (genAsymmetricKeys() *does* load the keys in the key-chain).
    
    privateKeyRef = private_key_ref;
}

- (void) getAsymmetricKeys {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getAsymmetricKeys: called.");
 
    NSLog(@"PersonalDataController:getAsymmetricKeys: XXX TODO(aka) This routine is not used!");
    
    // Attempt to get the public key.
    [self publicKeyRef];
    if (publicKeyRef == NULL) {
        [self genAsymmetricKeys];
        
        return;  // all done
    }
    
    // We got the public key, now attempt to get the private key.
    [self privateKeyRef];
    if (privateKeyRef == NULL) {
        // Argh!  Either we had an error or the private key was never stored.
        NSLog(@"PersonalDataController:getAsymmetricKeys: TODO(aka) unable to retrieve private key from key-chain, need to remove public key before generating new key pair!");
        
        [self genAsymmetricKeys];
        
        return;  // all done
    }

    // If we made it here, everything went smoothly.
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:getAsymmetricKeys: got both keys from key-chain.");

    /*
    // Setup application tag for key-chain query.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* pub_applicaton_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:getAsymmetricKeys: using public identity: %s.", [public_key_identity_str cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    // Set the public key query dictionary.
    NSMutableDictionary* public_key_dict = [[NSMutableDictionary alloc] init];
    [public_key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [public_key_dict setObject:public_key_identity forKey:(__bridge id)kSecAttrApplicationTag];
    [public_key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [public_key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Attempt to get the public key from the key chain.
    OSStatus public_key_status = noErr;
    public_key_status = SecItemCopyMatching((__bridge CFDictionaryRef)public_key_dict, (CFTypeRef*)&publicKeyRef);
    if (public_key_status == noErr) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:getAsymmetricKeys: SecItemCopyMatching(publicKeyRef) call successful.");
        
        if (publicKeyRef == NULL) {
            NSLog(@"PersonalDataController:getAsymmetricKeys: public key not found in key-chain, creating.");
            
            // Create asymmetric keys.
            [self genAsymmetricKeys];
            
            return;  // all done
        }
        
        // Okay, if we made it here we got the public key, now get the private key.
        
        // Creates NSData object that contains the identifier string modified to index the private key.
        NSString* private_key_identity_str = [_identity stringByAppendingFormat:@"%s", kPrivateKeyExt];
        NSData* private_key_identity = [private_key_identity_str dataUsingEncoding:[NSString defaultCStringEncoding]];
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:getAsymmetricKeys: using private identity: %s.", [private_key_identity_str cStringUsingEncoding: [NSString defaultCStringEncoding]]);
        
        // Set the private key query dictionary.
        NSMutableDictionary* private_key_dict = [[NSMutableDictionary alloc] init];
        [private_key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [private_key_dict setObject:private_key_identity forKey:(__bridge id)kSecAttrApplicationTag];
        [private_key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [private_key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
        
        // Attempt to get the private key from the key chain.
        OSStatus private_key_status = noErr;
        private_key_status = SecItemCopyMatching((__bridge CFDictionaryRef)private_key_dict, (CFTypeRef*)&privateKeyRef);
        if (private_key_status == noErr) {
            if (kDebugLevel > 0)
                NSLog(@"PersonalDataController:getAsymmetricKeys: SecItemCopyMatching(privateKeyRef) call successful.");
            
            if (privateKeyRef == NULL) {
                NSLog(@"PersonalDataController:getAsymmetricKeys: TODO(aka) private key not found!");
                return;
            }
            
            if (kDebugLevel > 0)
                NSLog(@"PersonalDataController:getAsymmetricKeys: got asymmetric keys.");
            return;  // all done
        } else {
            // Argh, error.  Fall-through and pick it up with the publicKeyRef error ...
        }
    }
    
    // If we made it here, things didn't work out so well with SecItemCopyMatching().
    NSLog(@"PersonalDataController:getAsymmetricKeys: SecItemCopyMatching() failed.");
    publicKeyRef = NULL;
    privateKeyRef = NULL;
     */
}

- (void) genAsymmetricKeys {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:genAsymmetricKeys: called.");
    
    NSLog(@"PersonalDataController:genAsymmetricKeys: TODO(aka) This routine must return any error messages!");
    
    // Setup application tags for querying the key-chain.
    NSString* public_key_identity = [_identity stringByAppendingFormat:@"%s", kPublicKeyExt];
    NSData* pub_application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    NSString* private_key_identity = [_identity stringByAppendingFormat:@"%s", kPrivateKeyExt];
    NSData* pri_application_tag = [private_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:genAsymmetricKeys: using public identity: %s, private identity: %s.", [public_key_identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [private_key_identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    // If either already exists in key-chain, remove them.
    NSString* error_msg = [PersonalDataController queryKeyRef:pub_application_tag keyRef:&publicKeyRef];
    if (error_msg != nil) {
        NSLog(@"PersonalDataController:genAsymmetricKeys: queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else {
        // We successfully queried *an entry* for the key, so delete it.
        [PersonalDataController deleteKeyRef:pub_application_tag];
    }
    
    error_msg = [PersonalDataController queryKeyRef:pri_application_tag keyRef:&privateKeyRef];
    if (error_msg != nil) {
        NSLog(@"PersonalDataController:genAsymmetricKeys: queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else {
        // We successfully queried *an entry* for the key, so delete it.
        [PersonalDataController deleteKeyRef:pri_application_tag];
    }
    
    publicKeyRef = NULL;
    privateKeyRef = NULL;
    
    /* 
     *  TODO(aka) To use CoreFoundation instead of NS to bulid dictionaries.
     
     // TOOD(aka) Unfortunately, I don't know how to add two arrays (*key_keys[] & *key_values[]) to another array (top_level_values[])!
     const void* private_key_keys[] = {kSecClass, kSecAttrApplicationTag, kSecAttrKeyType, kSecReturnData};
     const void* private_key_values[] = {kSecClassKey, private_key_identity_ref, kSecAttrKeyTypeRSA, kCFBooleanTrue};
     const void* public_key_keys[] = {kSecClass, kSecAttrApplicationTag, kSecAttrKeyType, kSecReturnData};
     const void* public_key_values[] = {kSecClassKey, private_key_identity_ref, kSecAttrKeyTypeRSA, kCFBooleanTrue};
     
     const void* top_level_keys[] = {kSecAttrKeyType, kSecAttrKeySizeInBits, kSecPrivate_key_attrs, kSecPublic_key_attrs};
     const void* top_level_values[] = {kSecAttrKeyTypeRSA, kChosenKeyBitSize, };
     
     CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values, 3, NULL, NULL);
     */
    
    // Allocates dictionaries to be used for attributes in the SecKeyGeneratePair function.
    
    NSMutableDictionary* private_key_dict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* public_key_dict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];  // top-level dictionary
    
    // Sets the key-type and key-size attributes in the top-level dictionary.
    [dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [dict setObject:[NSNumber numberWithInt:kChosenKeyBitSize] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    // Sets an attribute specifying that the private & public key is to be stored permanently (that is, put them into the keychain).
    
    [private_key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [public_key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    
    // Add the application tags to the dictionary for the private & public keys.
    
    [private_key_dict setObject:pri_application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [public_key_dict setObject:pub_application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    
    // Add the dictionaries of private & public key attributes to the top-level dictionary.
    
    [dict setObject:private_key_dict forKey:(__bridge id)kSecPrivateKeyAttrs];
    [dict setObject:public_key_dict forKey:(__bridge id)kSecPublicKeyAttrs];
    
    // Generates the key pair.
    OSStatus status = noErr;
    status = SecKeyGeneratePair((__bridge CFDictionaryRef)dict, &publicKeyRef, &privateKeyRef);
    if (status != noErr) {
        // Error handling ...
        NSLog(@"PersonalDataController:genAsymmetricKeys: ERROR: TODO(aka) SecKeyGeneratePair() failed: %d", (int)status);
        return;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:genAsymmetricKeys: generated asymmetric keys using indexes: %s, and %s, privateKeyRef: %d, publicKeyRef: %d.", [public_key_identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [private_key_identity cStringUsingEncoding: [NSString defaultCStringEncoding]], ((privateKeyRef == NULL) ? false : true), ((publicKeyRef == NULL) ? false : true));
}

- (NSData*) decryptSymmetricKey:(NSData*)encrypted_symmetric_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:decryptSymmetricKey: called.");
    
    if (encrypted_symmetric_key == nil) {
        NSLog(@"PersonalDataController:decryptSymmetricKey: symmetric key is nil!");
        return nil;
    }
    
    // Grab our private key.
    SecKeyRef private_key = [self privateKeyRef];
    if (private_key == NULL) {
        NSLog(@"PersonalDataController:decryptSymmetricKey: private key is nil!");
        return nil;
    }
    
    // Calculate the buffer sizes.
    size_t cipher_block_size = SecKeyGetBlockSize(private_key);
    size_t decryption_buf_size = [encrypted_symmetric_key length];  // key will be same length
    
    // Note, when using pkcs1 padding (which we are), the maximum amount of data we can encrypt is 11 bytes less than the block length associated with the public key.
    
    if (decryption_buf_size > cipher_block_size) {
        NSLog(@"PersonalDataController:decryptSymmetricKey: TODO(aka) encrypted symmetric key (%ld) is too large for the private key's block size %ld.", decryption_buf_size, cipher_block_size);
        return nil;    
    }
    
    // Allocate the decryption buffer.
    uint8_t* decryption_buf = NULL;
    decryption_buf = (uint8_t*)malloc(decryption_buf_size * sizeof(uint8_t));
    if (decryption_buf == NULL) {
        NSLog(@"PersonalDataController:decryptSymmetricKey: unable to malloc cipher text buffer.");
        return nil;    
    }
    memset((void*)decryption_buf, 0x0, decryption_buf_size);
    
    // Decrypt using the private key.
    OSStatus status = noErr;
    status = SecKeyDecrypt(private_key,
                           kSecPaddingPKCS1,
                           (const uint8_t*)[encrypted_symmetric_key bytes],
                           cipher_block_size,
                           decryption_buf,
                           &decryption_buf_size
                           );
    if (status != noErr) {
        NSLog(@"PersonalDataController:decryptSymmetricKey: ERROR: SecKeyDecrypt() failed: %d.", (int)status);
        return nil;
    }
    
    // Encode symmetric key as a NSData object.
    NSData* symmetric_key = [NSData dataWithBytes:(const void*)decryption_buf length:(NSUInteger)decryption_buf_size];
    
    if (decryption_buf) 
        free(decryption_buf);
    
    return symmetric_key;
}

- (NSString*) decryptString:(NSString*)encrypted_string_b64 decryptedString:(NSString**)string {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:decryptString:decryptedString: called.");
    
    if (encrypted_string_b64 == nil) {
        return @"PersonalDataController:decryptString: string is nil!";
    }
    
    // Grab our private key.
    SecKeyRef private_key = [self privateKeyRef];
    if (private_key == NULL) {
        return @"PersonalDataController:decryptString: private key is nil!";
    }
    
    // Convert our base64 NSString to a NSData.
    NSData* encrypted_data = [NSData dataFromBase64String:encrypted_string_b64];
    
    // TODO(aka) If decryptSymmetricKey() was actually decryptData(), then we could simply call that routine at this point!
    
    // Calculate the buffer sizes.
    size_t cipher_block_size = SecKeyGetBlockSize(private_key);
    size_t decryption_buf_size = [encrypted_data length];  // unencrypted data will be no bigger
    
    // Note, when using pkcs1 padding (which we are), the maximum amount of data we can encrypt is 11 bytes less than the block length associated with the public key.
    
    if (decryption_buf_size > cipher_block_size) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:decryptString: TODO(aka) encrypted symmetric key (%ld) is too large for the private key's block size %ld.", decryption_buf_size, cipher_block_size];
        return error_msg;
    }
    
    // Allocate the decryption buffer.
    uint8_t* decryption_buf = NULL;
    decryption_buf = (uint8_t*)malloc(decryption_buf_size * sizeof(uint8_t));
    if (decryption_buf == NULL) {
        return @"PersonalDataController:decryptString: unable to malloc cipher text buffer.";
    }
    memset((void*)decryption_buf, 0x0, decryption_buf_size);
    
    // Decrypt using the private key.
    OSStatus status = noErr;
    status = SecKeyDecrypt(private_key,
                           kSecPaddingPKCS1,
                           (const uint8_t*)[encrypted_data bytes],
                           cipher_block_size,
                           decryption_buf,
                           &decryption_buf_size
                           );
    if (status != noErr) {
        if (decryption_buf)
            free(decryption_buf);
        
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:decryptString: ERROR: SecKeyDecrypt() failed: %d.", (int)status];
        return error_msg;
    }
    
    // Encode the decrypted buf as a NSData object, then convert it to the passed in NSString.
    NSData* data = [NSData dataWithBytes:(const void*)decryption_buf length:(NSUInteger)decryption_buf_size];
    *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (decryption_buf)
        free(decryption_buf);
    
    return nil;
}

#pragma mark - Cryptography Class functions

+ (NSString*) queryKeyRef:(NSData*)application_tag keyRef:(SecKeyRef*)key_ref {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:queryKeyRef: called.");
    
    if (application_tag == nil || [application_tag length] == 0) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:queryKeyRef: ERROR: application tag nil or empty."];
        return error_msg;
    }
    
    if (kDebugLevel > 0) {
        // For Debugging: Get all the attributes associated with our match.
        
        // Setup the asymmetric key query dictionary.
        NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
        [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
        
        // Attempt to get the key's attributes from the key chain.
        CFDictionaryRef return_dict_ref = NULL;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&return_dict_ref);
        if (status != noErr) {
            NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:queryKeyRef: ERROR: SecItemCopyMatching() failed using tag: %s, error: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
            return error_msg;
        } else {
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:queryKeyRef: %s, SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_dict description], return_dict_ref);
        }
    }
    
    // Setup the asymmetric key query dictionary.
    NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
    [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Attempt to get the key reference from the key chain.
    
    NSLog(@"PersonalDataController:queryKeyRef: TODO(aka) Get brave and change code to passin the SecKeyRef* as a CFTypeRef* in SecItemCopyMatching!");
    
    *key_ref = NULL;
    SecKeyRef sec_key_ref = NULL;
    OSStatus status = noErr;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&sec_key_ref);
    //status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)key_ref);
    if (status != noErr) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:queryKeyRef: ERROR: SecItemCopyMatching() failed using tag: %s, error: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
        return error_msg;
    } else {
        if (sec_key_ref == NULL) {
            if (kDebugLevel > 0)
                NSLog(@"PersonalDataController:queryKeyRef: SecItemCopyMatching() call successful using tag: %s, but key not found in key-chain.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:queryKeyRef: SecItemCopyMatching() call successful using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if (kDebugLevel > 1)
        NSLog(@"PersonalDataController:queryKeyRef: after SecItemCopyMatching, sec_key_ref is %d!", (sec_key_ref == NULL) ? false : true);
    
    *key_ref = sec_key_ref;
    
    return nil;
}

+ (NSString*) queryKeyData:(NSData*)application_tag keyData:(NSData**)key_data {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:queryKeyData: called.");
    
    if (kDebugLevel > 0) {
        // For Debugging: Get all the attributes associated with our match.
        
        // Setup the asymmetric key query dictionary.
        NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
        [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
        
        // Attempt to get the key's attributes from the key chain.
        CFDictionaryRef return_dict_ref = NULL;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&return_dict_ref);
        if (status != noErr) {
            NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:queryKeyData: ERROR: SecItemCopyMatching() failed using tag: %s, error: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
            return error_msg;
        } else {
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:queryKeyData: %s, SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_dict description], return_dict_ref);
        }
    }
    
    // Setup the asymmetric key query dictionary.
    NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
    [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    
    // Attempt to get the key data from the key chain.
    *key_data = nil;
    CFTypeRef key_data_ref = NULL;
    OSStatus status = noErr;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&key_data_ref);
    if (status != noErr) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:queryKeyData: ERROR: SecItemCopyMatching() failed using tag: %s, error: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
        return error_msg;
    } else {
        if (key_data_ref == NULL) {
            if (kDebugLevel > 0)
                NSLog(@"PersonalDataController:queryKeyData: SecItemCopyMatching() successful using tag: %s, but key not found in key-chain.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            return nil;
        }
    }
    
    *key_data = (__bridge_transfer NSData*)key_data_ref;
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:queryKeyData: SecItemCopyMatching() call successful using tag: %s, returning %lub key.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (unsigned long)[*key_data length]);
    
    return nil;
}

#if 0
+ (NSData*) queryKeyData:(NSData*)application_tag {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:queryKeyData: called.");
    
    NSLog(@"PersonalDataController:queryKeyData: TODO(aka) This routine needs to return the error message and pass in a pointer to the SecKeyRef!");
    
    // Setup the asymmetric key query dictionary.
    NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
    [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    
    // Attempt to get the key data from the key chain.
    CFTypeRef key_data_ref = NULL;
    OSStatus status = noErr;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&key_data_ref);
    if (status != noErr) {
        NSLog(@"PersonalDataController:queryKeyData: ERROR: SecItemCopyMatching() failed using tag: %s, error: %ld.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], status);
        return nil;
    } else {
        if (key_data_ref == NULL) {
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:queryKeyData: SecItemCopyMatching() successful using tag: %s, but key not found in key-chain.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            return nil;
        }
    }
    
    NSData* key = (__bridge_transfer NSData*)key_data_ref;
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:queryKeyData: SecItemCopyMatching() call successful using tag: %s, returning %db key.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key length]);
    
    return key;
}
#endif

+ (NSString*) saveKeyData:(NSData*)key_data withTag:(NSData*)application_tag {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:saveKeyData: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveKeyData: using %luB key and tag: %s.", (unsigned long)[key_data length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // First, see if *an* object is already in the key-chain with the same applicatino tag, if so, remove it, because I don't think SecItemAdd() will overwrite an object.
    
    SecKeyRef tmp_sec_key_ref = NULL;
    NSString* error_msg = [PersonalDataController queryKeyRef:application_tag keyRef:&tmp_sec_key_ref];
    if (error_msg != nil) {
        NSLog(@"PersonalDataController:saveKeyData: TODO(aka) queryKeyRef() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        // We successfully queried *an entry* for the key, so delete it.
        [PersonalDataController deleteKeyRef:application_tag];
        
        // Make sure the delete did what we think it did.
        if (kDebugLevel > 0) {
            // For Debugging: Get all the attributes associated with our match.
            
            // Setup the asymmetric key query dictionary.
            NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
            [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
            [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
            [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
            [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
            
            // Attempt to get the key's attributes from the key chain.
            CFDictionaryRef return_dict_ref = NULL;
            OSStatus status = noErr;
            status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&return_dict_ref);
            if (status != noErr) {
                NSLog(@"PersonalDataController:saveKeyData: deleteKeyRef(%s) worked!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            } else {
                if (kDebugLevel > 1)
                    NSLog(@"PersonalDataController:saveKeyData: ERROR: after deleteKeyRef(%s), SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_dict description], return_dict_ref);
            }
        }
    }
    
    // Setup the asymmetric key query dictionary.
    NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
    [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    // XXX [key_dict setObject:[NSNumber numberWithInt:kChosenKeyBitSize] forKey:(__bridge id)kSecAttrKeySizeInBits];
    [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [key_dict setObject:key_data forKey:(__bridge id)kSecValueData];
    [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
    //[key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    // Attempt to store the key data into the key chain.
    CFDictionaryRef return_dict_ref = NULL;
    OSStatus status = noErr;
    status = SecItemAdd((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&return_dict_ref);
    if (status != noErr) {
        if (status == errSecDuplicateItem) {
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:saveKeyData: SecItemAdd() returned errSecDuplicateItem using tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:saveKeyData: SecItemAdd() failed using tag: %s, error: %d!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status];
            return error_msg;
        }
    } else if (kDebugLevel > 1) {
        NSLog(@"PersonalDataController:saveKeyData: %s, SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_dict description], return_dict_ref);
    }
    
    // XXX if (persistKey != nil) CFRelease(persistKey);
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:saveKeyData:withTag: added %luB key using tag: %s.", (unsigned long)[key_data length], [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}

+ (void) deleteKeyRef:(NSData*)application_tag {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:deleteKeyRef: called.");
    
    // Setup the asymmetric key query dictionary.
    NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
    [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
    [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Attempt to delete the key ref from the key chain.
    OSStatus status = noErr;
    status = SecItemDelete((__bridge CFDictionaryRef)key_dict);
    if (status != noErr && status != errSecItemNotFound) {
        NSLog(@"PersonalDataController:deleteKeyRef: ERROR: SecItemDelete() failed using tag: %s, error: %d.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], (int)status);
        return;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:deleteKeyRef: SecItemDeleteKey() successful for tag: %s.", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

+ (NSString*) hashAsymmetricKey:(NSData*)asymmetric_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:hashAsymmetricKey: called.");
    
    // Get a buffer to hold the hashed key.
    uint8_t* hash_buf = (uint8_t*)malloc(CC_SHA256_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void*)hash_buf, 0x0, CC_SHA256_DIGEST_LENGTH);
    
    // Initialize the Common-Crypto SHA256 context and execute the hash.
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, (void*)[asymmetric_key bytes], (CC_LONG)[asymmetric_key length]);
    CC_SHA256_Final(hash_buf, &ctx);
    
    // Convert the hash to a NSString for consumption.
    NSMutableString* hash = [NSMutableString stringWithCapacity:(CC_SHA256_DIGEST_LENGTH * 2)];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
        [hash appendFormat:@"%02x", hash_buf[i]];  // change to hex
    
    if (hash_buf)
        free(hash_buf);
    
    if (kDebugLevel > 1)
        NSLog(@"PersonalDataController:hashAsymmetricKey: generated %s.", [hash cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return hash;
}

+ (NSString*) hashSHA256Data:(NSData*)data {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:hashSHA256Data: called.");
    
    // Note, CC_SHA256_DIGEST_LENGTH == 32 bytes.
    
    // Get a buffer to hold the hashed key.
    uint8_t* hash_buf = (uint8_t*)malloc(CC_SHA256_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void*)hash_buf, 0x0, CC_SHA256_DIGEST_LENGTH);
    
    // Initialize the Common-Crypto SHA256 context and execute the hash.
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, (void*)[data bytes], (CC_LONG)[data length]);
    CC_SHA256_Final(hash_buf, &ctx);
    
    // Convert the hash to a NSString for consumption.
    NSMutableString* hash = [NSMutableString stringWithCapacity:(CC_SHA256_DIGEST_LENGTH * 2)];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
        [hash appendFormat:@"%02x", hash_buf[i]];  // change to hex
    
    if (hash_buf)
        free(hash_buf);
    
    if (kDebugLevel > 1)
        NSLog(@"PersonalDataController:hashSHA256Data: generated %s.", [hash cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return hash;
}

+ (NSString*) hashMD5Data:(NSData*)data {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:hashMD5Data: called.");
    
    // Note, CC_MD5_DIGEST_LENGTH == 16 bytes.
    
    // Get a buffer to hold the hashed key.
    uint8_t* hash_buf = (uint8_t*)malloc(CC_MD5_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void*)hash_buf, 0x0, CC_MD5_DIGEST_LENGTH);
    
    // Initialize the Common-Crypto MD5 context and execute the hash.
    CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);
    CC_MD5_Update(&ctx, (void*)[data bytes], (CC_LONG)[data length]);
    CC_MD5_Final(hash_buf, &ctx);
    
    // Convert the hash to a NSString for consumption.
    NSMutableString* hash = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hash appendFormat:@"%02x", hash_buf[i]];  // change to hex
    
    if (hash_buf)
        free(hash_buf);
    
    if (kDebugLevel > 1)
        NSLog(@"PersonalDataController:hashMD5Data: generated %s.", [hash cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return hash;
}

+ (NSString*) hashMD5String:(NSString*)string {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:hashMD5String: called.");
    
    // Note, we use MD5 in here, as we're not looking for strong pre-image resistance, but we are looking to save as much bytes as possible (to make our QR codes easier to manage!).  That is, CC_MD5_DIGEST_LENGTH == 16 bytes.
    
    // Convert our string to data.
    NSData* data = [string dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    // Get a buffer to hold the hashed string.
    uint8_t* hash_buf = (uint8_t*)malloc(CC_MD5_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void*)hash_buf, 0x0, CC_MD5_DIGEST_LENGTH);
    
    // Initialize the Common-Crypto MD5 context and execute the hash.
    CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);
    CC_MD5_Update(&ctx, (void*)[data bytes], (CC_LONG)[data length]);
    CC_MD5_Final(hash_buf, &ctx);
    
    // Convert the hash buffer to a NSString for consumption.
    NSMutableString* hash = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hash appendFormat:@"%02x", hash_buf[i]];  // change to hex
    
    if (hash_buf)
        free(hash_buf);
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:hashMD5String: genenerated %s.", [hash cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return hash;
}

+ (NSData*) encryptSymmetricKey:(NSData*)symmetric_key publicKeyRef:(SecKeyRef)public_key_ref {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: called.");
    
    if (symmetric_key == nil) {
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: ERROR: Symmetric key is nil.");
        return nil;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: symmetric key: %luB.", (unsigned long)[symmetric_key length]);
    }
    
    if (public_key_ref == NULL) {
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: ERROR: Public key is nil.");
        return nil;
    }
    
    // Calculate the buffer sizes.
    size_t plain_text_buf_size = [symmetric_key length];
    size_t cipher_block_size = SecKeyGetBlockSize(public_key_ref);
    
    // Note, when using pkcs1 padding (which we are), the maximum amount of data we can encrypt is 11 bytes less than the block length associated with the public key.
    
    if (plain_text_buf_size > (cipher_block_size - 11)) {
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: TODO(aka) symmetric key (%ld) is too large for the public key's block size %ld (- 11).", plain_text_buf_size, cipher_block_size);
        return nil;
    }
    
    size_t cipher_text_buf_size = cipher_block_size;  // to avoid confusion later on
    
    // Allocate the cipher text buffer.
    uint8_t* cipher_text_buf = NULL;
    cipher_text_buf = (uint8_t*)malloc(cipher_text_buf_size * sizeof(uint8_t));
    if (cipher_text_buf == NULL) {
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: unable to malloc cipher text buffer.");
        return nil;
    }
    memset((void*)cipher_text_buf, 0x0, cipher_text_buf_size);
    
    // Encrypt using the public key.
    OSStatus sanityCheck = noErr;
    sanityCheck = SecKeyEncrypt(public_key_ref,
                                kSecPaddingPKCS1,
                                (const uint8_t*)[symmetric_key bytes],
                                plain_text_buf_size,
                                cipher_text_buf,
                                &cipher_text_buf_size
                                );
    if (sanityCheck != noErr) {
        NSLog(@"PersonalDataController:encryptSymmetricKey:publicKeyRef: ERROR: SecKeyEncrypt() failed: %d.", (int)sanityCheck);
        return nil;
    }
    
    // Encode cipher text as a NSData object.
    NSData* cipher = [NSData dataWithBytes:(const void*)cipher_text_buf length:(NSUInteger)cipher_text_buf_size];
    
    if (cipher_text_buf)
        free(cipher_text_buf);
    
    return cipher;
}

+ (NSString*) encryptString:(NSString*)string publicKeyRef:(SecKeyRef)public_key_ref encryptedString:(NSString**)encrypted_string_b64 {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:encryptString:publicKeyRef: called.");
    
    if (string == nil) {
        return @"PersonalDataController:encryptString:publicKeyRef: ERROR: string is nil.";
    } else {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:encryptString:publicKeyRef: encrypting %s.", [string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    if (public_key_ref == NULL) {
        return @"PersonalDataController:encryptString:publicKeyRef: ERROR: public key is NULL.";
    }
    
    // Convert the NSString to a NSData.
    NSData* plain_text = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // Calculate the buffer sizes.
    size_t plain_text_buf_size = [plain_text length];
    size_t cipher_block_size = SecKeyGetBlockSize(public_key_ref);
    
    // Note, when using pkcs1 padding (which we are), the maximum amount of data we can encrypt is 11 bytes less than the block length associated with the public key.
    
    if (plain_text_buf_size > (cipher_block_size - 11)) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:encryptString:publicKeyRef: TODO(aka) symmetric key (%ld) is too large for the public key's block size %ld (- 11).", plain_text_buf_size, cipher_block_size];
        return error_msg;
    }
    
    size_t cipher_text_buf_size = cipher_block_size;  // to avoid confusion later on
    
    // Allocate the cipher text buffer.
    uint8_t* cipher_text_buf = NULL;
    cipher_text_buf = (uint8_t*)malloc(cipher_text_buf_size * sizeof(uint8_t));
    if (cipher_text_buf == NULL) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:encryptString:publicKeyRef: unable to malloc cipher text buffer."];
        return error_msg;
    }
    memset((void*)cipher_text_buf, 0x0, cipher_text_buf_size);
    
    // Encrypt using the public key.
    OSStatus sanityCheck = noErr;
    sanityCheck = SecKeyEncrypt(public_key_ref,
                                kSecPaddingPKCS1,
                                (const uint8_t*)[plain_text bytes],
                                plain_text_buf_size,
                                cipher_text_buf,
                                &cipher_text_buf_size
                                );
    if (sanityCheck != noErr) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:encryptString:publicKeyRef: ERROR: SecKeyEncrypt() failed: %d.", (int)sanityCheck];
        if (cipher_text_buf)
            free(cipher_text_buf);
        
        return error_msg;
    }
    
    // Encode cipher text buffer as a NSData object, then convert it to the passed in NSString.
    NSData* cipher_text = [NSData dataWithBytes:(const void*)cipher_text_buf length:(NSUInteger)cipher_text_buf_size];
    
#if 0
    // For Debugging: I don't understand the difference in encodings here ...
    NSLog(@"PersonalDataController:encryptString:publicKeyRef: cipher text(%d) with default encoding: %s.", [cipher_text length], [[[NSString alloc] initWithData:cipher_text encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    NSLog(@"PersonalDataController:encryptString:publicKeyRef: cipher text(%d) with UTF8 encoding: %s.", [cipher_text length], [[[NSString alloc] initWithData:cipher_text encoding:NSUTF8StringEncoding] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#endif
    
    *encrypted_string_b64 = [cipher_text base64EncodedString];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:encryptString:publicKeyRef: encrypted string %s.", [*encrypted_string_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if (cipher_text_buf)
        free(cipher_text_buf);
    
    return nil;
}

+ (NSData*) encryptLocationData:(NSData*)location_data dataSize:(size_t)data_size symmetricKey:(NSData*) symmetric_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: called.");
    
    // Encrypt with symmetric key (using the CommonCrypto library).
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: cipher block size: %ld, plain text size: %ld.", kChosenCipherBlockSize, data_size);
    
    // Setup an initialization vector.
    uint8_t iv[kChosenCipherBlockSize];
    if (SecRandomCopyBytes(kSecRandomDefault, kChosenCipherBlockSize, iv) != 0) {
        NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: ERROR: TODO(aka) unable to generate IV!");
        memset((void*)iv, 0x0, (size_t)sizeof(iv));  // make it all zeros, for now
    }
    
    // Set aside space for the cipher-text buffer.  Note, this is guarenteed to be no bigger than the plain-text size plus one cipher-block size (for a block cipher).
    
    // TODO(aka) We can use CCCryptorGetOutputLength() to get the exact amount we need, but that requires setting up a CCCryptor reference first (via CCCryptorCreate()).
    
    size_t cipher_buf_size = [location_data length] + kChosenCipherBlockSize;
    uint8_t* cipher_text = (uint8_t*)malloc(cipher_buf_size * sizeof(uint8_t));
    if (cipher_text == NULL) {
        NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: ERROR: TODO(aka) unable to malloc cipher-text buffer for encryption!");
        return nil;
    }
    
    size_t bytes_encrypted = 0;  // number of bytes moved into cipher-text buffer
    CCCryptorStatus ccStatus = kCCSuccess;
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithmAES128,
                       kCCOptionPKCS7Padding,
                       (const void*)[symmetric_key bytes],
                       kChosenCipherKeySize,
                       iv,
                       (const void*)[location_data bytes],
                       [location_data length],
                       (void*)cipher_text,
                       cipher_buf_size,
                       &bytes_encrypted
                       );
    
    switch (ccStatus) {
        case kCCSuccess:
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: Encrypted %ld bytes of cipher text.", bytes_encrypted);
            break;
        case kCCParamError: // illegal parameter value
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCParamError!");
            break;
        case kCCBufferTooSmall: // insufficent buffer provided for specified operation
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCBufferTooSmall!");
            break;
        case kCCMemoryFailure:  // memory allocation failure
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCMemoryFailure!");
            break;
        case kCCAlignmentError:  // input size was not aligned properly
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCAlignmentError!");
            break;
        case kCCDecodeError:  // input data did not decode or decrypt properly
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        case kCCUnimplemented:  // function not implemented for the current algorithm
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        default:
            NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
    }
    
    /*
     // TODO(aka) Here's the block-by-block method.
     CCCryptorRef thisEncipher = NULL;  // symmetric crypto reference
     NSData* cipherOrPlainText = nil;  // cipher Text container
     uint8_t* bufferPtr = NULL;  // Pointer to output buffer
     size_t bufferPtrSize = 0;  // Total size of the buffer.
     size_t remainingBytes = 0;  // Remaining bytes to be performed on.
     size_t totalBytesWritten = 0;  // Placeholder for total written.
     uint8_t* ptr;  // A friendly helper pointer.
     size_t movedBytes = 0;  // Number of bytes moved to buffer.
     
     // We don't want to toss padding on if we don't need to
     if (encryptOrDecrypt == kCCEncrypt) {
     if (*pkcs7 != kCCOptionECBMode) {
     if ((plainTextBufferSize % kChosenCipherBlockSize) == 0) {
     *pkcs7 = 0x0000;
     } else {
     *pkcs7 = kCCOptionPKCS7Padding;
     }
     }
     } else if (encryptOrDecrypt != kCCDecrypt) {
     LOGGING_FACILITY1( 0, @"Invalid CCOperation parameter [%d] for cipher context.", *pkcs7 );
     }
     
     // Create and Initialize the crypto reference.
     CCCryptorStatus ccStatus = kCCSuccess;
     ccStatus = CCCryptorCreate(kCCEncrypt,
     kCCAlgorithmAES128,
     *pkcs7,
     (const void *)[symmetricKey bytes],
     kChosenCipherKeySize,
     (const void *)iv,
     &thisEncipher
     );
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem creating the context, ccStatus == %d.", ccStatus );
     
     // Calculate byte block alignment for all calls through to and including final.
     bufferPtrSize = CCCryptorGetOutputLength(thisEncipher, plainTextBufferSize, true);
     
     // Allocate buffer.
     bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t) );
     
     // Zero out buffer.
     memset((void *)bufferPtr, 0x0, bufferPtrSize);
     
     // Initialize some necessary book keeping.
     
     ptr = bufferPtr;
     
     // Set up initial size.
     remainingBytes = bufferPtrSize;
     
     // Actually perform the encryption or decryption.
     ccStatus = CCCryptorUpdate( thisEncipher,
     (const void *) [plainText bytes],
     plainTextBufferSize,
     ptr,
     remainingBytes,
     &movedBytes
     );
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with CCCryptorUpdate, ccStatus == %d.", ccStatus );
     
     // Handle book keeping.
     ptr += movedBytes;
     remainingBytes -= movedBytes;
     totalBytesWritten += movedBytes;
     
     // Finalize everything to the output buffer.
     ccStatus = CCCryptorFinal(  thisEncipher,
     ptr,
     remainingBytes,
     &movedBytes
     );
     
     totalBytesWritten += movedBytes;
     
     if (thisEncipher) {
     (void) CCCryptorRelease(thisEncipher);
     thisEncipher = NULL;
     }
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with encipherment ccStatus == %d", ccStatus );
     
     cipherOrPlainText = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)totalBytesWritten];
     
     if (bufferPtr) free(bufferPtr);
     
     return cipherOrPlainText;
     */
    
    /*
     // TODO(aka) And here's another method ...
     OSStatus status = noErr;
     status = SecKeyEncrypt(key, kSecPaddingPKCS1, plain_text, locationStr.length, cipher_text, &cipher_len);
     if (status != noErr) {
     NSLog(@"PersonalDataController:locationManager:didUpdateToLocation:fromLocation: SecKeyEncrypt failed: %ld.", status);
     }
     */
    
    // Prefix the IV to the encrypted location data and format the bundle as an NSData object.
    size_t bundle_size = kChosenCipherBlockSize + bytes_encrypted;
    NSMutableData* bundle = [NSMutableData dataWithLength:bundle_size];
    [bundle setData:[[NSData alloc] initWithBytes:(const void*)iv length:kChosenCipherBlockSize]];
    [bundle appendBytes:(const void*)cipher_text length:bytes_encrypted];
    
    if (cipher_text)
        free(cipher_text);
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:encryptLocationData:dataSize:symmetricKey: returning %ld byte iv + cipher-text bundle.", bundle_size);
    
    return bundle;
}

+ (NSString*) decryptData:(NSData*)encrypted_bundle bundleSize:(NSInteger)bundle_size symmetricKey:(NSData*)symmetric_key decryptedData:(NSData**)decrypted_data  {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:decryptData:symmetricKey: called.");
    
    // Decrypt the data with the symmetric key (using the CommonCrypto library).
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:decryptData:symmetricKey: cipher block size: %ld, cipher buf size: %ld, key hash: %s.", kChosenCipherBlockSize, (long)bundle_size, [[PersonalDataController hashSHA256Data:symmetric_key] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Set aside space for the plain-text buffer.  Note, this is guarenteed to be no bigger than the cipher-text size plus one cipher-block size (for a block cipher).
    
    size_t plain_text_buf_size = bundle_size + kChosenCipherBlockSize;  // TOOD(aka) bundle_size has IV!
    uint8_t* plain_text = (uint8_t*)malloc(plain_text_buf_size * sizeof(uint8_t));
    if (plain_text == NULL)
        return @"PersonalDataController:decryptData:symmetricKey: unable to malloc plain-text buffer for decryption!";
    
    const uint8_t* cipher_text = [encrypted_bundle bytes];  // move encrypted data to uint_8 buffer
    size_t bytes_decrypted = 0;  // number of bytes moved into plain-text buffer
    CCCryptorStatus ccStatus = kCCSuccess;
    ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithmAES128,
                       kCCOptionPKCS7Padding,
                       (const void*)[symmetric_key bytes],
                       kChosenCipherKeySize,
                       cipher_text,  /* first kChosenCipherBlockSize is the IV */
                       (const void*)(cipher_text + kChosenCipherBlockSize),
                       bundle_size - kChosenCipherBlockSize,
                       (void*)plain_text,
                       plain_text_buf_size,
                       &bytes_decrypted
                       );
    
    NSString* error_msg = nil;
    switch (ccStatus) {
        case kCCSuccess:
            if (kDebugLevel > 1)
                NSLog(@"PersonalDataController:decryptData:symmetricKey: Decrypted %ld bytes of plain text.", bytes_decrypted);
            break;
        case kCCParamError: // illegal parameter value
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCParamError!";
            break;
        case kCCBufferTooSmall: // insufficent buffer provided for specified operation
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCBufferTooSmall!";
            break;
        case kCCMemoryFailure:  // memory allocation failure
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCMemoryFailure!";
            break;
        case kCCAlignmentError:  // input size was not aligned properly
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCAlignmentError!";
            break;
        case kCCDecodeError:  // input data did not decode or decrypt properly
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCDecodeError!";
            break;
        case kCCUnimplemented:  // function not implemented for the current algorithm
            error_msg = @"PersonalDataController:decryptData:symmetricKey: CCCrypt() status: kCCUnimplemented!";
            break;
        default:
            error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:decryptData:symmetricKey: CCCrypt() unknown status: %d.", ccStatus];
            break;
    }
    
    if (error_msg != nil) {
        if (plain_text)
            free(plain_text);
        
        return error_msg;
    }
    
    // Convert the plain-text buffer to a NSData object.
    //*decrypted_data = [[NSData alloc] initWithBytes:(const void*)plain_text length:plain_text_buf_size];
    *decrypted_data = [[NSData alloc] initWithBytes:(const void*)plain_text length:bytes_decrypted];
    
    if (plain_text)
        free(plain_text);
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:decryptData:symmetricKey: returning %ld byte plain text.", bytes_decrypted);
    
    return nil;
}

#pragma mark - QR Code Utilities

- (UIImage*) printQRPublicKey:(CGFloat)width {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:printQRPublicKey: called.");
    
    // Call QRcode to generate a binary buffer of the encoded ID + base-64 public key.
    NSString* id_key_str = [[NSString alloc] initWithFormat:@"id=%s%skey=%s", [_identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQRDelimiter, [[[self getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:printQRPublicKey: Encoding: %s.", [id_key_str UTF8String]);
    
    /**
     * Create a symbol from the string. The library automatically parses the input
     * string and encodes in a QR Code symbol.
     * @warning This function is THREAD UNSAFE.
     * @param string input string. It must be NULL terminated.
     * @param version version of the symbol. If 0, the library chooses the minimum
     *                version for the given input data.
     * @param level error correction level.
     * @param hint tell the library how non-alphanumerical characters should be
     *             encoded. If QR_MODE_KANJI is given, kanji characters will be
     *             encoded as Shif-JIS characters. If QR_MODE_8 is given, all of
     *             non-alphanumerical characters will be encoded as is. If you want
     *             to embed UTF-8 string, choose this.
     * @param casesensitive case-sensitive(1) or not(0).
     * @return an instance of QRcode class. The version of the result QRcode may
     *         be larger than the designated version. On error, NULL is returned,
     *         and errno is set to indicate the error. See Exceptions for the
     *         details.
     * @throw EINVAL invalid input object.
     * @throw ENOMEM unable to allocate memory for input objects.
     *
     * extern QRcode *QRcode_encodeString(const char *string, int version, QRecLevel level, QRencodeMode hint, int casesensitive);
     */

    QRcode* qr_code = NULL;
    if ((qr_code = QRcode_encodeString([id_key_str UTF8String], 0, QR_ECLEVEL_H, QR_MODE_8, 1)) == NULL) {
        NSLog(@"PersonalDataController:printQRPublicKey: ERROR: TODO(aka) QRcode_encodeString() failed!");
        return nil;
    }
    
    // Conver the QRcode to a UIImage.
    UIImage* image = [PersonalDataController qrCodeToUIImage:qr_code width:width];
    
    // Clean up QRcode.
    QRcode_free(qr_code);
    
    return image;
}

- (UIImage*) printQRDeposit:(CGFloat)width {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:printQRDeposit: called.");
    
    // Call QRcode to generate a binary buffer of the encoded deposit.
    QRcode* qr_code = NULL;
    if ((qr_code = QRcode_encodeString([[PersonalDataController absoluteStringDeposit:_deposit] UTF8String], 0, QR_ECLEVEL_H, QR_MODE_8, 0)) == NULL) {
        NSLog(@"PersonalDataController:printQRDeposit: ERROR: QRcode_encodeString() failed!");
        return nil;
    }
    
    // Conver the QRcode to a UIImage.
    UIImage* image = [PersonalDataController qrCodeToUIImage:qr_code width:width];
    
    // Clean up QRcode.
    QRcode_free(qr_code);
    
    return image;
}

#pragma mark - QR Code Class functions

+ (NSString*) printQRString:(NSString*)string width:(CGFloat)width image:(UIImage**)image {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:printQRString:width:image: called.");
    
    if (string == nil)
        return @"PersonalDataController:printQRString: ERROR: string is nil.";
    
    // Call QRcode to generate a binary buffer of the NSString.
    QRcode* qr_code = NULL;
    if ((qr_code = QRcode_encodeString([string UTF8String], 0, QR_ECLEVEL_H, QR_MODE_8, 0)) == NULL) {
        return @"PersonalDataController:printQRString: ERROR: QRcode_encodeString() failed!";
    }
    
    // Conver the QRcode to a UIImage.
    *image = [PersonalDataController qrCodeToUIImage:qr_code width:width];
    
    // Clean up QRcode.
    QRcode_free(qr_code);
    
    return nil;
}

+ (NSString*) parseQRScanResult:(NSString*)scan_result identityHash:(NSString**)identity_hash publicKey:(NSString**)public_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:parseQRScanResult:identityHash:publicKey: called.");
    
    if (scan_result == nil)
        return @"PersonalDataController:parseQRScanResult: ERROR: scan_result is nil.";
    
    // We're expecting a scan result of the form: id=HASH_OF_FOO;key=BASE64_PUB_KEY
    NSArray* key_value_pairs = [scan_result componentsSeparatedByString:[NSString stringWithCString:kQRDelimiter encoding:[NSString defaultCStringEncoding]]];
    for (int i = 0; i < [key_value_pairs count]; ++i) {
        // Grab the key & value.
        NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
        NSRange delimiter = [key_value_pair rangeOfString:@"="];
        NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
        NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
        
        if (kDebugLevel > 1)
            NSLog(@"PersonalDataController:parseQRScanResult: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        if ([key caseInsensitiveCompare:[NSString stringWithCString:kQRKeyIdentityHash encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
            *identity_hash = value;
        } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQRKeyPublicKey encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
            // Grab the base64 encoded public key.
            
            // Note, the base64 representation of the encrypted-key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in the string.
            
            //*public_key = [NSData dataFromBase64String:value];
            *public_key = value;
        } else {
            NSString* error_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:parseQRScanResult: ERROR: unknown QR key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return error_msg;
        }
    }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:parseQRScanResult: scanned id: %s, and key: %s.", [*identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], [*public_key cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}

+ (UIImage*) qrCodeToUIImage:(QRcode*)qr_code width:(CGFloat)width {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:qrCodeToUIImage: called.");
    
    // Map the QRcode buffer to a CGContext via a CGRect.
    
    // Note, the following code to *draw* the QRcode on a CGRect was borrowed (and then heavily modified) from Andrew Kopanev's QR Code Generator (QRCodeGenerator.m) file <andrew@moqod.com>.
    
    // TODO(aka) Change this to not use CGFoo routines, if possible!
    
    // Create and transform the context.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(0, width, width, 8, width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGAffineTransform translate_transform = CGAffineTransformMakeTranslation(0, -width);
    CGAffineTransform scale_transform = CGAffineTransformMakeScale(1, -1);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translate_transform, scale_transform));
    
    // Setup CGRect to draw on.
    float zoom = (double)width / (qr_code->width + 2.0 * qr_margin);
    CGRect cg_rect = CGRectMake(0, 0, zoom, zoom);
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor blackColor].CGColor));
    
    // Loop over *binary* characters in QRcode and print out based on width ...
    unsigned char* data_ptr = qr_code->data;
    for (int i = 0; i < qr_code->width; ++i) {
        for (int j = 0; j < qr_code->width; ++j) {
            if(*data_ptr & 1) {
                cg_rect.origin = CGPointMake((j + qr_margin) * zoom,(i + qr_margin) * zoom);
                CGContextAddRect(ctx, cg_rect);
            }
            
            ++data_ptr;
        }
    }
    
    CGContextFillPath(ctx);
    
    // Convert CGContext to an UIImage.
    CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
    UIImage* image = [UIImage imageWithCGImage:qrCGImage];
    
    // Cleanup CG and QRcode objects.
    CGContextRelease(ctx);
    CGImageRelease(qrCGImage);
    CGColorSpaceRelease(colorSpace);

    return image;
}

#pragma mark - Deposit Class functions

+ (NSArray*) supportedDeposits {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:supportedDeposits: called.");
    
    static NSArray* deposits = nil;
    
    if (deposits == nil)
        deposits = [[NSArray alloc] initWithObjects:[NSString stringWithCString:kDepositNone encoding:[NSString defaultCStringEncoding]], [NSString stringWithCString:kDepositSMS encoding:[NSString defaultCStringEncoding]], [NSString stringWithCString:kDepositEMail encoding:[NSString defaultCStringEncoding]], nil];
    
    return deposits;
}

+ (NSString*) getDepositType:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getDepositType: called.");
    
    if (deposit == nil)
        return @"";
    
    NSString* type = [deposit objectForKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
    return type;
}

+ (NSString*) getDepositPhoneNumber:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getDepositPhoneNumber: called.");
    
    if (deposit == nil)
        return @"";
    
    NSString* number = [deposit objectForKey:[NSString stringWithCString:kDepositKeyPhoneNumber encoding:[NSString defaultCStringEncoding]]];
    return number;
}

+ (NSString*) getDepositAddress:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getDepositAddress: called.");
    
    if (deposit == nil)
        return @"";
    
    NSString* address = [deposit objectForKey:[NSString stringWithCString:kDepositKeyAddress encoding:[NSString defaultCStringEncoding]]];
    return address;
}

+ (void) setDeposit:(NSMutableDictionary*)deposit type:(NSString*)type {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setDeposit:type: called.");
    
    if (deposit == nil)
        deposit = [[NSMutableDictionary alloc] initWithCapacity:5];
    [deposit setObject:type forKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
}

+ (void) setDeposit:(NSMutableDictionary*)deposit phoneNumber:(NSString*)phone_number {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setDeposit:phoneNumber: called.");
    
    if (deposit == nil)
        deposit = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    [deposit setObject:phone_number forKey:[NSString stringWithCString:kDepositKeyPhoneNumber encoding:[NSString defaultCStringEncoding]]];
}

+ (NSURL*) absoluteURLDeposit:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:absoluteURLDeposit: called.");
    
    // TODO(aka) Why do we have this routine?
    
    NSURL* url = nil;
    
    // Build URL based on type.
    if ([PersonalDataController isDepositTypeSMS:deposit]) {
        url = [[NSURL alloc] initWithScheme:[NSString stringWithCString:kDepositSMS encoding:[NSString defaultCStringEncoding]] host:@"" path:[PersonalDataController getDepositPhoneNumber:deposit]];        
    } else if ([PersonalDataController isDepositTypeEMail:deposit]) {
        url = [[NSURL alloc] initWithScheme:[NSString stringWithCString:kDepositEMail encoding:[NSString defaultCStringEncoding]] host:@"" path:[PersonalDataController getDepositAddress:deposit]];        
    } else {
        NSLog(@"PersonalDataController:absoluteURLDeposit: ERROR: unknown type!");
    }
    
    return url;
}

+ (NSString*) absoluteStringDeposit:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:absoluteStringDeposit: called.");
    
    NSString* absolute_string = [[NSString alloc] initWithFormat:@""];
    
    if (deposit == nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
        return absolute_string;
    }
    
    NSEnumerator* enumerator = [deposit keyEnumerator];
    id key = [enumerator nextObject];
    while (key != nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"%s", [[deposit objectForKey:key] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        
        if (key = [enumerator nextObject])
            absolute_string = [absolute_string stringByAppendingFormat:@"%s", kDepositDelimiter];
    }
    
    return absolute_string;
}

+ (NSString*) absoluteStringDebugDeposit:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:absoluteStringDeposit: called.");
    
    NSString* absolute_string = [[NSString alloc] initWithFormat:@"Deposit: "];
    
    if (deposit == nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
        return absolute_string;
    }
    
    NSEnumerator* enumerator = [deposit keyEnumerator];
    id key = [enumerator nextObject];
    while (key != nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"%s=%s", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [[deposit objectForKey:key] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        
        if (key = [enumerator nextObject])
            absolute_string = [absolute_string stringByAppendingFormat:@", "];
    }
    
    return absolute_string;
}

+ (NSMutableDictionary*) stringToDeposit:(NSString*)string {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:stringToDeposit: called.");
    
    if (string == nil)
        return nil;
    
    // A absoluteString deposit looks like type:parameter[:parameter].  So, we break the string up into elements (by our delimiter) and get the remaining parameters based on the type.
    
    NSMutableDictionary* deposit = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionarySize];
    
    NSArray* elements = [string componentsSeparatedByString:[NSString stringWithCString:kDepositDelimiter encoding:[NSString defaultCStringEncoding]]];
    NSString* type = [elements objectAtIndex:0];
    [deposit setObject:type forKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
    if ([type caseInsensitiveCompare:[NSString stringWithCString:kDepositSMS encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
        NSString* number = [elements objectAtIndex:1];
        [deposit setObject:number forKey:[NSString stringWithCString:kDepositKeyPhoneNumber encoding:[NSString defaultCStringEncoding]]];
    } else if ([type caseInsensitiveCompare:[NSString stringWithCString:kDepositEMail encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
        NSString* address = [elements objectAtIndex:1];
        [deposit setObject:address forKey:[NSString stringWithCString:kDepositKeyAddress encoding:[NSString defaultCStringEncoding]]];
    } else {
        NSLog(@"PersonalDataController:stringToDeposit: ERROR: unknown type: %s.", [type cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return nil;
    }
    
    return deposit;
}

// Note, this routine should be used by the consumer.
+ (BOOL) isDepositComplete:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isDepositComplete: called.");
    
    if (deposit == nil)
        return false;
    
    // See if we have a *type*.
    NSString* type = [deposit objectForKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
    if (!type)
        return false;
    
    // See if we have all the components based on the type.
    if ([PersonalDataController isDepositTypeSMS:deposit]) {
        NSString* number = [PersonalDataController getDepositPhoneNumber:deposit];
        if (number == nil || [number length] == 0)
            return false;
    } else if ([PersonalDataController isDepositTypeEMail:deposit]) {
            NSString* address = [PersonalDataController getDepositAddress:deposit];
        if (address == nil || [address length] == 0)
            return false;
    } else {
        NSLog(@"PersonalDataController:isDepositComplete: WARN: unknown type: %s", [[PersonalDataController getDepositType:deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return false;
    }
    
    // If we made it here, the deposit in the dictionary is complete!
    return true;
}

+ (BOOL) isDepositTypeSMS:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isDepositTypeSMS: called.");
    
    if (deposit == nil)
        return false;
    
    // See what file store we are using.
    NSString* type = [deposit objectForKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
    
    // Note, here's how to search for a subset within the string:
    // if ([some_string rangeOfString:@"s3"].location != NSNotFound)
    
    if ([type caseInsensitiveCompare:[NSString stringWithCString:kDepositSMS encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame)
        return true;
    
    return false;
}

+ (BOOL) isDepositTypeEMail:(NSDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isDepositTypeEMail: called.");
    
    if (deposit == nil)
        return false;
    
    // See what file store we are using.
    NSString* type = [deposit objectForKey:[NSString stringWithCString:kDepositKeyType encoding:[NSString defaultCStringEncoding]]];
    
    // Note, here's how to search for a subset within the string:
    // if ([some_string rangeOfString:@"s3"].location != NSNotFound)
    
    if ([type caseInsensitiveCompare:[NSString stringWithCString:kDepositEMail encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:isDepositTypeEMail: Found EMail deposit!");
        return true;
    }
    
    return false;
}

#pragma mark - File-store Class functions

// File Store dictionary class functions (as the Provider Class also uses the file store NSMutableDictionary type).

+ (NSArray*) supportedFileStores {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:supportedFileStores: called.");
    
    static NSArray* stores = nil;
    
    if (stores == nil)
        stores = [[NSArray alloc] initWithObjects:[NSString stringWithCString:kFSNone encoding:[NSString defaultCStringEncoding]], [NSString stringWithCString:kFSAmazonS3 encoding:[NSString defaultCStringEncoding]], nil];
    
    return stores;
}

+ (NSString*) getFileStoreService:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getFileStoreService: called.");
    
    NSString* service = [file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]];
    return service;
}

+ (NSString*) getFileStoreScheme:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getFileStoreScheme: called.");
    
    NSString* scheme = [file_store objectForKey:[NSString stringWithCString:kFSKeyScheme encoding:[NSString defaultCStringEncoding]]];
    return scheme;
}

+ (NSString*) getFileStoreHost:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getFileStoreHost: called.");
    
    NSString* host = [file_store objectForKey:[NSString stringWithCString:kFSKeyHost encoding:[NSString defaultCStringEncoding]]];
    return host;
}

+ (NSString*) getFileStoreAccessKey:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getFileStoreAccessKey: called.");
    
    NSString* key = [file_store objectForKey:[NSString stringWithCString:kFSKeyAccessKey encoding:[NSString defaultCStringEncoding]]];
    return key;
}

+ (NSString*) getFileStoreSecretKey:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:getFileStoreSecretKey: called.");
    
    NSString* key = [file_store objectForKey:[NSString stringWithCString:kFSKeySecretKey encoding:[NSString defaultCStringEncoding]]];
    return key;
}

+ (void) setFileStore:(NSMutableDictionary*)file_store service:(NSString*)service {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setFileStore:service: called.");
    
    if (file_store == nil)
        file_store = [[NSMutableDictionary alloc] initWithCapacity:5];  // TODO(aka) does this work? don't we need a Dict**?
    
    [file_store setObject:service forKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]];
    
    // In some cases, setting the service also determines the scheme and host of the service, so we can set those now, as well.
    
    if ([service caseInsensitiveCompare:[NSString stringWithCString:kFSAmazonS3 encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
        [file_store setObject:[NSString stringWithCString:kFSSchemeHTTPS encoding:[NSString defaultCStringEncoding]] forKey:[NSString stringWithCString:kFSKeyScheme encoding:[NSString defaultCStringEncoding]]];
        [file_store setObject:[NSString stringWithCString:kFSHostAmazonS3 encoding:[NSString defaultCStringEncoding]] forKey:[NSString stringWithCString:kFSKeyHost encoding:[NSString defaultCStringEncoding]]];
    }
}

+ (void) setFileStore:(NSMutableDictionary*)file_store accessKey:(NSString*)access_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setFileStore:accessKey: called.");
    
    if (file_store == nil) {
        NSLog(@"PersonalDataController:setFileStore:accessKey: ERROR: file_store is nil!");
        return;
    }
    
    [file_store setObject:access_key forKey:[NSString stringWithCString:kFSKeyAccessKey encoding:[NSString defaultCStringEncoding]]];
}

+ (void) setFileStore:(NSMutableDictionary*)file_store secretKey:(NSString*)secret_key {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:setFileStore:secretKey: called.");
    
    if (file_store == nil) {
        NSLog(@"PersonalDataController:setFileStore:secretKey: ERROR: file_store is nil!");
        return;
    }
    
    [file_store setObject:secret_key forKey:[NSString stringWithCString:kFSKeySecretKey encoding:[NSString defaultCStringEncoding]]];
}

+ (NSURL*) absoluteURLFileStore:(NSDictionary*)file_store withBucket:(NSString*)bucket_name {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:absoluteURLFileStore:withBucket: called.");
    
    // See what file store we are using.
    if ([PersonalDataController isFileStoreServiceAmazonS3:file_store]) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:absoluteURLFileStore:withBucket: building for S3 service.");
        
        // Build the URL.
        
        // Note, sample Amazon S3 URL: https://s3.amazonaws.com/fe0ef9b7a369180a68e3e85988981e0bac7914cc/location-data.b64
        
        NSString* scheme = [[NSString alloc] initWithCString:kFSSchemeHTTPS encoding:[NSString defaultCStringEncoding]];
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:absoluteURLFileStore:withBucket: file_store has %lu objects.", (unsigned long)[file_store count]);
                                                                                                         
        NSString* host = [file_store objectForKey:[NSString stringWithCString:kFSKeyHost encoding:[NSString defaultCStringEncoding]]];
        NSString* path = [[NSString alloc] initWithFormat:@"/%s/%s", [bucket_name cStringUsingEncoding:[NSString defaultCStringEncoding]], kLocationDataFilename];
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:absoluteURLFileStoreWithBucket: using: %s, %s, and %s.", [scheme cStringUsingEncoding:[NSString defaultCStringEncoding]], [host cStringUsingEncoding:[NSString defaultCStringEncoding]], [path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSURL* url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
        return url;    
    } else {
        NSLog(@"PersonalDataController:absoluteURLFileStoreWithBucket: unknown service: %s", [[file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }       
    
    // If we made it here, something went wrong.
    return nil;
}

+ (NSString*) absoluteStringFileStore:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:absoluteStringFileStore: called.");
    
    NSString* absolute_string = [[NSString alloc] initWithFormat:@"File Store: "];
    
    if (file_store == nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"nil"];
        return absolute_string;
    }
    
    NSEnumerator* enumerator = [file_store keyEnumerator];
    id key = [enumerator nextObject];
    while (key != nil) {
        absolute_string = [absolute_string stringByAppendingFormat:@"%s=%s", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [[file_store objectForKey:key] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        
        if (key = [enumerator nextObject])
            absolute_string = [absolute_string stringByAppendingFormat:@", "];
    }
    
    return absolute_string;
}

// Note, this routine should be used by the consumer.
+ (BOOL) isFileStoreValid:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isFileStoreValid: called.");
    
    if (file_store == nil)
        return false;
    
    // See if we have a *service*.
    NSString* service = [file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]];
    if (!service)
        return false;

    // See if we have all the components based on the service.
    if ([PersonalDataController isFileStoreServiceAmazonS3:file_store]) {
        NSString* scheme = [PersonalDataController getFileStoreScheme:file_store];
        NSString* host = [PersonalDataController getFileStoreHost:file_store];
        if (scheme == nil || [scheme length] == 0 || host == nil || [host length] == 0)
            return false;
    } else {
        NSLog(@"PersonalDataController:isFileStoreValid: WARN: unknown service: %s", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return false;
    }
    
    // If we made it here, there seems to be a valid file-store.
    return true;
}

// Note, this routine should be used by the provider.
+ (BOOL) isFileStoreComplete:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isFileStoreComplete: called.");
    
    if (file_store == nil)
        return false;
    
    if (![PersonalDataController isFileStoreValid:file_store])
        return false;
    
    // See if we have all the components based on the service.
    if ([PersonalDataController isFileStoreServiceAmazonS3:file_store]) {
        NSString* access_key = [PersonalDataController getFileStoreAccessKey:file_store];
        NSString* secret_key = [PersonalDataController getFileStoreSecretKey:file_store];
        if (access_key == nil || [access_key length] == 0 || secret_key == nil || [secret_key length] == 0)
            return false;
    } else {
        NSLog(@"PersonalDataController:isFileStoreComplete: WARN: unknown service: %s", [[PersonalDataController getFileStoreService:file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return false;
    }
    
    // If we made it here, the file-store in the dictionary is complete!
    return true;
}

+ (BOOL) isFileStoreServiceAmazonS3:(NSDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:isFileStoreServiceAmazonS3: called.");
    
    if (file_store == nil)
        return false;
    
    // See what file store we are using.
    NSString* service = [file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]];
    
    // Note, here's how to search for a subset within the string:
    // if ([some_string rangeOfString:@"s3"].location != NSNotFound)
    
    if ([service caseInsensitiveCompare:[NSString stringWithCString:kFSAmazonS3 encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame)
        return true;
    
    return false;
}

#pragma mark - Cloud Management

- (NSString*) uploadLocationData:(NSString*)location_data
                      bucketName:(NSString*)bucket_name {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:uploadLocationData:bucketName: called.");
    
    if (_file_store == nil) {
        NSLog(@"PersonalDataController:uploadLocationData:bucketName: file_store is nil!");
        return @"File Store is not set";
    }
    
    // See what file store we are using.
    if ([PersonalDataController isFileStoreServiceAmazonS3:_file_store]) {
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:uploadLocationData:bucketName: using S3 as file store.");
        
        NSString* filename = [[NSString alloc] initWithFormat:@"%s", kLocationDataFilename];
        NSString* err_msg = [self amazonS3Upload:location_data bucketName:bucket_name filename:filename];
        return err_msg;
    } else {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Unknown service: %s", [[_file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:uploadLocationData:bucketName: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    return nil;
}

- (NSString*) amazonS3Upload:(NSString*)data bucketName:(NSString*)bucket_name filename:(NSString*)filename {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:amazonS3Upload:bucketName:filename: called.");
    
    if (_file_store == nil) {
        NSLog(@"PersonalDataController:uploadLocationData:bucketName: file_store is nil!");
        return @"File Store is not set";
    }
    
    // Make sure we have an Amazon S3 file store.
    if (![PersonalDataController isFileStoreServiceAmazonS3:_file_store]) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:amazonS3Upload:bucketName:filename: service (%s) is not Amazon S3", [[_file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:amazonS3Upload:bucketName: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    // Get S3 parameters.
    NSString* access_key = [_file_store objectForKey:[NSString stringWithCString:kFSKeyAccessKey encoding:[NSString defaultCStringEncoding]]];
    NSString* secret_key = [_file_store objectForKey:[NSString stringWithCString:kFSKeySecretKey encoding:[NSString defaultCStringEncoding]]];
    
    if (access_key == nil || [access_key length] == 0 || secret_key == nil || [secret_key length] == 0) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"PersonalDataController:amazonS3Upload:bucketName:filename: Amazon S3 credentials either empty or null (access key: %s, secret key: %s).", [access_key cStringUsingEncoding:[NSString defaultCStringEncoding]], [secret_key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:amazonS3Upload:bucketName: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"PersonalDataController:amazonS3Upload:bucketName: uploading \"%s\", to %s, as %s.", [data cStringUsingEncoding:[NSString defaultCStringEncoding]], [bucket_name cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // ASW SDK can throw exceptions, joy.
    @try {
        // Initialize the S3 client.
        AmazonS3Client* s3 = [[AmazonS3Client alloc] initWithAccessKey:access_key withSecretKey:secret_key];
        
        // Create the bucket (if it doesn't already exist).
        [s3 createBucket:[[S3CreateBucketRequest alloc] initWithName:bucket_name]];
        
        // Setup the HTTP "PUT" Request ...
        S3PutObjectRequest* request = [[S3PutObjectRequest alloc] initWithKey:filename inBucket:bucket_name];
        request.contentType = @"application/octet-stream";
        request.cannedACL = [S3CannedACL publicRead];
        request.data = [data dataUsingEncoding:[NSString defaultCStringEncoding]];
        
        // ... and send it off to S3.
        [s3 putObject:request];
    }
    @catch (AmazonClientException* exception) {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Amazon S3 upload failure: %s", [exception.message cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:amazonS3Upload:bucketName: %s!", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    return nil;
}

@end