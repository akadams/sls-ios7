//
//  ConsumerDataViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/16/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>

#import "KeyDepositDataViewController.h"        // needed for delegation
#import "ConsumerDataExtViewController.h"       // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"


// XXX TODO(aka) I don't think we need to create the delegate anymore, as we can unwind to our MasterController!
@protocol ConsumerDataViewControllerDelegate;

@interface ConsumerDataViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>
// XXX <UITextFieldDelegate, KeyDepositDataViewControllerDelegate, ConsumerDataExtViewControllerDelegate>

#pragma mark - Inherited data (from the MasterViewController).
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) ProviderListController* provider_list_controller;
@property (nonatomic) BOOL fetch_data_toggle;

#pragma mark - Data we create.
@property (weak, nonatomic) id <ConsumerDataViewControllerDelegate> delegate;  // XXX deprecated

// Flags to pass back to MasterViewController showing what, if anything changed.
@property (nonatomic) BOOL identity_changed;
@property (nonatomic) BOOL deposit_changed;
@property (nonatomic) BOOL pub_keys_changed;
@property (nonatomic) BOOL fetch_toggle_changed;

#pragma mark - Outlets.
@property (nonatomic) BOOL add_self_status;  // used to show if we are also a provider
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* identity_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* address_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* map_focus_label;
@property (weak, nonatomic) IBOutlet UIButton* gen_pub_keys_button;
@property (weak, nonatomic) IBOutlet UIButton* add_self_button;
@property (weak, nonatomic) IBOutlet UISwitch* fetch_data_switch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;

#if 0
// XXX
@property (weak, nonatomic) IBOutlet UITextField* identity_input;
@property (weak, nonatomic) IBOutlet UIPickerView* picker;
@property (weak, nonatomic) IBOutlet UIButton* setup_deposit_button;
#endif

#pragma mark - Initialization.
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;

#pragma mark - Actions.
- (IBAction) showAddressBook:(id)sender;
- (IBAction) toggleFetchData:(id)sender;
- (IBAction) genPubKeys:(id)sender;
- (IBAction) addSelfToProviders:(id)sender;

#if 0
// XXX
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) showPeoplePicker:(id)sender;
#endif

@end

@protocol ConsumerDataViewControllerDelegate <NSObject>
- (void) consumerDataViewControllerDidFinish:(PersonalDataController*)our_data providerList:(ProviderListController*)provider_list fetchDataToggle:(BOOL)fetch_data_toggle addSelfStatus:(BOOL)add_self_status;
- (void) consumerDataViewControllerDidCancel:(ConsumerDataViewController*)controller;
@end
