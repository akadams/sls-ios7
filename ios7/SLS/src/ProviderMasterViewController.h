//
//  ProviderMasterViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>             // needed for delegation (SMS & mail)

// Data members.
#import "PersonalDataController.h"
#import "ConsumerListController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"


@protocol ProviderMasterViewControllerDelegate;  // so we can send ConsumerMaster VC info, if needed

@interface ProviderMasterViewController : UITableViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, CoreLocationControllerDelegate>

#pragma mark - Local variables
@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ConsumerListController* consumer_list_controller;
@property (strong, nonatomic) SymmetricKeysController* symmetric_keys_controller;
@property (strong, nonatomic) CoreLocationController* location_controller;
@property (strong, nonatomic) NSMutableDictionary* history_logs;  //  NSArrays of LocationBundleControllers (for each policy)
@property (weak, nonatomic) id <ProviderMasterViewControllerDelegate> delegate;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UITableView* table_view;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;
- (void) loadState;

#pragma mark - Cloud management
- (void) sendCloudMetaData:(NSString*)policy consumer:(Principal*)sole_consumer;

#pragma mark - Cloud operations
- (void) uploadKeyBundle:(NSString*)policy consumer:(Principal*)sole_consumer;
- (NSString*) uploadHistoryLog:(NSArray*)history_log policy:(NSString*)policy;  // returns an error, called by CLLocation delegates

@end

@protocol ProviderMasterViewControllerDelegate <NSObject>
- (void) addSelfToProviders:(PersonalDataController*)remote_data withBucket:(NSString*)bucket_name withKey:(NSData*)symmetric_key;
- (void) addConsumerToProviders:(Principal*)consumer;
@end