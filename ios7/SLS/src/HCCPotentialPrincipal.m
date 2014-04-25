//
//  HCCPotentialPrincipal.m
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "HCCPotentialPrincipal.h"


static const int kDebugLevel = 4;


@interface HCCPotentialPrincipal ()
@end

@implementation HCCPotentialPrincipal

#pragma mark - Local data
@synthesize principal = _principal;
@synthesize mode = _mode;
@synthesize our_challenge = _our_challenge;
@synthesize their_challenge = _their_challenge;
@synthesize our_secret_question = _our_secret_question;
@synthesize their_secret_question = _their_secret_question;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"HCCPotentialPrincipal:init: called.");
    
    if (self = [super init]) {
        _principal = nil;
        _mode = [NSNumber numberWithInt:HCC_MODE_INITIAL];
        _our_challenge = nil;
        _their_challenge = nil;
        _our_secret_question = nil;
        _their_secret_question = nil;
    }
    
    return self;
}

- (id) initWithPrincipal:(Principal*)principal {
    if (kDebugLevel > 2)
        NSLog(@"Principal:initWithPrincipal: called.");
    
    self = [super init];
    if (self) {
        _principal = principal;
        _mode = [NSNumber numberWithInt:HCC_MODE_INITIAL];
        _our_challenge = nil;
        _their_challenge = nil;
        _our_secret_question = nil;
        _their_secret_question = nil;
        
        return self;
    }
    
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    if (kDebugLevel > 2)
        NSLog(@"HCCPotentialPrincipal:copywithZone: called.");
    
    HCCPotentialPrincipal* tmp_potential_principal = [[HCCPotentialPrincipal alloc] init];
    if (_principal)
        tmp_potential_principal.principal = _principal;
    
    if (_mode)
        tmp_potential_principal.mode = _mode;
    
    if (_our_challenge)
        tmp_potential_principal.our_challenge = _our_challenge;
    
    if (_their_challenge)
        tmp_potential_principal.their_challenge = _their_challenge;
    
    if (_our_secret_question)
        tmp_potential_principal.our_secret_question = _our_secret_question;

    if (_their_secret_question)
        tmp_potential_principal.their_secret_question = _their_secret_question;
    
    return tmp_potential_principal;
}

- (id) initWithCoder:(NSCoder*)decoder {
    if (kDebugLevel > 2)
        NSLog(@"HCCPotentialPrincipal:initWithCoder: called.");
    
    self = [super init];
    if (self) {
        _principal = [decoder decodeObjectForKey:@"principal"];
        _mode = [decoder decodeObjectForKey:@"mode"];
        _our_challenge = [decoder decodeObjectForKey:@"our-challenge"];
        _their_challenge = [decoder decodeObjectForKey:@"their-challenge"];
        _our_secret_question = [decoder decodeObjectForKey:@"our-secret-question"];
        _their_secret_question = [decoder decodeObjectForKey:@"their-secret-question"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
    if (kDebugLevel > 2)
        NSLog(@"HCCPotentialPrincipal:encodeWithCoder: called.");
    
    [encoder encodeObject:_principal forKey:@"principal"];
    [encoder encodeObject:_mode forKey:@"mode"];
    [encoder encodeObject:_our_challenge forKey:@"our-challenge"];
    [encoder encodeObject:_their_challenge forKey:@"their-challenge"];
    [encoder encodeObject:_our_secret_question forKey:@"our-secret-question"];
    [encoder encodeObject:_their_secret_question forKey:@"their-secret-question"];
}

#pragma mark - Data management

@end
