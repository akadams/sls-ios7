//
//  ProviderMasterViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>        // needed for delegation
#import <MessageUI/MessageUI.h>                // needed for delegation (SMS & mail)

// Data members.
#import "PersonalDataController.h"
#import "ConsumerListController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"
#import "HCCPotentialPrincipal.h"
#import "Principal.h"


@protocol ProviderMasterViewControllerDelegate;  // so we can send ConsumerMaster VC info, if needed

@interface ProviderMasterViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, CoreLocationControllerDelegate>

#pragma mark - Local variables
@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ConsumerListController* consumer_list;
@property (strong, nonatomic) SymmetricKeysController* symmetric_keys_controller;
@property (strong, nonatomic) CoreLocationController* location_controller;
@property (strong, nonatomic) NSMutableDictionary* history_logs;  //  NSArrays of LocationBundleControllers (for each policy)
@property (strong, nonatomic) NSMutableDictionary* potential_consumers;  // HCCPotentialPrincipal objects indexed by identity
@property (strong, nonatomic) Principal* potential_consumer;  // a temporary Principal used by ABPeoplePickerNavigationController's delegate
@property (weak, nonatomic) id <ProviderMasterViewControllerDelegate> delegate;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UITableView* table_view;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;
- (void) updateOurDataState:(NSNotification*)notification;
- (void) loadState;

#pragma mark - NSUserDefaults management
- (NSString*) checkNSUserDefaults;

#pragma mark - Cloud management
- (void) sendCloudMetaData:(Principal*)sole_consumer;

#pragma mark - Cloud operations
- (void) uploadKeyBundle:(NSString*)policy consumer:(Principal*)sole_consumer;
- (NSString*) uploadHistoryLog:(NSArray*)history_log policy:(NSString*)policy;  // returns an error, called by CLLocation delegates
- (NSString*) googleDriveUpload:(NSString*)data bucket:(NSString*)bucket filename:(NSString*)filename idKey:(NSString*)id_key;
- (void) googleDriveQueryFolder:(NSString*)folder rootID:(NSString*)root_id;
- (void) googleDriveInsertFolder:(NSString*)folder rootID:(NSString*)root_id;
- (void) googleDriveQueryFileId:(NSString*)file_id;
- (void) googleDriveUpdateFolderPermission:(GTLDriveFile*)folder;

#pragma mark - Provider's utility functions
- (NSString*) getConsumerIdentity:(int)mode;

@end

@protocol ProviderMasterViewControllerDelegate <NSObject>
- (void) updateIdentity:(NSString*)identity;  // XXX Deprecated!
- (void) updatePersonalDataController;
- (void) addSelfToProviders:(NSString*)identity fileStoreURL:(NSURL*)file_store keyBundleURL:(NSURL*)key_bundle;
- (void) addConsumerToProviders:(Principal*)consumer;
@end