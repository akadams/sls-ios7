//
//  QRDecodeKeyViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVCaptureOutput.h>  // needed for delegation

// Data members.
#import "PersonalDataController.h"


@protocol QRDecodeKeyViewControllerDelegate;

//@interface QRDecodeKeyViewController : UIViewController <ZXingDelegate>
//@interface QRDecodeKeyViewController : UIViewController <ZBarReaderDelegate>
@interface QRDecodeKeyViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;  // encoder's identity
@property (copy, nonatomic) NSString* identity_hash;  // what ZXing populates after scan
@property (copy, nonatomic) NSData* public_key;  // what ZXing populates after scan
@property (weak, nonatomic) id <QRDecodeKeyViewControllerDelegate> delegate;
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

@protocol QRDecodeKeyViewControllerDelegate <NSObject>
- (void) qrDecodeKeyViewControllerDidFinish:(NSString*)identity_hash publicKey:(NSData*)public_key;
- (void) qrDecodeKeyViewControllerDidCancel:(QRDecodeKeyViewController*)controller;
@end
