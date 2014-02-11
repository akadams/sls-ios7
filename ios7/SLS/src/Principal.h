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
@property (copy, nonatomic) NSURL* key_bundle_url;                // provider's key-bundle file store (as URL)
@property (copy, nonatomic) NSURL* history_log_url;               // provider's history-log file store (as URL)
#else
@property (copy, nonatomic) NSMutableDictionary* file_store_key_bundle;   // provider's key-bundle file store (as dict)
@property (copy, nonatomic) NSMutableDictionary* file_store_history_log;  // provider's history-log file store (as dict)
#endif

#pragma mark - Data used by ConsumerMaster VC
@property (copy, nonatomic) NSData* key;                      // shared symmetric key given to us by this provider
@property (copy, nonatomic) NSMutableArray* history_log;      // array of LocationBundleControllers (i.e., their past history)
@property (copy, nonatomic) NSDate* last_fetch;               // date of last fetch
@property (copy, nonatomic) NSNumber* frequency;              // requested seconds between fetches; TODO(aka) make NSTimeInterval?)
@property (nonatomic) BOOL is_focus;                          // marks this provider as having the map focus

#pragma mark - Data used by the ProviderMaster VC
@property (copy, nonatomic) NSString* policy;                 // precision level for this consumer (dictionary index for sym key!)
@property (nonatomic) BOOL file_store_sent;                   // flag to show consumer has been sent the provider's meta-data URL

#pragma mark - Initialization
- (id) init;
- (id) initWithIdentity:(NSString*)identity;  // for when we *first* add a new principal
- (id) copyWithZone:(NSZone*)zone;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management
#if (FILE_STORE_USE_NSURL == 1)
// TODO(aka) Since we're not using mutable arrays or dicts here, we really don't need to override the setter!
- (void) setHistory_log_url:(NSURL*)history_log_url;
- (void) setKey_bundle_url:(NSURL*)key_bundle_url;
#else
// TOOD(aka) What we really need is a convertFileStore:(NSURL*)url routine!
- (void) setFile_store:(NSMutableDictionary*)file_store;  // TOOD(aka) needs updated to key-bundle & history-log
#endif
- (SecKeyRef) publicKeyRef;
- (NSData*) getPublicKey;
- (void) setPublicKey:(NSData*)public_key;
- (BOOL) isEqual:(Principal*)principal;

#pragma mark - ConsumerMaster VC utilities
- (void) updateLastFetch;
- (NSTimeInterval) getTimeIntervalToNextFetch;
- (BOOL) isKeyBundleURLValid;
- (BOOL) isHistoryLogURLValid;

// XXX TODO(aka) I think the following are deprecated.
/*
- (void) addLocation:(CLLocation*)location;
- (NSString*) fetchLocationData;
- (NSString*) downloadLocationData:(NSString**)encrypted_location_data_b64;
 */

#pragma mark - ProviderMaster VC utilities

#pragma mark - Debugging routines
- (NSString*) absoluteString;

@end
