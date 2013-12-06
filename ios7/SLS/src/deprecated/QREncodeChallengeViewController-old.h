//
//  QREncodeChallengeViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"


@protocol QREncodeChallengeViewControllerDelegate;

@interface QREncodeChallengeViewController : UIViewController

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;
@property (copy, nonatomic) NSString* encrypted_challenge;
@property (weak, nonatomic) id <QREncodeChallengeViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel* image_label;
@property (weak, nonatomic) IBOutlet UIImageView* image_view;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;

@end

@protocol QREncodeChallengeViewControllerDelegate <NSObject>
- (void) qrEncodeChallengeViewControllerDidFinish;
- (void) qrEncodeChallengeViewControllerDidCancel:(QREncodeChallengeViewController*)controller;
@end
