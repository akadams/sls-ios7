//
//  AddConsumerCTViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Note, we need to use delegation (as opposed to unwinding), because these classes will be called by both the AddConsumerCTView and the AddConsumerCTView!

#import "QREncodePKViewController.h"          // for delegation
#import "QRDecodePKViewController.h"          // for delegation
#import "QREncodeChallengeViewController.h"   // for delegation
#import "QRDecodeChallengeViewController.h"   // for delegation
#import "QREncodeDepositViewController.h"     // for delegation
#import "QRDecodeDepositViewController.h"     // for delegation

// Data members.
#import "PersonalDataController.h"
#import "Principal.h"


@interface AddConsumerCTViewController : UIViewController <QREncodePKViewControllerDelegate, QRDecodePKViewControllerDelegate, QREncodeChallengeViewControllerDelegate, QRDecodeChallengeViewControllerDelegate, QREncodeDepositViewControllerDelegate, QRDecodeDepositViewControllerDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) Principal* consumer;

#pragma mark - Local variables
@property (nonatomic) int current_state;

#pragma mark - Images
@property (copy, nonatomic) UIImage* checkbox_empty;
@property (copy, nonatomic) UIImage* checkbox_checked;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIButton* encode_key_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_key_image;

@property (weak, nonatomic) IBOutlet UIButton* decode_challenge_button;
@property (weak, nonatomic) IBOutlet UIImageView* decode_challenge_image;
@property (weak, nonatomic) IBOutlet UILabel* decode_challenge_label;
// XXX @property (weak, nonatomic) IBOutlet UILabel* decode_response_label;

@property (weak, nonatomic) IBOutlet UIButton* decode_key_button;
@property (weak, nonatomic) IBOutlet UIImageView* decode_key_image;

@property (weak, nonatomic) IBOutlet UIButton* encode_challenge_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_challenge_image;
@property (weak, nonatomic) IBOutlet UILabel* encode_challenge_label;
// XXX @property (weak, nonatomic) IBOutlet UILabel* encode_response_label;
@property (weak, nonatomic) IBOutlet UIButton* encode_response_yes_button;
@property (weak, nonatomic) IBOutlet UIButton* encode_response_no_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_response_image;

@property (weak, nonatomic) IBOutlet UIButton* encode_deposit_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_deposit_image;
@property (weak, nonatomic) IBOutlet UILabel* end_label;

@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) encodeResponseYes:(id)sender;
- (IBAction) encodeResponseNo:(id)sender;

@end
