//
//  PersonalDataController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/21/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "qrencode.h"

// Data members.


@interface PersonalDataController : NSObject <NSCopying> {
    @private
    SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef;
}

#pragma mark - Local data
@property (copy, nonatomic) NSString* identity;               // our identity
@property (copy, nonatomic) NSString* identity_hash;          // unique ID that's included in messages
@property (copy, nonatomic) NSMutableDictionary* deposit;     // mechanism to receive OOB meta-data
@property (copy, nonatomic) NSMutableDictionary* file_store;  // where we store our location data; can be nil

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;

#pragma mark - State backup & restore
- (void) loadState;  // XXX TODO(aka) Why doesn't this return an ERROR?
- (void) saveIdentityState;
- (void) saveDepositState;
- (void) saveFileStoreState;

#pragma mark - State Class functions
+ (void) saveState:(NSString*)filename boolean:(BOOL)boolean;
+ (void) saveState:(NSString*)filename string:(NSString*)string;
+ (void) saveState:(NSString*)filename array:(NSArray*)array;
+ (void) saveState:(NSString*)filename dictionary:(NSDictionary*)dict;
+ (BOOL) loadStateBoolean:(NSString*)filename;
+ (NSString*) loadStateString:(NSString*)filename;
+ (NSArray*) loadStateArray:(NSString*)filename;
+ (NSDictionary*) loadStateDictionary:(NSString*)filename;

#pragma mark - Cryptography management
- (SecKeyRef) publicKeyRef;
- (SecKeyRef) privateKeyRef;
- (NSData*) getPublicKey;

// TODO(aka) The following two methods should return an error message!  And make all encryption/decryption routines work on generic NSData and NSString values, as opposed to symmetric_keys, asymmetric_keys, etc.
- (void) genAsymmetricKeys;

// TODO(aka) The next two are deprecated (use asymmetricDecryptData: and asymmetricDecryptString:)
- (NSData*) decryptSymmetricKey:(NSData*)encrypted_symmetric_key;
- (NSString*) decryptString:(NSString*)encrypted_string_b64 decryptedString:(NSString**)string;

#pragma mark - Cryptography Class functions
// XXX + (SecKeyRef) queryKeyRef:(NSData*)application_tag;
+ (NSString*) queryKeyRef:(NSData*)application_tag keyRef:(SecKeyRef*)key_ref;
// XXX + (NSData*) queryKeyData:(NSData*)application_tag;
+ (NSString*) queryKeyData:(NSData*)application_tag keyData:(NSData**)key_data;
+ (NSString*) saveKeyData:(NSData*)key_data withTag:(NSData*)application_tag;
+ (void) deleteKeyRef:(NSData*)application_tag;

+ (NSString*) hashAsymmetricKey:(NSData*)asymmetric_key;  // Deprecated.  TODO(aka) just use hashSHA256Data()!
+ (NSString*) hashSHA256Data:(NSData*)data;
+ (NSString*) hashSHA256String:(NSString*)string;
+ (NSData*) hashSHA256DataToData:(NSData*)data;
+ (NSData*) hashSHA256StringToData:(NSString*)string;
+ (NSString*) hashMD5Data:(NSData*)data;                  // MD5 is used vs. SHA256 to keep size smaller in QR Codes
+ (NSString*) hashMD5String:(NSString*)string;

+ (NSString*) asymmetricEncryptData:(NSData*)data publicKeyRef:(SecKeyRef)public_key_ref encryptedData:(NSData**)encrypted_data;
+ (NSString*) asymmetricDecryptData:(NSData*)encrypted_data privateKeyRef:(SecKeyRef)private_key_ref data:(NSData**)data;
+ (NSString*) asymmetricEncryptString:(NSString*)plain_text publicKeyRef:(SecKeyRef)public_key_ref encryptedString:(NSString**)cipher_text_b64;
+ (NSString*) asymmetricDecryptString:(NSString*)cipher_text_b64 privateKeyRef:(SecKeyRef)private_key_ref string:(NSString**)plain_text;
+ (NSString*) symmetricEncryptData:(NSData*)data symmetricKey:(NSData*)symmetric_key encryptedData:(NSData**)encrypted_data;
+ (NSString*) symmetricDecryptData:(NSData*)encrypted_data symmetricKey:(NSData*)symmetric_key data:(NSData**)data;

+ (NSString*) signHashData:(NSData*)hash privateKeyRef:(SecKeyRef)private_key_ref signedHash:(NSString**)signed_hash_b64;
+ (NSString*) signHashString:(NSString*)hash privateKeyRef:(SecKeyRef)private_key_ref signedHash:(NSString**)signed_hash_b64;
+ (BOOL) verifySignatureData:(NSData*)hash secKeyRef:(SecKeyRef)public_key_ref signature:(NSData*)signed_hash;
+ (BOOL) verifySignatureString:(NSString*)hash secKeyRef:(SecKeyRef)public_key_ref signature:(NSData*)signed_hash;

#pragma mark - QR Code utilities
- (UIImage*) printQRPublicKey:(CGFloat)width;
- (UIImage*) printQRDeposit:(CGFloat)width;

#pragma mark - QR Code Class functions
+ (NSString*) printQRString:(NSString*)string width:(CGFloat)width image:(UIImage**)image;
+ (NSString*) parseQRScanResult:(NSString*)scan_result identityHash:(NSString**)identity_hash publicKey:(NSString**)public_key;
+ (UIImage*) qrCodeToUIImage:(QRcode*)qr_code width:(CGFloat)width;

#pragma mark - Deposit Class functions
+ (NSArray*) supportedDeposits;
+ (NSString*) getDepositType:(NSDictionary*)key_deposit;
+ (NSString*) getDepositPhoneNumber:(NSDictionary*)key_deposit;
+ (NSString*) getDepositAddress:(NSDictionary*)key_deposit;
+ (void) setDeposit:(NSMutableDictionary*)key_deposit type:(NSString*)type;
+ (void) setDeposit:(NSMutableDictionary*)key_deposit phoneNumber:(NSString*)phone_number;
+ (NSURL*) absoluteURLDeposit:(NSDictionary*)key_deposit;
+ (NSString*) absoluteStringDeposit:(NSDictionary*)key_deposit;
+ (NSString*) absoluteStringDebugDeposit:(NSDictionary*)key_deposit;
+ (NSMutableDictionary*) stringToDeposit:(NSString*)string;
+ (BOOL) isDepositComplete:(NSDictionary*)key_deposit;
+ (BOOL) isDepositTypeSMS:(NSDictionary*)key_deposit;
+ (BOOL) isDepositTypeEMail:(NSDictionary*)key_deposit;

#pragma mark - File-store Class functions
+ (NSArray*) supportedFileStores;
+ (NSString*) getFileStoreService:(NSDictionary*)file_store;
+ (NSString*) getFileStoreScheme:(NSDictionary*)file_store;
+ (NSString*) getFileStoreHost:(NSDictionary*)file_store;
+ (NSString*) getFileStoreAccessKey:(NSDictionary*)file_store;
+ (NSString*) getFileStoreSecretKey:(NSDictionary*)file_store;
+ (void) setFileStore:(NSMutableDictionary*)file_store service:(NSString*)service;
+ (void) setFileStore:(NSMutableDictionary*)file_store accessKey:(NSString*)access_key;
+ (void) setFileStore:(NSMutableDictionary*)file_store secretKey:(NSString*)secret_key;
+ (NSURL*) absoluteURLFileStore:(NSDictionary*)file_store withBucket:(NSString*)bucket_name withFile:(NSString*)file_name;
+ (NSString*) absoluteStringFileStore:(NSDictionary*)file_store;
+ (BOOL) isFileStoreValid:(NSDictionary*)file_store;
+ (BOOL) isFileStoreComplete:(NSDictionary*)file_store;
+ (BOOL) isFileStoreServiceAmazonS3:(NSDictionary*)file_store;

#pragma mark - Cloud management
// XXX - (NSString*) genFileStoreDepositMsg:(NSString*)consumer_identity_hash withPrecision:(NSNumber*)precision;
- (NSString*) uploadData:(NSString*)data bucketName:(NSString*)bucket_name filename:(NSString*)filename;
// TODO(aka) We need a routine to append, as opposed to simply uploading data!
- (NSString*) amazonS3Upload:(NSString*)data bucketName:(NSString*)bucket_name filename:(NSString*)filename;

@end
