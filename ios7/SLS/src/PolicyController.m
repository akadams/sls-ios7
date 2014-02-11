//
//  PolicyController.m
//  SLS
//
//  Created by Andrew K. Adams on 2/6/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "PolicyController.h"


static const int kDebugLevel = 1;

// ASCII versions of precisions (to act as keys within the dictionary)
/*
static const char* kNone = "none";  // placeholder; not used
static const char* kState = "state";
static const char* kCounty = "county";
static const char* kCity = "city";
static const char* kNeighborhood = "neighborhood";
static const char* kBuilding = "building";
static const char* kExact = "exact";
 */

static const char* precision_level_names[kNumPrecisionLevels] = {
    PC_PRECISION_NONE,
    PC_PRECISION_STATE,
    PC_PRECISION_COUNTY,
    PC_PRECISION_CITY,
    PC_PRECISION_NEIGHBORHOOD,
    PC_PRECISION_BUILDING,
    PC_PRECISION_EXACT,
};

#pragma mark - Non-class functions

const char* precision_level_name(const int precision_level) {
    if (precision_level < 0 || precision_level > kNumPrecisionLevels)
        return precision_level_names[0];
    
    return precision_level_names[precision_level];
}

const int precision_level_idx(const char* precision_level_name) {
    for (int i = 0; i < kNumPrecisionLevels; ++i) {
        if (strlen(precision_level_names[i]) == strlen(precision_level_name) &&
            !strncasecmp(precision_level_names[i], precision_level_name,
                         kNumPrecisionLevels))
            return i;
    }
    
    return -1;
}

@implementation PolicyController

#pragma mark - Local data

#pragma mark - Initialization

#pragma mark - Precision level management

+ (NSString*) precisionLevelName:(NSNumber*)index {
    if (kDebugLevel > 2)
        NSLog(@"PolicyController:precsionLevelName: called.");
    
    
    NSString* name = [[NSString alloc] initWithFormat:@"%s", precision_level_name([index intValue])];

    // XXX NSLog(@"PolicyController:precsionLevelName: XXX name for index: %d, %s.", [index intValue], [name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return name;
}

+ (NSNumber*) precisionLevelIndex:(NSString*)name {
    if (kDebugLevel > 2)
        NSLog(@"PolicyController:precsionLevelIndex: called.");
    
    if (name == nil || [name length] == 0)
        return [NSNumber numberWithInt:0];
    
    int idx = precision_level_idx([name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    NSNumber* index = [[NSNumber alloc] initWithInt:idx];
    
    return index;
}

@end
