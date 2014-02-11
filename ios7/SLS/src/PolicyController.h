//
//  PolicyController.h
//  SLS
//
//  Created by Andrew K. Adams on 2/6/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <Foundation/Foundation.h>


// A map of our policies to concrete values, so we can display them in GUIs (e.g., as a float or int)
typedef enum {
    PC_PRECISION_IDX_NONE = 0,         // no key
    PC_PRECISION_IDX_STATE = 1,        // 0 decimal places (110km)
    PC_PRECISION_IDX_COUNTY = 2,       // 1 decimal place (11km)
    PC_PRECISION_IDX_CITY = 3,         // 2 decimal places (1.1km)
    PC_PRECISION_IDX_NEIGHBORHOOD = 4, // 3 decimal places (110m)
    PC_PRECISION_IDX_BUILDING = 5,     // 4 decimal places (11m)
    PC_PRECISION_IDX_EXACT = 6,        // 5 decimal places (1.1m)
} PCPrecisionLevels;

static const int kNumPrecisionLevels = PC_PRECISION_IDX_EXACT + 1;

// ASCII versions of our policies (doubles as keys within the symmetric keys dictionary!)
#define PC_PRECISION_NONE "none"
#define PC_PRECISION_STATE "state"
#define PC_PRECISION_COUNTY "county"
#define PC_PRECISION_CITY "city"
#define PC_PRECISION_NEIGHBORHOOD "neighborhood"
#define PC_PRECISION_BUILDING "building"
#define PC_PRECISION_EXACT "exact"


@interface PolicyController : NSObject

#pragma mark - Local data

#pragma mark - Initialization

#pragma mark - Precision level management
+ (NSString*) precisionLevelName:(NSNumber*)index;
+ (NSNumber*) precisionLevelIndex:(NSString*)name;

@end
