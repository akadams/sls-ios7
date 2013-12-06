//
//  ProviderDataViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/16/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "FileStoreDataViewController.h"     // needed for delegation
#import "ProviderDataExtViewController.h"   // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"


@protocol ProviderDataViewControllerDelegate;

@interface ProviderDataViewController : UIViewController <UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate, FileStoreDataViewControllerDelegate, ProviderDataExtViewControllerDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) CoreLocationController* location_controller;
@property (copy, nonatomic) SymmetricKeysController* symmetric_keys;
@property (weak, nonatomic) id <ProviderDataViewControllerDelegate> delegate;
@property (nonatomic) BOOL state_change;
@property (nonatomic) BOOL add_self_status;
@property (weak, nonatomic) IBOutlet UITextField* identity_input;
@property (weak, nonatomic) IBOutlet UIPickerView* picker;
@property (weak, nonatomic) IBOutlet UIButton* setup_store_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) showPeoplePicker:(id)sender;

@end

@protocol ProviderDataViewControllerDelegate <NSObject>
- (void) providerDataViewControllerDidFinish:(PersonalDataController*)our_data coreLocationController:(CoreLocationController*)location_controller symmetricKeys:(SymmetricKeysController*)symmetric_keys addSelf:(BOOL)add_self;
- (void) providerDataViewControllerDidCancel:(ProviderDataViewController*)controller;
// XXX - (void) providerDataViewControllerEnableSharing:(ProviderDataViewController*)controller;
@end
