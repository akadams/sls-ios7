//
//  HCCPotentialPrincipal.h
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>

// Data members.
#import "Principal.h"


// Possible states to be in HCC protocol.
enum {
    HCC_MODE_INITIAL = 0,
    HCC_MODE_CONSUMER_PUBKEY_SENT = 1,
    HCC_MODE_PROVIDER_PUBKEY_RECEIVED = 2,
    HCC_MODE_PROVIDER_CHALLENGE_SENT = 3,
    HCC_MODE_CONSUMER_CHALLENGE_RECEIVED = 4,
    HCC_MODE_CONSUMER_RESPONSE_SENT = 5,
    HCC_MODE_PROVIDER_RESPONSE_VETTED = 6,
    HCC_MODE_PROVIDER_SECRET_QUESTION_INPUT = 7,
    HCC_MODE_PROVIDER_PUBKEY_SENT = 8,            // provider's secret-question piggy-backed in message
    HCC_MODE_CONSUMER_PUBKEY_RECEIVED = 9,
    HCC_MODE_CONSUMER_ANSWER_INPUT = 10,
    HCC_MODE_CONSUMER_SECRET_QUESTION_INPUT = 11,
    HCC_MODE_CONSUMER_CHALLENGE_SENT = 12,        // consumer's secret-question & sq answer piggy-backed in message
    HCC_MODE_PROVIDER_CHALLENGE_RECEIVED = 13,
    HCC_MODE_PROVIDER_ANSWER_INPUT = 14,
    HCC_MODE_PROVIDER_RESPONSE_SENT = 15,         // provider's sq answer piggy-backed in message
    HCC_MODE_CONSUMER_RESPONSE_VETTED = 16,
    HCC_MODE_CONSUMER_DEPOSIT_SENT = 17,          // both nonces piggy-backed in message
    HCC_MODE_PROVIDER_DEPOSIT_RECEIVED = 18,
    HCC_MODE_PROVIDER_DEPOSIT_SENT = 19,
    HCC_MODE_CONSUMER_DEPOSIT_RECEIVED = 20,
};

// TODO(aka) this should really be in a HCCPrincipalsController object!
#define HCC_PRINCIPALS_STATE_FILENAME "hcc-principals"  // note, consumer/provider will apply specific extensions to their state file


@interface HCCPotentialPrincipal : NSObject <NSCoding>

#pragma mark - Local data
@property (copy, nonatomic) Principal* principal;
@property (copy, nonatomic) NSNumber* mode;
@property (copy, nonatomic) NSNumber* our_challenge;
@property (copy, nonatomic) NSNumber* their_challenge;
@property (copy, nonatomic) NSString* our_secret_question;
@property (copy, nonatomic) NSString* their_secret_question;

#pragma mark - Initialization
- (id) init;
- (id) initWithPrincipal:(Principal*)principal;  // for when we *first* add a new principal
- (id) copyWithZone:(NSZone*)zone;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management

@end
