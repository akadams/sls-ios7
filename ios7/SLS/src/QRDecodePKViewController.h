//
//  QRDecodePKViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVCaptureOutput.h>
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>

// Data members.
#import "PersonalDataController.h"


@protocol QRDecodePKViewControllerDelegate;

@interface QRDecodePKViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

#pragma mark - Inherited data (from either AddProvider or AddConsumer CTViewControllers)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;  // encoder's identity
@property (weak, nonatomic) id <QRDecodePKViewControllerDelegate> delegate;

#pragma mark - Local variables
@property (copy, nonatomic) AVCaptureDevice* device;
@property (copy, nonatomic) AVCaptureDeviceInput* input;
@property (copy, nonatomic) AVCaptureMetadataOutput* output;
@property (copy, nonatomic) AVCaptureSession* session;
@property (copy, nonatomic) AVCaptureVideoPreviewLayer* preview_layer;
@property (copy, nonatomic) UIView* scan_view;

@property (copy, nonatomic) NSString* identity_hash;  // QR reader populates after scan
@property (copy, nonatomic) NSData* public_key;       // QR reader populates after scan

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UILabel* label;
@property (weak, nonatomic) IBOutlet UIButton* scan_button;
@property (weak, nonatomic) IBOutlet UITextView* text_view;
//@property (weak, nonatomic) IBOutlet UIView* scan_view;
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
