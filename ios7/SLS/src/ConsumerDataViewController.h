//
//  ConsumerDataViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"


@interface ConsumerDataViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) ProviderListController* provider_list;
@property (nonatomic) BOOL fetch_data_toggle;

#pragma mark - Local variables

#pragma mark - Variables returned via unwind callback
@property (nonatomic) BOOL identity_changed;
@property (nonatomic) BOOL deposit_changed;
@property (nonatomic) BOOL pub_keys_changed;
@property (nonatomic) BOOL fetch_toggle_changed;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* identity_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* deposit_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_hash_label;
@property (weak, nonatomic) IBOutlet UIButton* gen_pub_keys_button;
@property (weak, nonatomic) IBOutlet UISwitch* fetch_data_switch;
@property (weak, nonatomic) IBOutlet UIButton* show_providers_button;
@property (weak, nonatomic) IBOutlet UILabel* map_focus_label;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;

#pragma mark - Actions
- (IBAction) genPubKeys:(id)sender;
- (IBAction) toggleFetchData:(id)sender;

@end
