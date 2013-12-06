//
//  KeyDeposit.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/8/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KeyDeposit : NSObject <NSCopying>

@property (copy, nonatomic) NSString* type;      // type of location, e.g., SMS, URL, e-mail
@property (copy, nonatomic) NSString* location;  // location to *deposit* symmetric key

- (id) init;
- (id) initWithType:(NSString*)type location:(NSString*)location;
- (id) copyWithZone:(NSZone*)zone;
- (NSString*) absoluteString;

@end
