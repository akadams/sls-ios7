//
//  KeyBundleController.h
//  SLS
//
//  Created by Andrew K. Adams on 1/22/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KeyBundleController : NSObject <NSCoding>

#pragma mark - Local variables
@property (copy, nonatomic) NSString* symmetric_key;       // base64 encrypted shared symmetric key
@property (copy, nonatomic) NSString* history_log_path;    // file-store URL path component where history-log for this key is kept
@property (copy, nonatomic) NSNumber* time_stamp;          // timestamp
@property (copy, nonatomic) NSString* signature;           // base64 signature over key and timestamp

#pragma mark - Initialization
- (id) init;
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark - Data management
- (NSString*) build:(NSString*)symmetric_key privateKeyRef:(SecKeyRef)private_key_ref historyLogPath:(NSString*)path;
- (NSString*) generateWithString:(NSString*)serialized_str;
- (NSString*) serialize;
- (BOOL) verifySignature:(SecKeyRef)public_key_ref;

@end
