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
- (void) loadState;
- (void) saveIdentityState;
- (void) saveDepositState;
- (void) saveFileStoreState;

+ (void) saveState:(NSString*)filename Bool:(BOOL)boolean;
+ (void) saveState:(NSString*)filename string:(NSString*)string;
+ (BOOL) loadStateBool:(NSString*)filename;
+ (NSString*) loadStateString:(NSString*)filename;

#pragma mark - Cryptography management
- (SecKeyRef) publicKeyRef;
- (SecKeyRef) privateKeyRef;
- (NSData*) getPublicKey;

// TODO(aka) The following two methods should return an error message!  And make all encryption/decryption routines work on generic NSData and NSString values, as opposed to symmetric_keys, asymmetric_keys, etc.
- (void) genAsymmetricKeys;
- (NSData*) decryptSymmetricKey:(NSData*)encrypted_symmetric_key;
- (NSString*) decryptString:(NSString*)encrypted_string_b64 decryptedString:(NSString**)string;

// XXX + (SecKeyRef) queryKeyRef:(NSData*)application_tag;
+ (NSString*) queryKeyRef:(NSData*)application_tag keyRef:(SecKeyRef*)key_ref;
// XXX + (NSData*) queryKeyData:(NSData*)application_tag;
+ (NSString*) queryKeyData:(NSData*)application_tag keyData:(NSData**)key_data;
+ (NSString*) saveKeyData:(NSData*)key_data withTag:(NSData*)application_tag;
+ (void) deleteKeyRef:(NSData*)application_tag;

+ (NSString*) hashAsymmetricKey:(NSData*)asymmetric_key;  // TODO(aka) just use hashSHA256Data()!
+ (NSString*) hashSHA256Data:(NSData*)data;
+ (NSString*) hashMD5Data:(NSData*)data;
+ (NSString*) hashMD5String:(NSString*)string;

// TODO(aka) The three below that return NSData need to return ERROR strings!
+ (NSData*) encryptSymmetricKey:(NSData*)symmetric_key publicKeyRef:(SecKeyRef)public_key_ref;
+ (NSString*) encryptString:(NSString*)string publicKeyRef:(SecKeyRef)public_key_ref encryptedString:(NSString**)encrypted_string_b64;
+ (NSData*) encryptLocationData:(NSData*)location_data dataSize:(size_t)data_size symmetricKey:(NSData*) symmetric_key;
+ (NSString*) decryptData:(NSData*)encrypted_bundle bundleSize:(NSInteger)bundle_size symmetricKey:(NSData*)symmetric_key decryptedData:(NSData**)decrypted_data;

#pragma mark - QR Code utilities
- (UIImage*) printQRPublicKey:(CGFloat)width;
- (UIImage*) printQRDeposit:(CGFloat)width;
+ (NSString*) printQRString:(NSString*)string width:(CGFloat)width image:(UIImage**)image;
+ (NSString*) parseQRScanResult:(NSString*)scan_result identityHash:(NSString**)identity_hash publicKey:(NSString**)public_key;
+ (UIImage*) qrCodeToUIImage:(QRcode*)qr_code width:(CGFloat)width;

#pragma mark - Cloud utilities
- (NSString*) uploadLocationData:(NSString*)location_data bucketName:(NSString*)bucket_name;
- (NSString*) amazonS3Upload:(NSString*)data bucketName:(NSString*)bucket_name filename:(NSString*)filename;

#pragma mark - File-store utilities
+ (NSArray*) supportedFileStores;
+ (NSString*) getFileStoreService:(NSDictionary*)file_store;
+ (NSString*) getFileStoreScheme:(NSDictionary*)file_store;
+ (NSString*) getFileStoreHost:(NSDictionary*)file_store;
+ (NSString*) getFileStoreAccessKey:(NSDictionary*)file_store;
+ (NSString*) getFileStoreSecretKey:(NSDictionary*)file_store;
+ (void) setFileStore:(NSMutableDictionary*)file_store service:(NSString*)service;
+ (void) setFileStore:(NSMutableDictionary*)file_store accessKey:(NSString*)access_key;
+ (void) setFileStore:(NSMutableDictionary*)file_store secretKey:(NSString*)secret_key;
+ (NSURL*) absoluteURLFileStore:(NSDictionary*)file_store withBucket:(NSString*)bucket_name;
+ (NSString*) absoluteStringFileStore:(NSDictionary*)file_store;
+ (BOOL) isFileStoreValid:(NSDictionary*)file_store;
+ (BOOL) isFileStoreComplete:(NSDictionary*)file_store;
+ (BOOL) isFileStoreServiceAmazonS3:(NSDictionary*)file_store;

#pragma mark - Deposit utilities
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

@end
