//
//  AddConsumerQRViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/29/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QRDecodeKeyViewController.h"         // needed for delegation
#import "QREncodeChallengeViewController.h"   // needed for delegation
#import "QRDecodeKeyDepositViewController.h"  // needed for delegation
#import "QREncodeKeyViewController.h"         // needed for delegation
#import "QRDecodeChallengeViewController.h"   // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "Consumer.h"


@protocol AddConsumerQRViewControllerDelegate;

@interface AddConsumerQRViewController : UIViewController <QRDecodeKeyViewControllerDelegate, QREncodeChallengeViewControllerDelegate, QRDecodeKeyDepositViewControllerDelegate, QREncodeKeyViewControllerDelegate, QRDecodeChallengeViewControllerDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) Consumer* consumer;
@property (weak, nonatomic) id <AddConsumerQRViewControllerDelegate> delegate;
@property (copy, nonatomic) UIImage* checkbox_empty;
@property (copy, nonatomic) UIImage* checkbox_checked;

@property (weak, nonatomic) IBOutlet UIButton* decode_key_button;
@property (weak, nonatomic) IBOutlet UIImageView* decode_key_image;

@property (weak, nonatomic) IBOutlet UIButton* encode_challenge_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_challenge_image;
@property (weak, nonatomic) IBOutlet UILabel* encode_challenge_label;  // XXX think this belongs below

@property (weak, nonatomic) IBOutlet UILabel* encode_response_label;  // decprecated

@property (weak, nonatomic) IBOutlet UIButton* encode_response_yes_button;
@property (weak, nonatomic) IBOutlet UIButton* encode_response_no_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_response_image;

@property (weak, nonatomic) IBOutlet UIButton* decode_key_deposit_button;
@property (weak, nonatomic) IBOutlet UIImageView* decode_key_deposit_image;

@property (weak, nonatomic) IBOutlet UIButton* encode_key_button;
@property (weak, nonatomic) IBOutlet UIImageView* encode_key_image;

@property (weak, nonatomic) IBOutlet UIButton* decode_challenge_button;
@property (weak, nonatomic) IBOutlet UILabel* decode_challenge_label;
@property (weak, nonatomic) IBOutlet UIImageView* decode_challenge_image;

@property (weak, nonatomic) IBOutlet UILabel* end_label;

@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* cancel_button;

@property (nonatomic) int current_state;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) encodeResponseYes:(id)sender;
- (IBAction) encodeResponseNo:(id)sender;

@end

@protocol AddConsumerQRViewControllerDelegate <NSObject>
- (void) addConsumerQRViewControllerDidFinish:(Consumer*)consumer;
- (void) addConsumerQRViewControllerDidCancel:(AddConsumerQRViewController*)controller;
@end