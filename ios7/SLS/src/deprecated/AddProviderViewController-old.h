//
//  AddProviderViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>               // needed for delegation (SMS & mail)

#import "AddProviderQRViewController.h"       // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "Provider.h"


@protocol AddProviderViewControllerDelegate;

@interface AddProviderViewController : UIViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, AddProviderQRViewControllerDelegate>

// XXX TODO(aka) Does our_data need to be strong?
@property (strong, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) Provider* provider;
@property (weak, nonatomic) id <AddProviderViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UITextField* identity_input;
@property (weak, nonatomic) IBOutlet UITextField* mobile_input;
@property (weak, nonatomic) IBOutlet UITextField* email_input;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) showPeoplePicker:(id)sender;
- (IBAction) sendEmail:(id)sender;
- (IBAction) sendSMS:(id)sender;
- (IBAction) showAddressBook:(id)sender;


@end

@protocol AddProviderViewControllerDelegate <NSObject>
- (void) addProviderViewControllerDidFinish:(Provider*)provider;
- (void) addProviderViewControllerDidCancel:(AddProviderViewController*)controler;
@end