//
//  security-defines.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/28/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#ifndef Secure_Location_Sharing_security_defines_h
#define Secure_Location_Sharing_security_defines_h

#import <Security/Security.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>


#define CIPHER_KEY_SIZE kCCKeySizeAES128
#define CIPHER_BLOCK_SIZE kCCBlockSizeAES128
//#define SHA256_DIGEST_LENGTH CC_SHA256_DIGEST_LENGTH
//#defien MD5_DIGEST_LENGTH CC_MD5_DIGEST_LENGTH

#define KC_QUERY_KEY_PUBLIC_KEY_EXT ".publickey"
#define KC_QUERY_KEY_PRIVATE_KEY_EXT ".privatekey"
#define KC_QUERY_KEY_SYMMETRIC_KEY_EXT ".key"

#define KC_ACCESS_GROUP_CT "communionable-trust";
#define KC_ACCESS_GROUP_HCC "historical-communication-channels";

#endif
