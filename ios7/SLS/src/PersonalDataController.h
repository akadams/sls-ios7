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
#import <AWSS3/AWSS3.h>
#import "GTLDrive.h"

@class Principal;  // TODO(aka) this circular dependancy could be removed if we split the NSDictionary & Crypto Class functions out of here!

// File-store folder & filenames.
#define PDC_ROOT_FOLDER_NAME "SLS"
#define PDC_HISTORY_LOG_FILENAME "history.log"
#define PDC_KEY_BUNDLE_EXTENSION "kb"


@interface PersonalDataController : NSObject <NSCopying> {
    // NSCopying is needed because we (may?) use PDC as a key in a NSDictionary!
    
@private
    SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef;
}

#pragma mark - Local data
@property (copy, nonatomic) NSString* identity;               // our identity
@property (copy, nonatomic) NSString* identity_hash;          // unique ID that's included in messages
@property (copy, nonatomic) NSMutableDictionary* deposit;     // mechanism to receive OOB meta-data

// XXX TODO(aka) The following need to be put in a FileStoreController class!
@property (copy, nonatomic) NSMutableDictionary* file_store;  // where we store our location data; can be nil
@property (retain, nonatomic) AmazonS3Client* s3;             // Amazon S3's object
@property (retain, nonatomic) GTLServiceDrive* drive;         // Google's object
@property (copy, nonatomic) NSMutableDictionary* drive_ids;   // file IDs indexed by folder/filename; Drive API forces access through IDs
@property (copy, nonatomic) NSMutableDictionary* drive_wvls;  // web view links indexed by folder; Drive API's method of getting public URLs

#pragma mark - Initialization
- (id) init;
- (id) copyWithZone:(NSZone*)zone;

#pragma mark - State backup & restore
- (void) loadState;  // XXX TODO(aka) Why doesn't this return an ERROR?
- (void) saveIdentityState;
- (void) saveDepositState;
- (void) saveFileStoreState;

#pragma mark - State Class functions
// XXX TODO(aka) And why don't all of these return an ERROR?
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

// XXX TODO(aka) The following two methods should return an error message!  And make all encryption/decryption routines work on generic NSData and NSString values, as opposed to symmetric_keys, asymmetric_keys, etc.
- (void) genAsymmetricKeys;

// TODO(aka) The next two are deprecated (use asymmetricDecryptData: and asymmetricDecryptString:)
- (NSData*) decryptSymmetricKey:(NSData*)encrypted_symmetric_key;
- (NSString*) decryptString:(NSString*)encrypted_string_b64 decryptedString:(NSString**)string;

#pragma mark - Cryptography Class functions
// XXX + (SecKeyRef) queryKeyRef:(NSData*)application_tag;
+ (NSString*) queryKeyRef:(NSData*)application_tag keyRef:(SecKeyRef*)key_ref;
// XXX + (NSData*) queryKeyData:(NSData*)application_tag;
+ (NSString*) queryKeyData:(NSData*)application_tag keyData:(NSData**)key_data;
+ (NSString*) saveKeyData:(NSData*)key_data withTag:(NSData*)application_tag accessGroup:(NSString*)access_group;
+ (void) deleteKeyRef:(NSData*)application_tag;

+ (NSString*) hashAsymmetricKey:(NSData*)asymmetric_key;  // XXX Deprecated.  TODO(aka) just use hashSHA256Data()!
+ (NSString*) hashSHA256Data:(NSData*)data;
+ (NSString*) hashSHA256String:(NSString*)string;
+ (NSData*) hashSHA256DataToData:(NSData*)data;
+ (NSData*) hashSHA256StringToData:(NSString*)string;
+ (NSString*) hashMD5Data:(NSData*)data;                  // MD5 is used vs. SHA256 to keep hash size smaller in QR Codes
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

#pragma mark - Deposit utilities

// TODO(aka) It's arguable that the below Deposit & File-store Class methods should be instance ones, as the operate on existing data members, however, I think the reasoning is that these could be run on NSDictionary(ies) prior to being inserted into the class!

#pragma mark - Deposit Class functions
+ (NSArray*) supportedDeposits;
+ (NSString*) getDepositType:(NSDictionary*)key_deposit;
+ (NSString*) getDepositPhoneNumber:(NSDictionary*)key_deposit;
+ (NSString*) getDepositAddress:(NSDictionary*)key_deposit;
+ (void) setDeposit:(NSMutableDictionary*)key_deposit type:(NSString*)type;
+ (void) setDeposit:(NSMutableDictionary*)key_deposit phoneNumber:(NSString*)phone_number;

+ (NSString*) serializeDeposit:(NSDictionary*)key_deposit;
+ (NSMutableDictionary*) stringToDeposit:(NSString*)string;  // XXX TODO(aka) should this (and the FS counterpart be called genDepositWithString
+ (NSURL*) genDepositURL:(NSDictionary*)key_deposit;
// XXX deprecated (description: does the same!) + (NSString*) absoluteStringDebugDeposit:(NSDictionary*)key_deposit;

+ (BOOL) isDepositComplete:(NSDictionary*)key_deposit;
+ (BOOL) isDepositTypeSMS:(NSDictionary*)key_deposit;
+ (BOOL) isDepositTypeEMail:(NSDictionary*)key_deposit;

#pragma mark - File-store utilities
- (BOOL) isFileStoreAuthorized;
- (NSString*) genFileStoreKeyBundle:(Principal*)consumer URL:(NSURL**)url;
// XXX - (NSString*) genFileStoreURLAuthority:(NSURL**)url;  // TODO(aka) Not sure if this needs to be an instance or not?
- (NSString*) genFileStoreHistoryLog:(NSString*)policy path:(NSString**)path;

#pragma mark - File-store Class functions
+ (NSArray*) supportedFileStores;
+ (NSString*) getFileStoreScheme:(NSDictionary*)file_store;
+ (NSString*) getFileStoreHost:(NSDictionary*)file_store;
+ (NSNumber*) getFileStoreNonce:(NSDictionary*)file_store;
+ (NSString*) getFileStoreService:(NSDictionary*)file_store;
+ (NSString*) getFileStoreAccessKey:(NSDictionary*)file_store;
+ (NSString*) getFileStoreSecretKey:(NSDictionary*)file_store;
+ (NSString*) getFileStoreKeychainTag:(NSDictionary*)file_store;
+ (NSString*) getFileStoreClientID:(NSDictionary*)file_store;
+ (NSString*) getFileStoreClientSecret:(NSDictionary*)file_store;
+ (void) setFileStore:(NSMutableDictionary*)file_store nonce:(NSNumber*)nonce;
+ (void) setFileStore:(NSMutableDictionary*)file_store service:(NSString*)service;
+ (void) setFileStore:(NSMutableDictionary*)file_store accessKey:(NSString*)access_key;
+ (void) setFileStore:(NSMutableDictionary*)file_store secretKey:(NSString*)secret_key;
+ (void) setFileStore:(NSMutableDictionary*)file_store keychainTag:(NSString*)keychain_tag;
+ (void) setFileStore:(NSMutableDictionary*)file_store clientID:(NSString*)client_id;
+ (void) setFileStore:(NSMutableDictionary*)file_store clientSecret:(NSString*)client_secret;

+ (NSString*) serializeFileStore:(NSDictionary*)file_store;
+ (NSURL*) genFileStoreURLAuthority:(NSDictionary*)file_store;
// XXX + (NSURL*) genFileStoreAbsoluteURL:(NSDictionary*)file_store withBucket:(NSString*)bucket;

+ (BOOL) isFileStoreValid:(NSDictionary*)file_store;
+ (BOOL) isFileStoreComplete:(NSDictionary*)file_store;
+ (BOOL) isFileStoreServiceAmazonS3:(NSDictionary*)file_store;
+ (BOOL) isFileStoreServiceGoogleDrive:(NSDictionary*)file_store;

#pragma mark - Cloud management
//- (NSString*) uploadKeyBundle:(NSString*)data consumer:(Principal*)consumer;  // XXX Deprecated, as Drive requires closure in MVC!
// TODO(aka) We need a routine to append, as opposed to simply uploading data!
//- (NSString*) uploadHistoryLog:(NSString*)data policy:(NSString*)policy;  // XXX Deprecated, as Drive requires closure in MVC!
- (NSString*) amazonS3Auth:(NSString*)access_key secretKey:(NSString*)secret_key;
- (NSString*) amazonS3Upload:(NSString*)data bucket:(NSString*)bucket filename:(NSString*)filename;
- (NSString*) googleDriveInit;
- (NSString*) googleDriveKeychainAuth:(NSString*)keychain_tag clientID:(NSString*)client_id clientSecret:(NSString*)client_secret;
- (BOOL) googleDriveIsAuthorized;
// XXX - (NSString*) googleDriveUpload:(NSString*)data bucket:(NSString*)bucket filename:(NSString*)filename;
// XXX - (NSString*) genFileStoreDepositMsg:(NSString*)consumer_identity_hash withPrecision:(NSNumber*)precision;
// XXX deprecated - (NSString*) uploadData:(NSString*)data bucketName:(NSString*)bucket_name filename:(NSString*)filename;

@end
