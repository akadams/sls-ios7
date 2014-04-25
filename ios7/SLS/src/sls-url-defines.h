//
//  sls-url-defines.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 6/28/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#ifndef Secure_Location_Sharing_sls_url_defines_h
#define Secure_Location_Sharing_sls_url_defines_h

#define URI_SCHEME_SLS "sls"

// Possible path values within an SLS URI.  Note, first eight (well, nine counting the '/') chars specify processing tab controller!
#define URI_PATH_FILE_STORE "consumer-cloud_fs"  // provider's cloud file-store meta-data
#define URI_PATH_HCC_MSG1   "provider-hcc_msg1"  // consumer's HCC pubkey & identity-token
#define URI_PATH_HCC_MSG2   "consumer-hcc_msg2"  // provider's HCC encrypted nonce challenge
#define URI_PATH_HCC_MSG3   "provider-hcc_msg3"  // consumer's HCC nonce response
#define URI_PATH_HCC_MSG4   "consumer-hcc_msg4"  // provider's HCC pubkey, identity-token & encrypted secret-question
#define URI_PATH_HCC_MSG5   "provider-hcc-msg5"  // consumer's HCC encrypted nonce challenge, secret-question reply & secret-question
#define URI_PATH_HCC_MSG6   "consumer-hcc-msg6"  // provider's HCC encrypted nonce response & secret-question reply
#define URI_PATH_HCC_MSG7   "provider-hcc-msg7"  // consumer's HCC encrypted deposit & both nonces
#define URI_PATH_HCC_MSG8   "consumer-hcc-msg8"  // provider's HCC encrypted deposit

#define URI_PATH_DELIMITER '&'

#define URI_QUERY_KEY_ID "id"
#define URI_QUERY_KEY_FS_URL "fs-url"
#define URI_QUERY_KEY_HL_URL "log"  // XXX TODO(aka) deprecated!
#define URI_QUERY_KEY_KB_URL "kb-url"
#define URI_QUERY_KEY_TIME_STAMP "date"
#define URI_QUERY_KEY_SIGNATURE "sig"
#define URI_QUERY_KEY_PUB_KEY "pubkey"
#define URI_QUERY_KEY_CHALLENGE "challenge"
#define URI_QUERY_KEY_CHALLENGE_RESPONSE "response"
#define URI_QUERY_KEY_SECRET_QUESTION "secret-question"
#define URI_QUERY_KEY_SQ_ANSWER "answer"
#define URI_QUERY_KEY_OUR_CHALLENGE "our-challenge"
#define URI_QUERY_KEY_THEIR_CHALLENGE "their-challenge"
#define URI_QUERY_KEY_DEPOSIT "deposit"

#define URI_QUERY_KEY_ENCRYPTED_KEY "encrypted-key"  // deprecated

#endif
