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
    // NSCopying is needed because we use Principal as a key in a NSDictionary!
    // NSCoding is needed because we use iOS's archiving.
    
@private
    SecKeyRef publicKeyRef;
}

#pragma mark - Local variables
@property (copy, nonatomic) NSString* identity;            // provider's identity
@property (copy, nonatomic) NSString* identity_hash;       // unique ID used in messages (local-identity?)
@property (copy, nonatomic) NSString* mobile_number;       // SMS contact #; can be nil
@property (copy, nonatomic) NSString* email_address;       // e-mail; can be nil
@property (copy, nonatomic) NSMutableDictionary* deposit;  // OOB mechanism to receive (file-store) meta-data

#pragma mark - Data used by Consumer MVC

// TODO(aka) At one point I was going to store the URLs as dictionaries, since (at least in the case of the history-log URL) we get the components of the URL in pieces (i.e., the scheme & host from our Deposit, the path from the key-bundle), but we end up using URLs in the end, so we might as well start with them on the Consumer.

#if (FILE_STORE_USE_NSURL == 1)
@property (copy, nonatomic) NSURL* file_store_url;            // provider's file store (as URL); it may or may not contain the history-log path
@property (copy, nonatomic) NSURL* key_bundle_url;            // provider's key-bundle file store (as URL)
#else
@property (copy, nonatomic) NSMutableDictionary* file_store_history_log;  // provider's history-log file store (as dict)
@property (copy, nonatomic) NSMutableDictionary* file_store_key_bundle;   // provider's key-bundle file store (as dict)
#endif

@property (copy, nonatomic) NSData* key;                      // shared symmetric key given to us by this provider
@property (copy, nonatomic) NSMutableArray* history_log;      // array of LocationBundleControllers (i.e., their past history)
@property (copy, nonatomic) NSDate* last_fetch;               // date of last fetch
@property (copy, nonatomic) NSNumber* frequency;              // requested seconds between fetches; TODO(aka) make NSTimeInterval?)
@property (nonatomic) BOOL is_focus;                          // marks this provider as having the map focus

#pragma mark - Data used by the Provider MVC
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
- (void) setFile_store_url:(NSURL*)file_store_url;
- (void) setKey_bundle_url:(NSURL*)key_bundle_url;
#else
// TOOD(aka) What we really need is a convertFileStore:(NSURL*)url routine!
- (void) setFile_store:(NSMutableDictionary*)file_store;  // TOOD(aka) needs updated to key-bundle & history-log
#endif
- (SecKeyRef) publicKeyRef;
- (NSData*) getPublicKey;
- (void) setPublicKey:(NSData*)public_key accessGroup:(NSString*)access_group;
- (BOOL) isEqual:(Principal*)principal;

#pragma mark - ConsumerMaster VC utilities
- (void) updateLastFetch;
- (NSTimeInterval) getTimeIntervalToNextFetch;
- (BOOL) isFileStoreURLValid;
- (BOOL) isKeyBundleURLValid;

// XXX TODO(aka) I think the following are deprecated.
/*
- (void) addLocation:(CLLocation*)location;
- (NSString*) fetchLocationData;
- (NSString*) downloadLocationData:(NSString**)encrypted_location_data_b64;
 */

#pragma mark - ProviderMaster VC utilities

#pragma mark - Debugging routines
- (NSString*) serialize;

@end
