//
//  QRDecodePKViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureOutput.h>  // needed for delegation

// Data members.
#import "PersonalDataController.h"


@protocol QRDecodePKViewControllerDelegate;

@interface QRDecodePKViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

#pragma mark - Inherited data (from either AddProvider or AddConsumer CTViewControllers)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;  // encoder's identity
@property (weak, nonatomic) id <QRDecodePKViewControllerDelegate> delegate;

#pragma mark - Local variables
@property (copy, nonatomic) NSString* identity_hash;  // what ZXing populates after scan
@property (copy, nonatomic) NSData* public_key;  // what ZXing populates after scan

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

@protocol QRDecodePKViewControllerDelegate <NSObject>
- (void) qrDecodePKViewControllerDidFinish:(NSString*)identity_hash publicKey:(NSData*)public_key;
- (void) qrDecodePKViewControllerDidCancel:(QRDecodePKViewController*)controller;
@end
