//
//  AddConsumerViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/2/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Note, this viewController is for adding a Consumer object to the provider's view.

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

#import "BluetoothRequestViewController.h"    // needed for delegation
#import "AddConsumerQRViewController.h"       // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "Consumer.h"


@protocol AddConsumerViewControllerDelegate;

@interface AddConsumerViewController : UIViewController <UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, BluetoothRequestViewControllerDelegate, AddConsumerQRViewControllerDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) Consumer* consumer;
@property (weak, nonatomic) id <AddConsumerViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField* identity_input;
@property (weak, nonatomic) IBOutlet UITextField* mobile_input;
@property (weak, nonatomic) IBOutlet UITextField* email_input;
@property (weak, nonatomic) IBOutlet UIButton* bluetooth_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) cancel:(id)sender;
- (IBAction) done:(id)sender;
- (IBAction) showPeoplePicker:(id)sender;
- (IBAction) sendEmail:(id)sender;
- (IBAction) sendSMS:(id)sender;

@end

@protocol AddConsumerViewControllerDelegate <NSObject>
- (void) addConsumerViewControllerDidFinish:(Consumer*)consumer;
- (void) addConsumerViewControllerDidCancel:(AddConsumerViewController*)controller;
@end
