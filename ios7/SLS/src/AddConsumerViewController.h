//
//  AddConsumerViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>        // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "Principal.h"


@interface AddConsumerViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;

#pragma mark - Local variables
@property (copy, nonatomic) Principal* consumer;
@property (nonatomic) NSInteger chosen_protocol;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UIPickerView* pairing_picker;
@property (weak, nonatomic) IBOutlet UIButton* start_pairing_button;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) showAddressBook:(id)sender;
- (IBAction) startPairing:(id)sender;

#pragma mark - Utility routines
+ (NSArray*) supportedPairingProtocols;

@end
