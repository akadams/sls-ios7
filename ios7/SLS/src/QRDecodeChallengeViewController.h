//
//  QRDecodeChallengeViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureOutput.h>  // needed for delegation

// Data members.
#import "PersonalDataController.h"


@protocol QRDecodeChallengeViewControllerDelegate;

@interface QRDecodeChallengeViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

#pragma mark - Inherited data (from either AddProvider or AddConsumer CTViewControllers)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;
@property (weak, nonatomic) id <QRDecodeChallengeViewControllerDelegate> delegate;

#pragma mark - Local variables
@property (copy, nonatomic) NSString* scan_results;  // what ZXing fill in

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UILabel* label;
@property (weak, nonatomic) IBOutlet UIButton* scan_button;
@property (weak, nonatomic) IBOutlet UITextView* text_view;
// XXX @property (weak, nonatomic) IBOutlet UIButton* done_button;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) scanStart:(id)sender;
// XXX - (IBAction) scanOkay:(id)sender;

@end

@protocol QRDecodeChallengeViewControllerDelegate <NSObject>
- (void) qrDecodeChallengeViewControllerDidFinish:(NSString*)scan_results;
- (void) qrDecodeChallengeViewControllerDidCancel:(QRDecodeChallengeViewController*)controller;
@end
