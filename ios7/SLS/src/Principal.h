//
//  Principal.h
//  SLS
//
//  Created by Andrew K. Adams on 12/4/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#define FILE_STORE_USE_NSURL 1  // HACK: TODO(aka) Do we want file-store to be a NSURL or NSDictionary!?!

@interface Principal : NSObject <NSCopying, NSCoding> {
@private
    SecKeyRef publicKeyRef;
}

#pragma mark - Local variables
@property (copy, nonatomic) NSString* identity;            // provider's identity
@property (copy, nonatomic) NSString* identity_hash;       // unique ID used in messages (local-identity?)
@property (copy, nonatomic) NSString* mobile_number;       // SMS contact #; can be nil
@property (copy, nonatomic) NSString* email_address;       // e-mail; can be nil
@property (copy, nonatomic) NSMutableDictionary* deposit;  // mechanism to receive OOB meta-data

// TODO(aka) I'm not certain if we want the file store as a URL or as a NSMutableDictionary.  The argument for *not* using a dictionary (as we do for our own meta-data in the PersonalDataController) is that we receive it from the other principal as a URL (not a dictionary, as opposed to how we receive the deposit from the other principal!).

#if (FILE_STORE_USE_NSURL == 1)
@property (copy, nonatomic) NSURL* file_store;                // provider's file store (as URL)
#else
@property (copy, nonatomic) NSMutableDictionary* file_store;  // provider's file store (as dict)
#endif

#pragma mark - Data used by ConsumerMaster VC
@property (copy, nonatomic) NSData* key;                      // shared symmetric key given to us by this provider
@property (copy, nonatomic) NSMutableArray* locations;        // history of this provider's past locations
@property (copy, nonatomic) NSDate* last_fetch;               // date of last fetch
@property (copy, nonatomic) NSNumber* frequency;              // requested seconds between fetches; TODO(aka) make NSTimeInterval?)
@property (nonatomic) BOOL is_focus;                          // marks this provider as having the map focus

#pragma mark - Consumer variables
@property (copy, nonatomic) NSNumber* precision;              // precision level for this consumer
@property (nonatomic) BOOL file_store_sent;                   // flag to show consumer has been sent the provider's file-store URL

#pragma mark - Initialization
- (id) init;
- (id) initWithIdentity:(NSString*)identity;  // for when we *first* add a new principal
- (id) copyWithZone:(NSZone*)zone;

#pragma mark - Data management
#if (FILE_STORE_USE_NSURL == 1)
- (void) setFile_store:(NSURL*)file_store;
#else
// TOOD(aka) What we really need is a convertFileStore:(NSURL*)url routine!
- (void) setFile_store:(NSMutableDictionary*)file_store;
#endif
- (SecKeyRef) publicKeyRef;
- (NSData*) getPublicKey;
- (void) setPublicKey:(NSData*)public_key;
- (BOOL) isEqual:(Principal*)principal;

#pragma mark - ConsumerMaster VC utilities
- (void) addLocation:(CLLocation*)location;
- (NSTimeInterval) getTimeIntervalToNextFetch;
- (NSString*) fetchLocationData;
- (NSString*) downloadLocationData:(NSString**)encrypted_location_data_b64;

#pragma mark - ProviderMaster VC utilities
- (NSString*) sendFileStore;

#pragma mark - Debugging routines
- (NSString*) absoluteString;

@end
