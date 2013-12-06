//
//  ProviderDataViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/22/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

// Data members.
#import "PersonalDataController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"


@interface ProviderDataViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) CoreLocationController* location_controller;
@property (copy, nonatomic) SymmetricKeysController* symmetric_keys;
@property (nonatomic) BOOL track_self_status;

#pragma mark - Local variables

#pragma mark - Variables returned via unwind callback
@property (nonatomic) BOOL identity_changed;
@property (nonatomic) BOOL deposit_changed;
@property (nonatomic) BOOL pub_keys_changed;
@property (nonatomic) BOOL sym_keys_changed;
@property (nonatomic) BOOL file_store_changed;
@property (nonatomic) BOOL location_sharing_toggle_changed;
@property (nonatomic) BOOL power_savings_toggle_changed;
@property (nonatomic) BOOL distance_filter_changed;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* identity_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* deposit_label;
@property (weak, nonatomic) IBOutlet UIButton* gen_pub_keys_button;
@property (weak, nonatomic) IBOutlet UIButton* gen_sym_keys_button;
@property (weak, nonatomic) IBOutlet UISwitch* location_sharing_switch;
@property (weak, nonatomic) IBOutlet UILabel* file_store_label;
@property (weak, nonatomic) IBOutlet UIButton* track_self_button;
@property (weak, nonatomic) IBOutlet UIButton* toggle_power_saving_button;
@property (weak, nonatomic) IBOutlet UISlider* distance_filter_slider;
@property (weak, nonatomic) IBOutlet UILabel* distance_filter_label;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;

#pragma mark - Actions
- (IBAction) genPubKeys:(id)sender;
- (IBAction) genSymKeys:(id)sender;
- (IBAction) toggleLocationSharing:(id)sender;
- (IBAction) addSelfToConsumers:(id)sender;
- (IBAction) togglePowerSaving:(id)sender;
- (IBAction) distanceFilterSliderChanged:(id)sender;

@end
