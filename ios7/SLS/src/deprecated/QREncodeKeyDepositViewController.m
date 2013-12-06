//
//  QREncodeKeyDepositViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/27/12.
//  Copyright (c) 2012 PSC. All rights reserved.
//

#import <QuartzCore/CALayer.h>
//#import <QREncoder/QREncoder.h>

#import "QREncodeKeyDepositViewController.h"
#import "NSData+Base64.h"
#import "qrencode.h"


static const int kDebugLevel = 1;

static const CGFloat kPadding = 10;  // used in QREncode

@interface QREncodeKeyDepositViewController ()
@end

@implementation QREncodeKeyDepositViewController

@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;
@synthesize image_label = _image_label;
@synthesize image_view = _image_view;
// XXX @synthesize change_button = _change_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_label = nil;
        _image_view = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_label = nil;
        _image_view = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

#if 0 // XXX Don't think we need this anymore.
- (void) setQr_image_view:(UIImageView*)qr_image_view {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:setQr_image_view: called.");
    
    NSLog(@"QREncodeKeyDepositViewController:setQr_image_view: TODO(aka) Why do we need to override this setter?");
    
    if (_image_view != qr_image_view) {
        _image_view = qr_image_view;
        
        /*
         // Set the *text* to our (base64) public key.
         _image_view.image = _publicKey;
         NSLog(@"QREncodeKeyDepositViewController:setqr_image_view: UIImageView text set from %s to: %s", 
         [_publicKey cStringUsingEncoding: [NSString defaultCStringEncoding]],
         [_image_view.text cStringUsingEncoding: [NSString defaultCStringEncoding]]);
         */
    }
}
#endif

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    _our_data = nil;
    _identity = nil;
    [self setImage_label:nil];
    [self setImage_view:nil];
    // XXX [self setChange_button:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:configureView: called.");
    
    // Get ASCII version of key deposit.
    NSString* key_deposit_str = [PersonalDataController absoluteStringKeyDeposit:_our_data.key_deposit];
    
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:configureView: QR-encoding Key-Deposit: %s.", [key_deposit_str cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    // Set the *image* to our QR-encoded key deposit.
    UIImage* image = [_our_data printQRKeyDeposit:_image_view.bounds.size.width];
    _image_view.image = image;
    
    // Set additional UIImageView parameters.
    _image_view.backgroundColor = [UIColor whiteColor];
    //CGFloat qrSize = _image_view.bounds.size.width - kPadding * 2;
    //_image_view.frame = CGRectMake(kPadding, (_view.bounds.size.height - qrSize) / 2, qrSize, qrSize);
    [_image_view layer].magnificationFilter = kCAFilterNearest;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:done: called");
    
    [[self delegate] qrEncodeKeyDepositViewControllerDidFinish];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:cancel: called");
    
    [[self delegate] qrEncodeKeyDepositViewControllerDidCancel:self];
}

/* XXX
- (IBAction) buttonPressed:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyDepositViewController:buttonPressed: called");
    
    [self viewDidLoad];  // XXX TODO(aka) I think we just want configureView here!
}
*/

// Delegate functions.

@end

