//
//  QRDecodeChallengeViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureOutput.h>  // needed for delegation

// Data members.
#import "PersonalDataController.h"


@protocol QRDecodeChallengeViewControllerDelegate;

//@interface QRDecodeChallengeViewController : UIViewController <ZXingDelegate>
@interface QRDecodeChallengeViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;
@property (copy, nonatomic) NSString* scan_results;  // what ZXing fill in
@property (weak, nonatomic) id <QRDecodeChallengeViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel* label;
@property (weak, nonatomic) IBOutlet UIButton* scan_button;
@property (weak, nonatomic) IBOutlet UITextView* text_view;
// XXX @property (weak, nonatomic) IBOutlet UIButton* done_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) scanStart:(id)sender;
// XXX - (IBAction) scanOkay:(id)sender;

@end

@protocol QRDecodeChallengeViewControllerDelegate <NSObject>
- (void) qrDecodeChallengeViewControllerDidFinish:(NSString*)scan_results;
- (void) qrDecodeChallengeViewControllerDidCancel:(QRDecodeChallengeViewController*)controller;
@end
