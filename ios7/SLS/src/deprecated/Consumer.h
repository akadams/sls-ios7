//
//  Consumer.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, this class is used in the ConsumerListController class, which is used by the ProviderMasterViewController class.  That is, it is a container for consumer information kept by the provider!  See Provider and ProviderListController to see provider information kept by the consumer.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// Data members.


@interface Consumer : NSObject <NSCopying, NSCoding> {  
    @private
    SecKeyRef publicKeyRef;
}

@property (copy, nonatomic) NSString* identity;       // consumer's identity
@property (copy, nonatomic) NSString* identity_hash;  // unique ID used in messages (local-identity?)
@property (copy, nonatomic) NSMutableDictionary* key_deposit; // preferred location to receive symmetric keys
@property (copy, nonatomic) NSString* mobile_number;
@property (copy, nonatomic) NSString* email_address;
@property (copy, nonatomic) NSNumber* precision;      // precision level of location data

- (id) init;
- (id) initWithIdentity:(NSString*)identity;  // for when we *first* add a new consumer
- (id) copyWithZone:(NSZone*)zone;
- (SecKeyRef) publicKeyRef;
- (NSData*) getPublicKey;
- (void) setPublicKey:(NSData*)public_key;
- (NSString*) absoluteString;
- (BOOL) isEqual:(Consumer*)consumer;

@end
