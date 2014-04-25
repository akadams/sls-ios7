//
//  AddConsumerHCCViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

// Data members.
#import "PersonalDataController.h"
#import "HCCPotentialPrincipal.h"


@interface AddConsumerHCCViewController : UIViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) HCCPotentialPrincipal* potential_consumer;

#pragma mark - Local variables

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UILabel* main_label;
@property (weak, nonatomic) IBOutlet UITextField* main_input;
@property (weak, nonatomic) IBOutlet UIButton* send_msg_button;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) send_msg:(id)sender;

@end
