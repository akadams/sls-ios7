//
//  ProviderMasterViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>             // needed for delegation (SMS & mail)

#import "ProviderDataViewController.h"      // needed for delegation
#import "ConsumerListDataViewController.h"  // needed for delegation
#import "AddConsumerViewController.h"       // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "ConsumerListController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"
#import "ConsumerCellController.h"


@interface ProviderMasterViewController : UIViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, ProviderDataViewControllerDelegate, CoreLocationControllerDelegate, AddConsumerViewControllerDelegate, ConsumerCellControllerDelegate, ConsumerListDataViewControllerDelegate>

@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ConsumerListController* consumer_list_controller;
@property (strong, nonatomic) CoreLocationController* location_controller;
@property (strong, nonatomic) SymmetricKeysController* symmetric_keys_controller;
@property (assign, nonatomic) ConsumerCellController* cell;
@property (weak, nonatomic) IBOutlet UITableView* table_view;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (void) loadState;
- (void) sendSymmetricKey:(NSNumber*)precision consumer:(Consumer*)sole_consumer;
- (NSString*) uploadLocationData:(CLLocation*)location;

@end
