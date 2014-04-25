//
//  ConsumerDataController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 3/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ConsumerListController.h"
#import "Principal.h"


static const int kDebugLevel = 1;

static const int kInitialConsumerListSize = 10;
static const char* kConsumerListFilename = "consumers.list";


@interface ConsumerListController ()
@end

@implementation ConsumerListController

#pragma mark - Local variables
@synthesize consumer_list = _consumer_list;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:init: called.");
    
    if (self = [super init]) {
        _consumer_list = [[NSMutableArray alloc] initWithCapacity:kInitialConsumerListSize];

        /*  XXX Old code that invoked our overridden setter?
        NSMutableArray* array = [[NSMutableArray alloc] init];
        _consumer_list = array;
         */
    }
    
    return self;
}

- (void) setConsumer_list:(NSMutableArray*)new_list {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:setConsumer_list: called.");
    
    // We need to override the default setter, because consumer_list property is a copy, and we must ensure that the new copy is also mutable.
    
    if (_consumer_list != new_list) {
        _consumer_list = [new_list mutableCopy];
    }
}

#pragma mark - State backup & restore

- (NSString*) saveState {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:saveState: called.");
    
    // Save our list of consumers to disk.
    
    // Get Document path, and add the name of consumers' list file.
    NSArray* dir_list =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* consumer_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kConsumerListFilename];
    
    // Note, we must convert our Consumer objects to serialized NSData objects, and rebuild our NSArray.
    
    // XXX TODO(aka) Why do we do this, as opposed to simply making the ProviderListController NSCoding commplient?  It only has the one data member, the NSArray!
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerListController:saveState: operating on consumer list of count: %lu.", (unsigned long)[_consumer_list count]);
    
    NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithCapacity:kInitialConsumerListSize];
    for (int i = 0; i < [_consumer_list count]; ++i) {
        Principal* consumer = [_consumer_list objectAtIndex:i];
        
        if (kDebugLevel > 2)
            NSLog(@"ConsumerListController:saveState: converting consumer: %s.", [[consumer serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        NSData* tmp_data = [NSKeyedArchiver archivedDataWithRootObject:consumer];
        [serialized_list addObject:tmp_data];
    }
    
    // And write it out to disk.
    if (![serialized_list writeToFile:consumer_list_path atomically:YES]) {
        NSString* error_msg = [[NSString alloc] initWithFormat:@"ConsumerListController:saveState: writeToFile(%s) failed!", [consumer_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return error_msg;
    }
    
    return nil;   
}

- (NSString*) loadState {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:loadState: called.");
    
    // Load in our list of consumers from disk.
    
    // Get Document path, and add the name of consumers' list file.
    NSArray* dir_list = 
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* doc_dir = [dir_list objectAtIndex:0];
    NSString* consumer_list_path = [[NSString alloc] initWithFormat:@"%s/%s", [doc_dir cStringUsingEncoding:[NSString defaultCStringEncoding]], kConsumerListFilename];
    
    // If it exists, load it in, else initialize an empty list.
    if ([[NSFileManager defaultManager] fileExistsAtPath:consumer_list_path]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerListController:loadState: %s exists, initializing consumer list with contents.", [consumer_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Note, we must convert the serialized NSData object into our consumer object and re-build our NSArray.
        
        NSMutableArray* serialized_list = [[NSMutableArray alloc] initWithContentsOfFile:consumer_list_path];
        for (int i = 0; i < [serialized_list count]; ++i) {
            // TODO(aka) Technically, we should try to catch NSInvalidArchiveOperationException, however, according to lore, there's no guarantee that an exception will even be thrown!
            
            Principal* consumer = [NSKeyedUnarchiver unarchiveObjectWithData:[serialized_list objectAtIndex:i]];
            [_consumer_list addObject:consumer];
        }
    } else {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerListController:loadState: %s does not exist, initializing empty consumer list.", [consumer_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);        
        
        _consumer_list = [[NSMutableArray alloc] initWithCapacity:kInitialConsumerListSize];
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerListController:loadState: loaded %lu consumer(s) from %s.", (unsigned long)[_consumer_list count], [consumer_list_path cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}

#pragma mark - Data source routines

- (NSUInteger) countOfList {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:countOfList: called.");
    
    return [_consumer_list count];
}

- (Principal*) objectInListAtIndex:(NSUInteger)index {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:objectInListAtIndex: called: %lu.", (unsigned long)index);
    
   return [_consumer_list objectAtIndex:index];    
}

- (BOOL) containsObject:(Principal*)consumer {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:addConsumer: called.");
    
    if (consumer == nil)
        return false;
    
    if ([_consumer_list count] == 0)
        return false;
    
    return [_consumer_list containsObject:consumer];
}

- (void) removeObjectAtIndex:(NSUInteger)index {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:removeObjectAtIndex: called.");
    
    if ([_consumer_list count] == 0)
        return;
    
    [_consumer_list removeObjectAtIndex:index];
    
    return;
}

#pragma mark - Data management

- (NSString*) addConsumer:(Principal*)consumer {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:addConsumer: called.");
    
    if (consumer == nil)
        return nil;
    
    // Note, it's up to the Provider's MVC to (i) get the old policy and re-key for it, and (ii) generate a new symmetric key for the new policy if it doesn't already exist!
    
    // First, see if the Consumer object already exists (if so, delete it).
    NSString* err_msg = nil;
    if ([self containsObject:consumer]) {
        err_msg = [self deleteConsumer:consumer saveState:false];  // we won't save state here
        if (err_msg != nil)
            return err_msg;
    }
    
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListController:addConsumer: adding: %s.", [[consumer serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [_consumer_list addObject:consumer];

    // And now store our (newly) updated list of consumers to disk.
    return [self saveState];
}

- (NSString*) deleteConsumer:(Principal*)consumer saveState:(BOOL)save_state {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListContoller:deleteConsumer:saveState: called: %d.", save_state);
    
    [self.consumer_list removeObject:consumer];
    
    if (save_state) {
        // Store our (newly) updated list of consumers to disk.
        return [self saveState];
    } else {
        return nil;
    }
}

- (NSUInteger) countOfPolicy:(NSString*)policy {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListContoller:countPolicy: called.");
    
    NSUInteger cnt = 0;
    
    if (_consumer_list == nil || policy == nil)
        return cnt;
    
    for (id object in _consumer_list) {
        Principal* consumer = (Principal*)object;
        if ([consumer.policy isEqual:policy])
            cnt++;
    }

    return cnt;
}

@end
