//
//  QREncodeKeyViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <QuartzCore/CALayer.h>
//#import <QREncoder/QREncoder.h>         // deprecated

#import "QREncodeKeyViewController.h"
#import "AddProviderViewController.h"     // for checking delegate
#import "AddConsumerViewController.h"     // for checking delegate
#import "NSData+Base64.h"
#import "qrencode.h"


static const int kDebugLevel = 1;

static const CGFloat kPadding = 10;  // used in QREncode

@interface QREncodeKeyViewController ()
@end

@implementation QREncodeKeyViewController

@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;
@synthesize image_label = _image_label;
@synthesize image_view = _image_view;
// XXX @synthesize change_button = _change_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

#if 0 // XXX Don't need anymore.
- (void) setQr_image_view:(UIImageView*)qr_image_view {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:setQr_image_view: called.");
    
    NSLog(@"QREncodeKeyViewController:setQr_image_view: TODO(aka) Why do we need to override this setter?");
    
    if (_image_view != qr_image_view) {
        _image_view = qr_image_view;
        
        /*
         // Set the *text* to our (base64) public key.
         _image_view.image = _publicKey;
         NSLog(@"QREncodeKeyViewController:setqr_image_view: UIImageView text set from %s to: %s", 
         [_publicKey cStringUsingEncoding: [NSString defaultCStringEncoding]],
         [_image_view.text cStringUsingEncoding: [NSString defaultCStringEncoding]]);
         */
    }
}
#endif

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:viewDidUnload: called.");
    
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
        NSLog(@"QREncodeKeyViewController:configureView: called.");
    
    if (kDebugLevel > 0) 
        NSLog(@"QREncodeKeyViewController:configureView: QR-encoding PK(Hash: %s): %s.", [[PersonalDataController hashMD5Data:[_our_data getPublicKey]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[[_our_data getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);

#if 1            
    UIImage* image = [_our_data printQRPublicKey:_image_view.bounds.size.width];
#else
    // Base64 our public key.
    NSString* public_key = [_our_data.getPublicKey base64EncodedString];
    
    // TODO(aka) Apparently, our *first* borrowed QR-encoder library does not have enough memory to QR encode our 191B base64 encoded public key.
    
    UIImage* image = [QREncoder encode:public_key size:8 correctionLevel:QRCorrectionLevelHigh];
#endif
    
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
        NSLog(@"QREncodeKeyViewController:done: called");
    
    [[self delegate] qrEncodeKeyViewControllerDidFinish];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:cancel: called");
    
    [[self delegate] qrEncodeKeyViewControllerDidCancel:self];
}

/* XXX
- (IBAction) buttonPressed:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeKeyViewController:buttonPressed: called");
    
    [self viewDidLoad];  // XXX TODO(aka) I think we just want configureView here!
}
*/

// Delegate functions.

@end

