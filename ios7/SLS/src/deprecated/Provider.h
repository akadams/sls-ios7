//
//  Provider.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, this class is used in the ProviderListController class, which is used by the ConsumerMasterViewController class.  That is, it is a container for provider information kept by the consumer!  See Consumer and ConsumerListController to see consumer information kept by the provider.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#define PROVIDER_USE_URL 1  // HACK: TODO(aka) Do we want file-store to be a NSURL or NSDictionary!?!

@interface Provider : NSObject <NSCopying, NSCoding> {
@private
    SecKeyRef publicKeyRef;
}

@property (copy, nonatomic) NSString* identity;    // provider's identity
@property (copy, nonatomic) NSString* identity_hash;  // unique ID used in messages (local-identity?)

// TODO(aka) I'm not certain if we want the file store as a URL or in its native format!
#if (PROVIDER_USE_URL == 1)
@property (copy, nonatomic) NSURL* file_store;     // provider's file store
#else
@property (copy, nonatomic) NSMutableDictionary* file_store;  // provider's file store
#endif
@property (copy, nonatomic) NSString* mobile_number;
@property (copy, nonatomic) NSString* email_address;
@property (copy, nonatomic) NSData* key;           // shared symmetric key
@property (copy, nonatomic) NSMutableArray* locations;  // provider's past locations
@property (copy, nonatomic) NSDate* last_fetch;    // date of last fetch
@property (copy, nonatomic) NSNumber* frequency;   // requested seconds between fetches, TODO(aka) make NSTimeInterval?)
@property (nonatomic) BOOL is_focus;

- (id) init;
- (id) initWithIdentity:(NSString*)identity;  // for when we *first* add a new provider
- (id) copyWithZone:(NSZone*)zone;
#if (PROVIDER_USE_URL == 1)
- (void) setFile_store:(NSURL*)file_store;
#else
// TOOD(aka) What we really need is a convertFileStore:(NSURL*)url routine!
- (void) setFile_store:(NSMutableDictionary*)file_store;
#endif
- (SecKeyRef) publicKeyRef;
- (NSData*) getPublicKey;
- (void) setPublicKey:(NSData*)public_key;
- (void) addLocation:(CLLocation*)location;
- (NSTimeInterval) getTimeIntervalToNextFetch;
- (NSString*) absoluteString;
- (NSString*) fetchLocationData;
- (NSString*) downloadLocationData:(NSString**)encrypted_location_data_b64;
- (BOOL) isEqual:(Provider*)provider;

@end
